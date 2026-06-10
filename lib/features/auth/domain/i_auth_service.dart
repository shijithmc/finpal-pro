/// Contract for Cognito-backed mobile number authentication.
/// Infrastructure layer provides the implementation.
abstract interface class IAuthService {
  /// Returns true if valid tokens are stored (user is logged in).
  Future<bool> isLoggedIn();

  /// Signs in (or registers) the user with a 10-digit Indian mobile number.
  /// Creates the Cognito user on first call; issues tokens via CUSTOM_AUTH
  /// on every call — no OTP, no password verification.
  ///
  /// Throws [AuthException] on network error or Cognito failure.
  Future<void> signIn(String phoneNumber);

  /// Clears all stored tokens and user identity from secure storage.
  Future<void> signOut();

  /// Returns the Cognito sub (userId) of the signed-in user, or null.
  Future<String?> getCurrentUserId();

  /// Returns the current access token JWT, or null if not logged in.
  Future<String?> getAccessToken();

  /// Returns the stored phone number (10 digits, no country prefix), or null.
  Future<String?> getCurrentPhone();
}

/// Thrown when an authentication operation fails.
final class AuthException implements Exception {
  final String message;
  final String? code;

  const AuthException(this.message, {this.code});

  @override
  String toString() => 'AuthException[$code]: $message';
}
