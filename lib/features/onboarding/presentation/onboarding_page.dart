import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../accounts/application/providers.dart';
import '../../accounts/domain/i_account_repository.dart';
import '../../auth/application/providers.dart';
import '../../profile/application/providers.dart';
import '../../profile/domain/user_profile.dart';
import '../../security/application/providers.dart';

/// First-run onboarding flow (issue #41 — Welcome Experience).
///
/// Steps:
///   1. Display name (skippable — greeting falls back to nameless form)
///   2. First account (skippable — pre-filled Savings / INR / 0)
///   3. Biometric enable (native only — never rendered on web)
///
/// Progress persists per step in user_profiles.onboarding_step, so killing
/// the app mid-flow resumes at the incomplete step. "Skip setup" on any step
/// marks onboarding complete immediately (escape hatch — prevents loops).
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  int _step = 0; // 0 = name, 1 = account, 2 = biometric (native only)
  bool _initialised = false;
  bool _busy = false;
  String? _error;
  String? _userId;

  // Step 1 — name
  final _nameController = TextEditingController();

  // Step 2 — first account
  final _accountNameController = TextEditingController(text: 'Savings');
  final _balanceController = TextEditingController(text: '0');
  AccountType _accountType = AccountType.savings;

  // Step 3 — biometric
  bool _biometricAvailable = false;

  int get _totalSteps => kIsWeb ? 2 : 3;

  @override
  void initState() {
    super.initState();
    _initialise();
  }

  Future<void> _initialise() async {
    final userId = await ref.read(authServiceProvider).getCurrentUserId();
    if (userId == null || userId.isEmpty) {
      // Auth state lost — router will redirect to /login on next frame.
      if (mounted) setState(() => _initialised = true);
      return;
    }
    _userId = userId;

    final repo = ref.read(userProfileRepositoryProvider);
    final profile = await repo.findOrCreate(userId);

    // Resume at the first incomplete step.
    var resume = profile.onboardingStep.value;
    if (resume >= _totalSteps) resume = _totalSteps - 1;
    if (profile.displayName != null) {
      _nameController.text = profile.displayName!;
    }

    var bioAvailable = false;
    if (!kIsWeb) {
      try {
        bioAvailable = await ref
            .read(securityServiceProvider)
            .isBiometricAvailable();
      } catch (_) {
        bioAvailable = false;
      }
    }

    if (mounted) {
      setState(() {
        _step = resume;
        _biometricAvailable = bioAvailable;
        _initialised = true;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _accountNameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  // ── Step actions ─────────────────────────────────────────────────────────

  Future<void> _completeNameStep({required bool skipped}) async {
    final userId = _userId;
    if (userId == null) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = ref.read(userProfileRepositoryProvider);
      final name = skipped ? null : _nameController.text.trim();
      final validationError = name == null
          ? null
          : UserProfile.validateName(name);
      if (validationError != null) {
        setState(() => _error = validationError);
        return;
      }
      await repo.setDisplayName(userId, name);
      await repo.setOnboardingStep(userId, OnboardingStep.nameDone);
      _advance();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _completeAccountStep({required bool skipped}) async {
    final userId = _userId;
    if (userId == null) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!skipped) {
        final balance = double.tryParse(_balanceController.text.trim()) ?? 0.0;
        try {
          await ref.read(createAccountProvider)(
            CreateAccountParams(
              name: _accountNameController.text.trim().isEmpty
                  ? 'Savings'
                  : _accountNameController.text.trim(),
              type: _accountType,
              openingBalanceMajor: balance,
            ),
          );
        } on DuplicateAccountNameException {
          // Account already exists (returning user) — treat as done.
        } on ArgumentError catch (e) {
          setState(() => _error = e.message as String?);
          return;
        }
      }
      await ref
          .read(userProfileRepositoryProvider)
          .setOnboardingStep(userId, OnboardingStep.accountDone);
      _advance();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _completeBiometricStep({required bool enable}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (enable) {
        try {
          await ref.read(securityServiceProvider).setBiometricEnabled(true);
        } catch (_) {
          // Biometric enrolment failed — continue without it.
        }
      }
      await _finish();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _advance() {
    if (_step + 1 >= _totalSteps) {
      _finish();
    } else {
      setState(() => _step++);
    }
  }

  /// Marks onboarding complete and navigates home. Escape hatch — also wired
  /// to "Skip setup" so a stuck user can never loop here.
  Future<void> _finish() async {
    final userId = _userId;
    if (userId != null) {
      await ref
          .read(userProfileRepositoryProvider)
          .setOnboardingStep(userId, OnboardingStep.complete);
    }
    ref.invalidate(userProfileProvider);
    ref.read(authStateChangedProvider.notifier).state++;
    if (mounted) context.go('/');
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!_initialised) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Progress header ───────────────────────────────────
                  Row(
                    children: [
                      if (_step > 0)
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          tooltip: 'Back',
                          onPressed: _busy
                              ? null
                              : () => setState(() => _step--),
                        )
                      else
                        const SizedBox(width: 48),
                      Expanded(
                        child: Text(
                          'Step ${_step + 1} of $_totalSteps',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _busy ? null : _finish,
                        child: const Text('Skip setup'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (_step + 1) / _totalSteps,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 32),
                  if (_error != null) ...[
                    Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    const SizedBox(height: 16),
                  ],
                  AnimatedSwitcher(
                    duration: MediaQuery.of(context).disableAnimations
                        ? Duration.zero
                        : const Duration(milliseconds: 250),
                    child: switch (_step) {
                      0 => _buildNameStep(theme),
                      1 => _buildAccountStep(theme),
                      _ => _buildBiometricStep(theme),
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNameStep(ThemeData theme) {
    return Column(
      key: const ValueKey('step-name'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'What should we call you?',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your name personalises your dashboard. You can change it any '
          'time in Settings.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _nameController,
          autofocus: true,
          maxLength: 50,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) =>
              _busy ? null : _completeNameStep(skipped: false),
          decoration: const InputDecoration(
            labelText: 'Your name',
            hintText: 'e.g. Shijith',
            counterText: '',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _busy ? null : () => _completeNameStep(skipped: false),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: const Text('Continue'),
        ),
        TextButton(
          onPressed: _busy ? null : () => _completeNameStep(skipped: true),
          child: const Text('Skip for now'),
        ),
      ],
    );
  }

  Widget _buildAccountStep(ThemeData theme) {
    return Column(
      key: const ValueKey('step-account'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Set up your first account',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Track where your money lives — bank, cash, or card. You can add '
          'more accounts later.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _accountNameController,
          maxLength: 50,
          decoration: const InputDecoration(
            labelText: 'Account name',
            counterText: '',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<AccountType>(
          initialValue: _accountType,
          decoration: const InputDecoration(
            labelText: 'Account type',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(
              value: AccountType.savings,
              child: Text('Savings'),
            ),
            DropdownMenuItem(value: AccountType.bank, child: Text('Bank')),
            DropdownMenuItem(value: AccountType.cash, child: Text('Cash')),
            DropdownMenuItem(
              value: AccountType.creditCard,
              child: Text('Credit Card'),
            ),
            DropdownMenuItem(
              value: AccountType.investment,
              child: Text('Investment'),
            ),
          ],
          onChanged: (v) => setState(() => _accountType = v!),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _balanceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Current balance',
            prefixText: '₹ ',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _busy ? null : () => _completeAccountStep(skipped: false),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: _busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : const Text('Create account'),
        ),
        TextButton(
          onPressed: _busy ? null : () => _completeAccountStep(skipped: true),
          child: const Text('Skip for now'),
        ),
      ],
    );
  }

  Widget _buildBiometricStep(ThemeData theme) {
    return Column(
      key: const ValueKey('step-biometric'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.fingerprint, size: 72, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          'Unlock with biometrics?',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _biometricAvailable
              ? 'Keep your financial data private from anyone holding your '
                    'phone — unlock with fingerprint or face.'
              : 'Biometric unlock is not available on this device. You can '
                    'enable it later in Settings if that changes.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        if (_biometricAvailable) ...[
          FilledButton.icon(
            onPressed: _busy
                ? null
                : () => _completeBiometricStep(enable: true),
            icon: const Icon(Icons.fingerprint),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            label: const Text('Enable biometric unlock'),
          ),
          TextButton(
            onPressed: _busy
                ? null
                : () => _completeBiometricStep(enable: false),
            child: const Text('Not now'),
          ),
        ] else
          FilledButton(
            onPressed: _busy
                ? null
                : () => _completeBiometricStep(enable: false),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: const Text('Finish'),
          ),
      ],
    );
  }
}
