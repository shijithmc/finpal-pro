import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import 'package:drift/drift.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../domain/i_security_service.dart';

/// Security service backed by Android Keystore via flutter_secure_storage.
/// PIN is SHA-256 hashed with a per-device salt before storage.
/// Never stores plaintext PIN in any medium.
final class BiometricSecurityService implements ISecurityService {
  static const _pinHashKey = 'finpal_pin_hash';
  static const _pinSaltKey = 'finpal_pin_salt';

  final FlutterSecureStorage _secureStorage;
  final LocalAuthentication _localAuth;
  final AppDatabase _db;

  BiometricSecurityService({
    FlutterSecureStorage? secureStorage,
    LocalAuthentication? localAuth,
    required AppDatabase db,
  }) : _secureStorage =
           secureStorage ??
           const FlutterSecureStorage(
             aOptions: AndroidOptions(encryptedSharedPreferences: true),
           ),
       _localAuth = localAuth ?? LocalAuthentication(),
       _db = db;

  @override
  Future<bool> hasPinConfigured() async {
    final hash = await _secureStorage.read(key: _pinHashKey);
    return hash != null && hash.isNotEmpty;
  }

  @override
  Future<bool> isBiometricAvailable() async {
    final canCheck = await _localAuth.canCheckBiometrics;
    final isSupported = await _localAuth.isDeviceSupported();
    return canCheck && isSupported;
  }

  @override
  Future<void> setPin(String pin) async {
    if (pin.length < AppConstants.minPinLength ||
        pin.length > AppConstants.maxPinLength) {
      throw ArgumentError(
        'PIN must be ${AppConstants.minPinLength}–${AppConstants.maxPinLength} digits',
      );
    }
    if (!RegExp(r'^\d+$').hasMatch(pin)) {
      throw ArgumentError('PIN must contain only digits');
    }

    // Generate a per-device salt stored alongside the hash
    final salt = _generateSalt();
    final hash = _hashPin(pin, salt);

    await _secureStorage.write(key: _pinSaltKey, value: salt);
    await _secureStorage.write(key: _pinHashKey, value: hash);

    // Persist hash to DB (for migration export, not for auth)
    await (_db.update(_db.securityConfigs)
          ..where((s) => s.id.equals(AppConstants.securityConfigRowId)))
        .write(SecurityConfigsCompanion(pinHash: Value(hash)));
  }

  @override
  Future<bool> verifyPin(String candidate) async {
    final storedHash = await _secureStorage.read(key: _pinHashKey);
    final salt = await _secureStorage.read(key: _pinSaltKey);
    if (storedHash == null || salt == null) return false;
    final candidateHash = _hashPin(candidate, salt);
    return candidateHash == storedHash;
  }

  @override
  Future<bool> authenticateWithBiometric() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to access FinPal Pro',
        options: const AuthenticationOptions(
          biometricOnly: false, // allow PIN fallback via OS dialog
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> clearSecurity() async {
    await _secureStorage.delete(key: _pinHashKey);
    await _secureStorage.delete(key: _pinSaltKey);
    await (_db.update(
      _db.securityConfigs,
    )..where((s) => s.id.equals(AppConstants.securityConfigRowId))).write(
      const SecurityConfigsCompanion(
        pinHash: Value(null),
        biometricEnabled: Value(false),
      ),
    );
  }

  @override
  Future<SecurityConfigSnapshot> readConfig() async {
    final row =
        await (_db.select(_db.securityConfigs)
              ..where((s) => s.id.equals(AppConstants.securityConfigRowId)))
            .getSingleOrNull();
    final hasPin = await hasPinConfigured();
    return SecurityConfigSnapshot(
      hasPinConfigured: hasPin,
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

  // ─── Helpers ───────────────────────────────────────────────────────────────

  String _generateSalt() {
    final now = DateTime.now().microsecondsSinceEpoch.toString();
    final bytes = utf8.encode(now);
    return base64.encode(bytes);
  }

  String _hashPin(String pin, String salt) {
    final combined = utf8.encode('$salt:$pin');
    final digest = crypto.sha256.convert(combined);
    return digest.toString();
  }
}
