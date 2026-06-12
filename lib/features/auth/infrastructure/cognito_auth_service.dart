import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../domain/i_auth_service.dart';

/// Cognito-backed auth service using direct REST API calls.
///
/// Auth model: phone number + 6-digit PIN. The PIN is the Cognito password,
/// verified server-side via USER_PASSWORD_AUTH — Cognito provides credential
/// hashing and escalating lockout on repeated failures. No OTP is ever sent;
/// the PreSignUp Lambda auto-confirms new users.
///
/// Uses Cognito REST API directly (no AWS SDK dependency):
///   POST https://cognito-idp.{region}.amazonaws.com/
///   X-Amz-Target: AWSCognitoIdentityProviderService.{Operation}
///
/// Token storage: flutter_secure_storage (encrypted on-device).
final class CognitoAuthService implements IAuthService {
  // ── Storage keys ──────────────────────────────────────────────────────────
  static const _accessTokenKey = 'finpal_cognito_access';
  static const _idTokenKey = 'finpal_cognito_id';
  static const _refreshTokenKey = 'finpal_cognito_refresh';
  static const _phoneKey = 'finpal_phone';
  static const _userIdKey = 'finpal_user_id';

  // Survives sign-out — powers the one-tap "Continue as" re-login.
  static const _lastPhoneKey = 'finpal_last_phone';

  final FlutterSecureStorage _storage;
  final http.Client _httpClient;

