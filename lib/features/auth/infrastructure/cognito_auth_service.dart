import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../domain/i_auth_service.dart';

/// Cognito-backed auth service using direct REST API calls.
///
/// Auth model: CUSTOM_AUTH where the DefineAuthChallenge Lambda issues tokens
/// immediately on the first call — no OTP, no password verification.
/// Phone number is the sole identity factor (trust-on-first-use).
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

  // Used for signUp only — never submitted for authentication.
  // CUSTOM_AUTH does not verify this password; only the signUp call needs it
  // to satisfy Cognito's password policy.
  static const _signUpPassword = 'FinPalDev#2026';

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
  Future<void> signIn(String phoneNumber) async {
    _validatePhone(phoneNumber);

    final phoneE164 = '+91$phoneNumber';

    // Step 1 — Create the Cognito user if this is their first login.
    // The PreSignUp Lambda auto-confirms and auto-verifies the phone number
    // without sending any OTP.
    await _ensureUserExists(phoneE164);

    // Step 2 — Authenticate via CUSTOM_AUTH.
    // The DefineAuthChallenge Lambda sets issueTokens=true immediately on the
    // first call, so Cognito responds with AuthenticationResult (tokens).
    final tokens = await _initiateCustomAuth(phoneE164);

    // Step 3 — Persist tokens to secure storage.
    await _storeTokens(tokens, phoneNumber);
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

  /// Creates the Cognito user if they don't exist yet.
  /// Silently ignores UsernameExistsException.
  Future<void> _ensureUserExists(String phoneE164) async {
    final response = await _httpClient.post(
      _endpoint,
      headers: _headers('SignUp'),
      body: jsonEncode({
        'ClientId': AppConfig.cognitoClientId,
        'Username': phoneE164,
        'Password': _signUpPassword,
        'UserAttributes': [
          {'Name': 'phone_number', 'Value': phoneE164},
        ],
      }),
    );

    if (response.statusCode == 200) return; // Created successfully.

    final body = _parseBody(response.body);
    final type = body['__type'] as String? ?? '';

    if (type == 'UsernameExistsException') return; // Already exists — OK.

    throw AuthException(
      body['message'] as String? ?? 'Sign-up failed',
      code: type,
    );
  }

  /// Calls InitiateAuth with CUSTOM_AUTH.
  /// Returns the AuthenticationResult map with AccessToken / IdToken / RefreshToken.
  Future<Map<String, dynamic>> _initiateCustomAuth(String phoneE164) async {
    final response = await _httpClient.post(
      _endpoint,
      headers: _headers('InitiateAuth'),
      body: jsonEncode({
        'AuthFlow': 'CUSTOM_AUTH',
        'AuthParameters': {'USERNAME': phoneE164},
        'ClientId': AppConfig.cognitoClientId,
      }),
    );

    if (response.statusCode != 200) {
      final body = _parseBody(response.body);
      throw AuthException(
        body['message'] as String? ?? 'Authentication failed',
        code: body['__type'] as String? ?? 'AuthError',
      );
    }

    final body = _parseBody(response.body);

    // If DefineAuthChallenge issues tokens immediately, Cognito returns
    // AuthenticationResult directly — no ChallengeName field.
    final authResult = body['AuthenticationResult'] as Map<String, dynamic>?;
    if (authResult == null) {
      final challenge = body['ChallengeName'] as String?;
      throw AuthException(
        'Unexpected challenge from Cognito: $challenge. '
        'Check DefineAuthChallenge Lambda configuration.',
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
}
