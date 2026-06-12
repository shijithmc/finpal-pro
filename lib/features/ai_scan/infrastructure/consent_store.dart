import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the one-time AI processing consent (DPDP-aware, PBI-016).
///
/// Consent is recorded on-device only. The key is versioned so a future
/// consent-copy change can re-prompt by bumping the suffix.
final class ConsentStore {
  static const _aiScanConsentKey = 'finpal_ai_scan_consent_v1';

  final FlutterSecureStorage _storage;

  ConsentStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
          );

  /// True when the user has accepted AI image processing on this device.
  Future<bool> hasAiScanConsent() async {
    final value = await _storage.read(key: _aiScanConsentKey);
    return value == 'accepted';
  }

  /// Records acceptance — the consent sheet is never shown again.
  Future<void> grantAiScanConsent() =>
      _storage.write(key: _aiScanConsentKey, value: 'accepted');
}