  CognitoAuthService({FlutterSecureStorage? storage, http.Client? httpClient})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
          ),
      _httpClient = httpClient ?? http.Client();

  // ── IAuthService ──────────────────────────────────────────────────────────

  @override
  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: _accessTokenKey);
    return token != null && token.isNotEmpty;
  }

  @override
  Future<SignInOutcome> signIn(String phoneNumber, String pin) async {
    _validatePhone(phoneNumber);
    _validatePin(pin);

    final phoneE164 = '+91$phoneNumber';

    final response = await _initiateAuth(phoneE164, pin);

    if (response.statusCode == 200) {
      final body = _parseBody(response.body);
      await _storeTokens(_requireAuthResult(body), phoneNumber);
      return SignInOutcome.success;
    }

    final body = _parseBody(response.body);
    final type = body['__type'] as String? ?? '';

    // PreventUserExistenceErrors is OFF on the app client specifically so
    // this distinction is possible: new number → registration flow.
    if (type == 'UserNotFoundException') return SignInOutcome.userNotFound;
    if (type == 'NotAuthorizedException') return SignInOutcome.wrongPin;

    throw AuthException(
      body['message'] as String? ?? 'Authentication failed',
      code: type.isEmpty ? 'AuthError' : type,
    );
  }

  @override
  Future<void> register(String phoneNumber, String pin) async {
    _validatePhone(phoneNumber);
    _validatePin(pin);

    final phoneE164 = '+91$phoneNumber';

    // Create the Cognito user with the PIN as the password. The PreSignUp
    // Lambda auto-confirms and auto-verifies the phone — no OTP is sent.
    final response = await _httpClient.post(
      _endpoint,
      headers: _headers('SignUp'),
      body: jsonEncode({
        'ClientId': AppConfig.cognitoClientId,
        'Username': phoneE164,
        'Password': pin,
        'UserAttributes': [
          {'Name': 'phone_number', 'Value': phoneE164},
        ],
      }),
    );

    if (response.statusCode != 200) {
      final body = _parseBody(response.body);
      final type = body['__type'] as String? ?? '';

      // Registered concurrently (or stale userNotFound) — fall through and
      // attempt sign-in with the provided PIN.
      if (type != 'UsernameExistsException') {
        throw AuthException(
          body['message'] as String? ?? 'Registration failed',
          code: type.isEmpty ? 'SignUpError' : type,
        );
      }
    }

    final authResponse = await _initiateAuth(phoneE164, pin);

    if (authResponse.statusCode != 200) {
      final body = _parseBody(authResponse.body);
      final type = body['__type'] as String? ?? '';
      if (type == 'NotAuthorizedException') {
        throw const AuthException(
          'This number is already registered with a different PIN.',
          code: 'IncorrectPin',
        );
      }
      throw AuthException(
        body['message'] as String? ?? 'Authentication failed',
        code: type.isEmpty ? 'AuthError' : type,
      );
    }

    final body = _parseBody(authResponse.body);
    await _storeTokens(_requireAuthResult(body), phoneNumber);
  }

  @override
  Future<void> signOut() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _idTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _phoneKey);
    await _storage.delete(key: _userIdKey);
  }

  @override
  Future<String?> getCurrentUserId() => _storage.read(key: _userIdKey);

  @override
  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);

  @override
  Future<String?> getCurrentPhone() => _storage.read(key: _phoneKey);

  @override
  Future<String?> getLastUsedPhone() => _storage.read(key: _lastPhoneKey);

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// POST to the Cognito endpoint for this User Pool's region.
  Uri get _endpoint {
    final region = AppConfig.cognitoUserPoolId.split('_').first;
    return Uri.parse('https://cognito-idp.$region.amazonaws.com/');
  }

  Map<String, String> _headers(String target) => {
    'Content-Type': 'application/x-amz-json-1.1',
    'X-Amz-Target': 'AWSCognitoIdentityProviderService.$target',
  };

  /// Calls InitiateAuth with USER_PASSWORD_AUTH (PIN as password).
  Future<http.Response> _initiateAuth(String phoneE164, String pin) {
    return _httpClient.post(
      _endpoint,
      headers: _headers('InitiateAuth'),
      body: jsonEncode({
        'AuthFlow': 'USER_PASSWORD_AUTH',
        'AuthParameters': {'USERNAME': phoneE164, 'PASSWORD': pin},
        'ClientId': AppConfig.cognitoClientId,
      }),
    );
  }

  /// Extracts AuthenticationResult or throws — USER_PASSWORD_AUTH with the
  /// pool's config (no MFA, auto-confirmed users) never returns a challenge.
  Map<String, dynamic> _requireAuthResult(Map<String, dynamic> body) {
    final authResult = body['AuthenticationResult'] as Map<String, dynamic>?;
    if (authResult == null) {
      final challenge = body['ChallengeName'] as String?;
      throw AuthException(
        'Unexpected challenge from Cognito: $challenge. '
        'Check the user pool MFA and app client configuration.',
        code: 'UnexpectedChallenge',
      );
    }
    return authResult;
  }

  /// Stores all tokens and user identity in secure storage.
  Future<void> _storeTokens(
    Map<String, dynamic> authResult,
    String phone,
  ) async {
    final accessToken = authResult['AccessToken'] as String?;
    final idToken = authResult['IdToken'] as String?;
    final refreshToken = authResult['RefreshToken'] as String?;

    if (accessToken == null || idToken == null) {
      throw const AuthException(
        'Cognito returned no tokens after authentication',
        code: 'MissingTokens',
      );
    }

    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _idTokenKey, value: idToken);
    if (refreshToken != null) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
    await _storage.write(key: _phoneKey, value: phone);
    await _storage.write(key: _lastPhoneKey, value: phone);

    final userId = _extractSub(idToken);
    if (userId != null) {
      await _storage.write(key: _userIdKey, value: userId);
    }
  }

  /// Extracts the `sub` claim from a JWT payload without verifying the signature.
  /// Cognito already verified the token; we only need the user ID.
  String? _extractSub(String jwtToken) {
    try {
      final parts = jwtToken.split('.');
      if (parts.length != 3) return null;
      final payload = parts[1];
      final padded = payload.padRight(
        payload.length + (4 - payload.length % 4) % 4,
        '=',
      );
      final decoded = utf8.decode(base64Url.decode(padded));
      final claims = jsonDecode(decoded) as Map<String, dynamic>;
      return claims['sub'] as String?;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _parseBody(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  /// Validates that [phoneNumber] is a 10-digit Indian mobile number.
  void _validatePhone(String phoneNumber) {
    if (phoneNumber.length != 10 ||
        !RegExp(r'^\d{10}$').hasMatch(phoneNumber)) {
      throw const AuthException(
        'Phone number must be exactly 10 digits',
        code: 'InvalidPhoneNumber',
      );
    }
    final firstDigit = int.parse(phoneNumber[0]);
    if (firstDigit < 6) {
      throw const AuthException(
        'Invalid mobile number: must start with 6–9',
        code: 'InvalidPhoneNumber',
      );
    }
  }

  /// Validates that [pin] is exactly 6 digits (Cognito password policy floor).
  void _validatePin(String pin) {
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      throw const AuthException(
        'PIN must be exactly 6 digits',
        code: 'InvalidPin',
      );
    }
  }
}
