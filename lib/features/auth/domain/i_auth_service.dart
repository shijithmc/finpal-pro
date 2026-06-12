/// Contract for Cognito-backed mobile number + PIN authentication.
/// Infrastructure layer provides the implementation.
abstract interface class IAuthService {
  /// Returns true if valid tokens are stored (user is logged in).
  Future<bool> isLoggedIn();

  /// Signs in with a 10-digit Indian mobile number and a 6-digit PIN.
  /// The PIN is verified server-side by Cognito (USER_PASSWORD_AUTH) —
  /// no OTP is ever sent.
  ///
  /// Returns [SignInOutcome.userNotFound] when the number has no account yet
  /// (caller should confirm the PIN and call [register]), and
  /// [SignInOutcome.wrongPin] when the PIN does not match.
  ///
  /// Throws [AuthException] on network error or unexpected Cognito failure.
  Future<SignInOutcome> signIn(String phoneNumber, String pin);

  /// Registers a new account for [phoneNumber] with [pin] as the credential,
  /// then signs in and stores tokens.
  ///
  /// Idempotent against races: if the number was registered concurrently,
  /// falls back to signing in with [pin] and throws [AuthException]
  /// (code `IncorrectPin`) when it does not match.
  ///
  /// Throws [AuthException] on network error or Cognito failure.
  Future<void> register(String phoneNumber, String pin);

  /// Clears all stored tokens and user identity from secure storage.
  Future<void> signOut();

  /// Returns the Cognito sub (userId) of the signed-in user, or null.
  Future<String?> getCurrentUserId();

  /// Returns the current access token JWT, or null if not logged in.
  Future<String?> getAccessToken();

  /// Returns the stored phone number (10 digits, no country prefix), or null.
  Future<String?> getCurrentPhone();

  /// Returns the last phone number used to sign in on this device, or null.
  /// Survives sign-out — powers the one-tap "Continue as" re-login.
  Future<String?> getLastUsedPhone();
}

/// Result of a [IAuthService.signIn] attempt.
enum SignInOutcome {
  /// Tokens issued and stored — user is signed in.
  success,

  /// No account exists for this phone number — confirm PIN and register.
  userNotFound,

  /// Account exists but the PIN did not match.
  wrongPin,
}

/// Thrown when an authentication operation fails.
final class AuthException implements Exception {
  final String message;
  final String? code;

  const AuthException(this.message, {this.code});

  @override
  String toString() => 'AuthException[$code]: $message';
}
