import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/i_security_service.dart';
import '../infrastructure/biometric_security_service.dart';
import '../../accounts/application/providers.dart';

final securityServiceProvider = Provider<ISecurityService>((ref) {
  return BiometricSecurityService(db: ref.read(appDatabaseProvider));
});

final securityConfigProvider =
    FutureProvider<SecurityConfigSnapshot>((ref) async {
  return ref.read(securityServiceProvider).readConfig();
});

/// App-level lock state. true = locked; false = authenticated.
final appLockedProvider = StateProvider<bool>((ref) => true);

final isSetupCompleteProvider = FutureProvider<bool>((ref) async {
  final config =
      await ref.read(securityServiceProvider).readConfig();
  return config.hasPinConfigured;
});
