/// Contract for biometric hardware access.
///
/// PIN auth removed in schema v4 — mobile number (Cognito) is the login method.
/// This interface is retained for biometric app-lock (Sprint 5, PBI-015).
abstract interface class ISecurityService {
  /// True if biometric hardware is available and enrolled on this device.
  Future<bool> isBiometricAvailable();

  /// Triggers the OS biometric prompt. Returns true on success.
  Future<bool> authenticateWithBiometric();

  /// Reads current security configuration (biometric, lock-on-background).
  Future<SecurityConfigSnapshot> readConfig();

  /// Updates biometric-enabled flag.
  Future<void> setBiometricEnabled(bool enabled);
}

final class SecurityConfigSnapshot {
  /// Always false after schema v4 — PIN no longer used.
  final bool hasPinConfigured;
  final bool biometricEnabled;
  final bool lockOnBackground;
  final int lockDelaySeconds;

  const SecurityConfigSnapshot({
    this.hasPinConfigured = false,
    required this.biometricEnabled,
    required this.lockOnBackground,
    required this.lockDelaySeconds,
  });
}
