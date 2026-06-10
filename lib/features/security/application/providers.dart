import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/i_security_service.dart';
import '../infrastructure/biometric_security_service.dart';
import '../../accounts/application/providers.dart';

/// Biometric security service — used for biometric hardware checks.
/// PIN-based auth providers removed in schema v4 (mobile number login).
final securityServiceProvider = Provider<ISecurityService>((ref) {
  return BiometricSecurityService(db: ref.read(appDatabaseProvider));
});

/// Read-only security config (biometric availability, lock-on-background).
final securityConfigProvider = FutureProvider<SecurityConfigSnapshot>((
  ref,
) async {
  return ref.read(securityServiceProvider).readConfig();
});
