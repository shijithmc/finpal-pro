import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../application/providers.dart';
import '../domain/i_auth_service.dart';
import 'indian_phone_formatter.dart';

/// Branded mobile number login screen — premium welcome experience.
///
/// Visual design (issue #51):
///   - Full-screen deep-emerald gradient backdrop with soft glow shapes
///   - Brand mark + name + tagline over the gradient (WCAG AA contrast)
///   - Form lives in a floating surface card with large radius + soft shadow
///   - Trust chips (Private / Instant / No OTP) above the fold
///   - Staggered entrance: brand leads, card follows (reduced-motion aware)
///
/// UX behaviour (issue #41 — unchanged):
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
    final brightness = theme.brightness;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final showQuickLogin = _lastPhone != null && !_useDifferentNumber;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          _GradientBackdrop(brightness: brightness),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 40,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 900),
                    builder: (context, t, _) {
                      // Staggered intervals: brand leads, card follows.
                      final tBrand = Curves.easeOutCubic.transform(
                        (t / 0.6).clamp(0.0, 1.0),
                      );
                      final tCard = Curves.easeOutCubic.transform(
                        ((t - 0.25) / 0.75).clamp(0.0, 1.0),
                      );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Opacity(
                            opacity: tBrand,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - tBrand)),
                              child: const _BrandHeader(),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Opacity(
                            opacity: tCard,
                            child: Transform.translate(
                              offset: Offset(0, 28 * (1 - tCard)),
                              child: _FormCard(
                                scheme: scheme,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
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
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Opacity(opacity: tCard, child: const _TrustChips()),
                          const SizedBox(height: 24),
                          Opacity(
                            opacity: tCard,
                            child: Text(
                              'Your financial data stays private on your device.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.92),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneEntry(ThemeData theme, ColorScheme scheme) {
    const validColor = AppTheme.incomeGreen;
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
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'We\'ll sign you in instantly — no OTP, no password.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
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
            style: theme.textTheme.titleMedium?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                child: Text(
                  '+91',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0),
              suffixIcon: _fieldState == _PhoneFieldState.valid
                  ? const Icon(Icons.check_circle, color: validColor)
                  : null,
              hintText: '98765 43210',
              errorText: _fieldError,
              helperText: _fieldState == _PhoneFieldState.valid
                  ? 'Looks good'
                  : ' ', // Reserve the line so layout never jumps.
              helperStyle: const TextStyle(color: validColor),
              enabled: !_loading,
              enabledBorder: borderColor == null
                  ? null
                  : OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusMedium,
                      ),
                      borderSide: BorderSide(color: borderColor, width: 1.5),
                    ),
              focusedBorder: borderColor == null
                  ? null
                  : OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusMedium,
                      ),
                      borderSide: BorderSide(color: borderColor, width: 2),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        AnimatedScale(
          scale: _canSubmit ? 1.0 : 0.98,
          duration: const Duration(milliseconds: 150),
          child: FilledButton(
            onPressed: _canSubmit ? _submit : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
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

/// Full-screen deep-emerald gradient with soft decorative glow shapes.
/// Purely decorative — excluded from semantics, ignores pointer events.
class _GradientBackdrop extends StatelessWidget {
  final Brightness brightness;

  const _GradientBackdrop({required this.brightness});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppTheme.loginBackdrop(brightness),
          ),
          child: const Stack(
            children: [
              Positioned(
                top: -90,
                right: -70,
                child: _GlowCircle(diameter: 280, alpha: 0.10),
              ),
              Positioned(
                bottom: -120,
                left: -90,
                child: _GlowCircle(diameter: 340, alpha: 0.07),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double diameter;
  final double alpha;

  const _GlowCircle({required this.diameter, required this.alpha});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withValues(alpha: alpha),
            Colors.white.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

/// Brand mark, name, and tagline over the gradient backdrop.
/// All text white — backdrop tones guarantee >= 4.5:1 contrast.
class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.30),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ShaderMask(
            shaderCallback: (bounds) =>
                AppTheme.loginBackdrop(Brightness.light).createShader(bounds),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              size: 48,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'FinPal Pro',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your money, crystal clear',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.92),
          ),
        ),
      ],
    );
  }
}

/// Floating surface card hosting the form — the focal point of the screen.
class _FormCard extends StatelessWidget {
  final ColorScheme scheme;
  final Widget child;

  const _FormCard({required this.scheme, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 48,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Value-prop chips over the gradient: why this login is safe and fast.
class _TrustChips extends StatelessWidget {
  const _TrustChips();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        _TrustChip(icon: Icons.lock_outline, label: '100% private'),
        _TrustChip(icon: Icons.bolt_outlined, label: 'Instant sign-in'),
        _TrustChip(icon: Icons.verified_user_outlined, label: 'No OTP needed'),
      ],
    );
  }
}

class _TrustChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TrustChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
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
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 20),
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
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
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
