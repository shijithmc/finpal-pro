import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/providers.dart';
import '../domain/i_security_service.dart';

/// Hides the navigator until device authentication succeeds, including on resume.
class AppLockGate extends ConsumerStatefulWidget {
  final Widget child;
  const AppLockGate({super.key, required this.child});
  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  SecurityConfigSnapshot? _config;
  bool _locked = true;
  bool _obscured = false;
  bool _authenticating = false;
  String? _error;
  DateTime? _backgroundedAt;
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    _lifecycle =
        WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycle = state;
    final config = _config;
    if (config == null || !config.biometricEnabled) return;
    if (state != AppLifecycleState.resumed) {
      // Native authentication may temporarily make the app inactive. Still hide
      // its contents, and treat a real background transition as a lock event.
      if (!_authenticating || state != AppLifecycleState.inactive) {
        _backgroundedAt ??= DateTime.now();
      }
      setState(() => _obscured = true);
    } else {
      final elapsed = _backgroundedAt == null
          ? 0
          : DateTime.now().difference(_backgroundedAt!).inSeconds;
      setState(() {
        if (_backgroundedAt != null &&
            config.lockOnBackground &&
            elapsed >= config.lockDelaySeconds) {
          _locked = true;
        }
        _backgroundedAt = null;
        _obscured = false;
      });
    }
  }

  Future<void> _unlock() async {
    if (_authenticating) return;
    setState(() {
      _authenticating = true;
      _error = null;
    });
    try {
      final unlocked = await ref
          .read(securityServiceProvider)
          .authenticateWithBiometric();
      if (!mounted) return;
      setState(() {
        final backgrounded =
            _backgroundedAt != null && _lifecycle != AppLifecycleState.resumed;
        _locked = !unlocked || backgrounded;
        _obscured = _lifecycle != AppLifecycleState.resumed;
        if (!backgrounded) _backgroundedAt = null;
        if (!unlocked) _error = 'Authentication was not completed. Try again.';
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Device authentication is unavailable. Try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _authenticating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(securityConfigProvider);
    final next = config.valueOrNull;
    if (next != null) {
      // Enabling the setting already requires device authentication.
      if (_config != null &&
          !_config!.biometricEnabled &&
          next.biometricEnabled) {
        _locked = false;
      }
      _config = next;
    }
    final hidden =
        config.isLoading ||
        config.hasError ||
        (next?.biometricEnabled == true && (_locked || _obscured));
    return Stack(
      children: [
        Offstage(
          offstage: hidden,
          child: ExcludeFocus(excluding: hidden, child: widget.child),
        ),
        if (hidden)
          Positioned.fill(
            child: PopScope(
              canPop: false,
              child: Scaffold(
                body: SafeArea(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_outline, size: 56),
                          const SizedBox(height: 16),
                          const Text('FinPal Pro is locked'),
                          const SizedBox(height: 16),
                          if (config.isLoading)
                            const CircularProgressIndicator()
                          else if (config.hasError) ...[
                            const Text(
                              'Could not read your security settings.',
                            ),
                            TextButton(
                              onPressed: () =>
                                  ref.invalidate(securityConfigProvider),
                              child: const Text('Retry'),
                            ),
                          ] else ...[
                            const Text(
                              'Unlock with biometrics or your device passcode.',
                              textAlign: TextAlign.center,
                            ),
                            if (_error != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(_error!),
                              ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: _authenticating ? null : _unlock,
                              icon: const Icon(Icons.fingerprint),
                              label: Text(
                                _authenticating ? 'Unlocking…' : 'Unlock',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
