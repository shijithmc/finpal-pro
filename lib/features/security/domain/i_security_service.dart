/// Contract for PIN and biometric authentication.
/// Infrastructure layer provides the implementation backed by Android Keystore.
abstract interface class ISecurityService {
  /// True if a PIN has been configured.
  Future<bool> hasPinConfigured();

  /// True if biometric hardware is available and enrolled on this device.
  Future<bool> isBiometricAvailable();

  /// Sets (or changes) the PIN. Hashes before storage — never stores plaintext.
  Future<void> setPin(String pin);

  /// Verifies a candidate PIN against the stored hash.
  Future<bool> verifyPin(String candidate);

  /// Triggers biometric prompt. Returns true on success.
  Future<bool> authenticateWithBiometric();

  /// Clears PIN and disables biometric (used for PIN removal or data wipe).
  Future<void> clearSecurity();

  /// Reads current security configuration.
  Future<SecurityConfigSnapshot> readConfig();

  /// Updates biometric-enabled flag.
  Future<void> setBiometricEnabled(bool enabled);
}

final class SecurityConfigSnapshot {
  final bool hasPinConfigured;
  final bool biometricEnabled;
  final bool lockOnBackground;
  final int lockDelaySeconds;

  const SecurityConfigSnapshot({
    required this.hasPinConfigured,
    required this.biometricEnabled,
    required this.lockOnBackground,
    required this.lockDelaySeconds,
  });
}
