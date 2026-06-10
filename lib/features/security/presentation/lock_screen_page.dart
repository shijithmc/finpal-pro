import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../application/providers.dart';

/// Shown when app is locked. Supports PIN entry and biometric unlock.
class LockScreenPage extends ConsumerStatefulWidget {
  const LockScreenPage({super.key});

  @override
  ConsumerState<LockScreenPage> createState() => _LockScreenPageState();
}

class _LockScreenPageState extends ConsumerState<LockScreenPage> {
  final StringBuffer _pinBuffer = StringBuffer();
  String? _error;
  int _failCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  Future<void> _tryBiometric() async {
    final svc = ref.read(securityServiceProvider);
    final config = await svc.readConfig();
    if (!config.biometricEnabled) return;

    final ok = await svc.authenticateWithBiometric();
    if (ok && mounted) {
      ref.read(appLockedProvider.notifier).state = false;
    }
  }

  void _onDigit(String digit) {
    if (_pinBuffer.length >= AppConstants.maxPinLength) return;
    setState(() {
      _pinBuffer.write(digit);
      _error = null;
    });

    if (_pinBuffer.length >= AppConstants.minPinLength) {
      _submit();
    }
  }

  void _onBackspace() {
    if (_pinBuffer.isEmpty) return;
    final s = _pinBuffer.toString();
    _pinBuffer.clear();
    _pinBuffer.write(s.substring(0, s.length - 1));
    setState(() {});
  }

  Future<void> _submit() async {
    final pin = _pinBuffer.toString();
    final svc = ref.read(securityServiceProvider);
    final ok = await svc.verifyPin(pin);

    if (!mounted) return;

    if (ok) {
      ref.read(appLockedProvider.notifier).state = false;
    } else {
      _failCount++;
      setState(() {
        _pinBuffer.clear();
        _error = _failCount >= AppConstants.maxPinAttempts
            ? 'Too many failed attempts'
            : 'Incorrect PIN. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'FinPal Pro',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your PIN to continue',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              // PIN dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  AppConstants.minPinLength,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < _pinBuffer.length
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                    ),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              // Numeric keypad
              _NumericPad(
                onDigit: _onDigit,
                onBackspace: _onBackspace,
                onBiometric: _tryBiometric,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumericPad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onBiometric;

  const _NumericPad({
    required this.onDigit,
    required this.onBackspace,
    required this.onBiometric,
  });

  @override
  Widget build(BuildContext context) {
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];
    return Column(
      children: [
        ...rows.map(
          (row) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row
                .map((d) => _PadButton(label: d, onTap: () => onDigit(d)))
                .toList(),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PadButton(icon: Icons.fingerprint, onTap: onBiometric),
            _PadButton(label: '0', onTap: () => onDigit('0')),
            _PadButton(icon: Icons.backspace_outlined, onTap: onBackspace),
          ],
        ),
      ],
    );
  }
}

class _PadButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;

  const _PadButton({this.label, this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        margin: const EdgeInsets.all(8),
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.surfaceContainerHighest,
        ),
        child: Center(
          child: label != null
              ? Text(
                  label!,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                )
              : Icon(icon, size: 28),
        ),
      ),
    );
  }
}
