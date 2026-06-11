import 'package:local_auth/local_auth.dart';

import 'package:drift/drift.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../domain/i_security_service.dart';

/// Biometric hardware service.
///
/// PIN auth removed in schema v4 — see CognitoAuthService for login.
/// This service is retained for biometric app-lock (Sprint 5, PBI-015).
final class BiometricSecurityService implements ISecurityService {
  final LocalAuthentication _localAuth;
  final AppDatabase _db;

  BiometricSecurityService({
    LocalAuthentication? localAuth,
    required AppDatabase db,
  }) : _localAuth = localAuth ?? LocalAuthentication(),
       _db = db;

  @override
  Future<bool> isBiometricAvailable() async {
    final canCheck = await _localAuth.canCheckBiometrics;
    final isSupported = await _localAuth.isDeviceSupported();
    return canCheck && isSupported;
  }

  @override
  Future<bool> authenticateWithBiometric() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to access FinPal Pro',
        options: const AuthenticationOptions(
          biometricOnly: false, // allow OS PIN/pattern fallback
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  @override
  Future<SecurityConfigSnapshot> readConfig() async {
    final row =
        await (_db.select(_db.securityConfigs)
              ..where((s) => s.id.equals(AppConstants.securityConfigRowId)))
            .getSingleOrNull();
    return SecurityConfigSnapshot(
      biometricEnabled: row?.biometricEnabled ?? false,
      lockOnBackground: row?.lockOnBackground ?? true,
      lockDelaySeconds: row?.lockDelaySeconds ?? 0,
    );
  }

  @override
  Future<void> setBiometricEnabled(bool enabled) async {
    await (_db.update(_db.securityConfigs)
          ..where((s) => s.id.equals(AppConstants.securityConfigRowId)))
        .write(SecurityConfigsCompanion(biometricEnabled: Value(enabled)));
  }
}
