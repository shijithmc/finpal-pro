import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/providers.dart';
import '../domain/i_auth_service.dart';
import 'indian_phone_formatter.dart';

/// Branded mobile number login screen.
///
/// UX features (issue #41 — Welcome Experience):
///   - Entrance animation on the brand block (respects reduced-motion)
///   - Live 5+5 digit formatting (98765 43210)
///   - Real-time validation: green check at a valid number, specific red
///     error on an invalid first digit
///   - Inline error banner with Retry — the typed number is never cleared
///   - One-tap "Continue as" re-login with the masked last-used number
///
/// Auth model unchanged: Cognito CUSTOM_AUTH, no OTP, trust-on-first-use.
class MobileLoginPage extends ConsumerStatefulWidget {
  const MobileLoginPage({super.key});

  @override
  ConsumerState<MobileLoginPage> createState() => _MobileLoginPageState();
}

enum _PhoneFieldState { neutral, valid, invalid }

class _MobileLoginPageState extends ConsumerState<MobileLoginPage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  bool _loading = false;
  String? _bannerError;
  _PhoneFieldState _fieldState = _PhoneFieldState.neutral;
  String? _fieldError;

  /// Last number used on this device (raw 10 digits), if any.
  String? _lastPhone;
  bool _useDifferentNumber = false;

  @override
  void initState() {
    super.initState();
    _loadLastPhone();
  }

  Future<void> _loadLastPhone() async {
    final last = await ref.read(authServiceProvider).getLastUsedPhone();
    if (mounted && last != null && last.length == 10) {
      setState(() => _lastPhone = last);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Validation ───────────────────────────────────────────────────────────

  String get _digits => IndianPhoneFormatter.digitsOf(_controller.text);

  void _revalidate() {
    final digits = _digits;
    setState(() {
      _bannerError = null;
      if (digits.length < 10) {
        _fieldState = _PhoneFieldState.neutral;
        _fieldError = null;
      } else if (int.parse(digits[0]) < 6) {
        _fieldState = _PhoneFieldState.invalid;
        _fieldError = 'Mobile numbers start with 6, 7, 8 or 9';
      } else {
        _fieldState = _PhoneFieldState.valid;
        _fieldError = null;
      }
    });
  }

  bool get _canSubmit => !_loading && _fieldState == _PhoneFieldState.valid;

  // ── Submit ───────────────────────────────────────────────────────────────

  Future<void> _submit([String? phoneOverride]) async {
    final phone = phoneOverride ?? _digits;
    if (phoneOverride == null && !_canSubmit) return;

    setState(() {
      _loading = true;
      _bannerError = null;
    });

    try {
      await ref.read(authServiceProvider).signIn(phone);

      // Invalidate providers so the router picks up the new auth state.
      ref.invalidate(isLoggedInProvider);
      ref.read(authStateChangedProvider.notifier).state++;

      if (mounted) context.go('/');
    } on AuthException catch (e) {
      setState(() => _bannerError = e.message);
    } catch (_) {
      setState(
        () => _bannerError = 'Couldn\'t sign you in — check your connection.',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final showQuickLogin = _lastPhone != null && !_useDifferentNumber;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, t, child) => Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, 24 * (1 - t)),
                    child: child,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _BrandHeader(scheme: scheme, theme: theme),
                    const SizedBox(height: 48),
                    if (_bannerError != null) ...[
                      _ErrorBanner(
                        message: _bannerError!,
                        onRetry: showQuickLogin
                            ? () => _submit(_lastPhone)
                            : (_canSubmit ? _submit : null),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (showQuickLogin)
                      _QuickLoginBlock(
                        maskedPhone: _maskPhone(_lastPhone!),
                        loading: _loading,
                        onContinue: () => _submit(_lastPhone),
                        onUseDifferent: () {
                          setState(() {
                            _useDifferentNumber = true;
                            _bannerError = null;
                          });
                        },
                      )
                    else
                      _buildPhoneEntry(theme, scheme),
                    const SizedBox(height: 32),
                    Text(
                      'Your financial data stays private on your device.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneEntry(ThemeData theme, ColorScheme scheme) {
    final validColor = Colors.green.shade600;
    final borderColor = switch (_fieldState) {
      _PhoneFieldState.valid => validColor,
      _PhoneFieldState.invalid => scheme.error,
      _PhoneFieldState.neutral => null,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Enter your mobile number',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'We\'ll sign you in instantly — no OTP, no password.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Semantics(
          label: 'Mobile number',
          textField: true,
          child: TextFormField(
            controller: _controller,
            focusNode: _focusNode,
            autofocus: true,
            keyboardType: TextInputType.phone,
            inputFormatters: [IndianPhoneFormatter()],
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _canSubmit ? _submit() : null,
            onChanged: (_) => _revalidate(),
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                child: Text(
                  '+91',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0),
              suffixIcon: _fieldState == _PhoneFieldState.valid
                  ? Icon(Icons.check_circle, color: validColor)
                  : null,
              hintText: '98765 43210',
              border: const OutlineInputBorder(),
              enabledBorder: borderColor == null
                  ? null
                  : OutlineInputBorder(
                      borderSide: BorderSide(color: borderColor, width: 1.5),
                    ),
              focusedBorder: borderColor == null
                  ? null
                  : OutlineInputBorder(
                      borderSide: BorderSide(color: borderColor, width: 2),
                    ),
              errorText: _fieldError,
              helperText: _fieldState == _PhoneFieldState.valid
                  ? 'Looks good'
                  : ' ', // Reserve the line so layout never jumps.
              helperStyle: TextStyle(color: validColor),
              enabled: !_loading,
            ),
          ),
        ),
        const SizedBox(height: 16),
        AnimatedScale(
          scale: _canSubmit ? 1.0 : 0.98,
          duration: const Duration(milliseconds: 150),
          child: FilledButton(
            onPressed: _canSubmit ? _submit : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _loading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: scheme.onPrimary,
                    ),
                  )
                : const Text(
                    'Continue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }

  /// Masks a 10-digit number for display: `98765 4XXXX`.
  static String _maskPhone(String digits) {
    final first5 = digits.substring(0, 5);
    final sixth = digits.substring(5, 6);
    return '$first5 ${sixth}XXXX';
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _BrandHeader extends StatelessWidget {
  final ColorScheme scheme;
  final ThemeData theme;

  const _BrandHeader({required this.scheme, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [scheme.primary, scheme.tertiary],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            Icons.account_balance_wallet_outlined,
            size: 44,
            color: scheme.onPrimary,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'FinPal Pro',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: scheme.primary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your money, crystal clear',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ErrorBanner({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: scheme.onErrorContainer, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Retry',
                style: TextStyle(
                  color: scheme.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickLoginBlock extends StatelessWidget {
  final String maskedPhone;
  final bool loading;
  final VoidCallback onContinue;
  final VoidCallback onUseDifferent;

  const _QuickLoginBlock({
    required this.maskedPhone,
    required this.loading,
    required this.onContinue,
    required this.onUseDifferent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Welcome back',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: loading ? null : onContinue,
          icon: loading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: scheme.onPrimary,
                  ),
                )
              : const Icon(Icons.phone_android),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          label: Text(
            'Continue as +91 $maskedPhone',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: loading ? null : onUseDifferent,
          child: const Text('Use a different number'),
        ),
      ],
    );
  }
}
