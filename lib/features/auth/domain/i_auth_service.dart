/// Cognito sign-in requires proof of phone ownership before storing a session.
abstract interface class IAuthService {
  Future<bool> isLoggedIn();

  /// Sends an SMS code. Does not sign in.
  Future<OtpChallenge> requestSignIn(String phoneNumber);

  /// Null means signed in; a challenge means another code is required.
  Future<OtpChallenge?> verifySignIn(OtpChallenge challenge, String code);
  Future<void> signOut();
  Future<String?> getCurrentUserId();

  /// Refreshes an expiring token; null means sign-in is required.
  Future<String?> getAccessToken();
  Future<String?> getCurrentPhone();
  Future<String?> getLastUsedPhone();
}

enum OtpChallengeKind { signUp, signIn }

/// Held only in memory while the user enters the SMS code.
final class OtpChallenge {
  final String phoneNumber;
  final String username;
  final OtpChallengeKind kind;
  final String? session;
  const OtpChallenge({
    required this.phoneNumber,
    required this.username,
    required this.kind,
    this.session,
  });
}

final class AuthException implements Exception {
  final String message;
  final String? code;
  const AuthException(this.message, {this.code});
  @override
  String toString() => 'AuthException[$code]: $message';
}
