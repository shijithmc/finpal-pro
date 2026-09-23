import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/providers.dart';

class SecuritySettingsPage extends ConsumerStatefulWidget {
  const SecuritySettingsPage({super.key});
  @override
  ConsumerState<SecuritySettingsPage> createState() =>
      _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends ConsumerState<SecuritySettingsPage> {
  bool _busy = false;
  String? _error;

  Future<void> _change(Future<void> Function() write) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!await ref
          .read(securityServiceProvider)
          .authenticateWithBiometric()) {
        throw StateError('Authentication was not completed.');
      }
      await write();
      ref.invalidate(securityConfigProvider);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not change app lock. Check device authentication and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(securityConfigProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Security')),
      body: kIsWeb
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'App lock is available in the mobile app. Use your device screen lock to protect this browser.',
                ),
              ),
            )
          : config.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: TextButton(
                  onPressed: () => ref.invalidate(securityConfigProvider),
                  child: const Text('Retry'),
                ),
              ),
              data: (value) => ListView(
                children: [
                  SwitchListTile(
                    title: const Text('App lock'),
                    subtitle: const Text(
                      'Require biometrics or your device passcode when opening FinPal Pro',
                    ),
                    value: value.biometricEnabled,
                    onChanged: _busy
                        ? null
                        : (enabled) => _change(
                            () => ref
                                .read(securityServiceProvider)
                                .setBiometricEnabled(enabled),
                          ),
                  ),
                  if (value.biometricEnabled)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: DropdownButtonFormField<int>(
                        initialValue: value.lockDelaySeconds,
                        decoration: const InputDecoration(
                          labelText: 'Lock after leaving the app',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 0,
                            child: Text('Immediately'),
                          ),
                          DropdownMenuItem(
                            value: 30,
                            child: Text('30 seconds'),
                          ),
                          DropdownMenuItem(
                            value: 300,
                            child: Text('5 minutes'),
                          ),
                        ],
                        onChanged: _busy
                            ? null
                            : (seconds) {
                                if (seconds != null) {
                                  _change(
                                    () => ref
                                        .read(securityServiceProvider)
                                        .setLockDelay(seconds),
                                  );
                                }
                              },
                      ),
                    ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(_error!),
                    ),
                ],
              ),
            ),
    );
  }
}
