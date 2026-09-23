import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';
import '../domain/i_auth_service.dart';

/// Native Cognito USER_AUTH/SMS_OTP. Store tokens only after verification.
final class CognitoAuthService implements IAuthService {
  static const _access = 'finpal_cognito_access';
  static const _id = 'finpal_cognito_id';
  static const _refresh = 'finpal_cognito_refresh';
  static const _phone = 'finpal_phone';
  static const _user = 'finpal_user_id';
  static const _lastPhone = 'finpal_last_phone';
  static const _version = 'finpal_auth_version';
  final FlutterSecureStorage _storage;
  final http.Client _client;
  final String _poolId;
  final String _clientId;
  final DateTime Function() _now;
  Future<String?>? _refreshing;
  Future<void> _sessionOperations = Future<void>.value();
  int _generation = 0;

  CognitoAuthService({
    FlutterSecureStorage? storage,
    http.Client? httpClient,
    String? poolId,
    String? clientId,
    DateTime Function()? now,
  }) : _storage =
           storage ??
           const FlutterSecureStorage(
             aOptions: AndroidOptions(encryptedSharedPreferences: true),
           ),
       _client = httpClient ?? http.Client(),
       _poolId = poolId ?? AppConfig.cognitoUserPoolId,
       _clientId = clientId ?? AppConfig.cognitoClientId,
       _now = now ?? DateTime.now;

  String get _sessionVersion => 'sms-otp-v1:$_clientId';

  @override
  Future<OtpChallenge> requestSignIn(String phoneNumber) async {
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phoneNumber)) {
      throw const AuthException('Enter a valid 10-digit Indian mobile number.');
    }
    final username = '+91$phoneNumber';
    try {
      final result = await _request('SignUp', {
        'ClientId': _clientId,
        'Username': username,
        'UserAttributes': [
          {'Name': 'phone_number', 'Value': username},
        ],
      });
      if (result['UserConfirmed'] == true) return _startAuth(phoneNumber);
      return OtpChallenge(
        phoneNumber: phoneNumber,
        username: username,
        kind: OtpChallengeKind.signUp,
        session: result['Session'] as String?,
      );
    } on AuthException catch (e) {
      if (e.code != 'UsernameExistsException') rethrow;
      try {
        return await _startAuth(phoneNumber);
      } on AuthException catch (e) {
        if (e.code != 'UserNotConfirmedException') rethrow;
        await _request('ResendConfirmationCode', {
          'ClientId': _clientId,
          'Username': username,
        });
        return OtpChallenge(
          phoneNumber: phoneNumber,
          username: username,
          kind: OtpChallengeKind.signUp,
        );
      }
    }
  }

  Future<OtpChallenge> _startAuth(String phone) async {
    final result = await _request('InitiateAuth', {
      'ClientId': _clientId,
      'AuthFlow': 'USER_AUTH',
      'AuthParameters': {
        'USERNAME': '+91$phone',
        'PREFERRED_CHALLENGE': 'SMS_OTP',
      },
    });
    return _readChallenge(result, phone);
  }

  OtpChallenge _readChallenge(Map<String, dynamic> result, String phone) {
    final session = result['Session'];
    if (result['ChallengeName'] != 'SMS_OTP' ||
        session is! String ||
        session.isEmpty) {
      throw const AuthException(
        'SMS sign-in is unavailable. Please try again later.',
        code: 'UnexpectedChallenge',
      );
    }
    final parameters = result['ChallengeParameters'] as Map<String, dynamic>?;
    return OtpChallenge(
      phoneNumber: phone,
      username: parameters?['USERNAME'] as String? ?? '+91$phone',
      kind: OtpChallengeKind.signIn,
      session: session,
    );
  }

  @override
  Future<OtpChallenge?> verifySignIn(
    OtpChallenge challenge,
    String code,
  ) async {
    // Cognito sign-up and sign-in codes can have different lengths.
    if (!RegExp(r'^\d{6,8}$').hasMatch(code)) {
      throw const AuthException('Enter the code from your SMS.');
    }
    // A new verification supersedes refreshes and older verification attempts.
    final generation = ++_generation;
    final Map<String, dynamic> result;
    if (challenge.kind == OtpChallengeKind.signUp) {
      final confirmed = await _request('ConfirmSignUp', {
        'ClientId': _clientId,
        'Username': challenge.username,
        'ConfirmationCode': code,
        if (challenge.session != null) 'Session': challenge.session,
      });
      final session = confirmed['Session'];
      if (session is! String || session.isEmpty) {
        return _startAuth(challenge.phoneNumber);
      }
      result = await _request('InitiateAuth', {
        'ClientId': _clientId,
        'AuthFlow': 'USER_AUTH',
        'Session': session,
        'AuthParameters': {
          'USERNAME': challenge.username,
          'PREFERRED_CHALLENGE': 'SMS_OTP',
        },
      });
      if (result['AuthenticationResult'] == null) {
        return _readChallenge(result, challenge.phoneNumber);
      }
    } else {
      result = await _request('RespondToAuthChallenge', {
        'ClientId': _clientId,
        'ChallengeName': 'SMS_OTP',
        'Session': challenge.session,
        'ChallengeResponses': {
          'USERNAME': challenge.username,
          'SMS_OTP_CODE': code,
        },
      });
    }
    final tokens = result['AuthenticationResult'];
    if (tokens is! Map<String, dynamic>) {
      throw const AuthException(
        'Could not verify the code. Request a new code.',
      );
    }
    if (generation != _generation) {
      throw const AuthException('Sign-in was cancelled.');
    }
    if (!await _storeTokens(
      tokens,
      challenge.phoneNumber,
      generation: generation,
    )) {
      throw const AuthException('Sign-in was cancelled.');
    }
    return null;
  }

  Future<bool> _hasVerifiedSession() => _withSessionLock(() async {
    if (await _storage.read(key: _version) == _sessionVersion) return true;
    // Old phone-only sessions are not proof of ownership.
    await _clearSessionUnlocked();
    return false;
  });

  @override
  Future<bool> isLoggedIn() async {
    try {
      return await getAccessToken() != null;
    } on AuthException catch (e) {
      // Preserve offline ledger access for previously verified users during outages.
      if (e.code == 'NetworkError' || e.code == 'ServiceUnavailable') {
        return await _hasVerifiedSession() &&
            await _storage.read(key: _refresh) != null;
      }
      rethrow;
    }
  }

  @override
  Future<String?> getAccessToken() async {
    if (!await _hasVerifiedSession()) return null;
    final token = await _storage.read(key: _access);
    final exp = _claims(token)?['exp'];
    if (exp is num && exp * 1000 > _now().millisecondsSinceEpoch + 60000) {
      return token;
    }
    if (_refreshing != null) return _refreshing;
    final future = _refreshTokens();
    _refreshing = future;
    try {
      return await future;
    } finally {
      if (identical(_refreshing, future)) _refreshing = null;
    }
  }

  Future<String?> _refreshTokens() async {
    final generation = _generation;
    final (refresh, phone) = await _withSessionLock(
      () async => (
        await _storage.read(key: _refresh),
        await _storage.read(key: _phone),
      ),
    );
    if (generation != _generation) return null;
    if (refresh == null || phone == null) {
      await _withSessionLock(() async {
        if (generation == _generation) await _clearSessionUnlocked();
      });
      return null;
    }
    try {
      final result = await _request('InitiateAuth', {
        'ClientId': _clientId,
        'AuthFlow': 'REFRESH_TOKEN_AUTH',
        'AuthParameters': {'REFRESH_TOKEN': refresh},
      });
      if (generation != _generation) return null;
      final tokens = result['AuthenticationResult'];
      if (tokens is! Map<String, dynamic>) {
        throw const AuthException(
          'Your session expired. Sign in again.',
          code: 'NotAuthorizedException',
        );
      }
      if (!await _storeTokens(
        tokens,
        phone,
        refreshing: true,
        generation: generation,
      )) {
        return null;
      }
      return tokens['AccessToken'] as String;
    } on AuthException catch (e) {
      if (e.code == 'NotAuthorizedException' ||
          e.code == 'UserNotFoundException') {
        await _withSessionLock(() async {
          if (generation == _generation) await _clearSessionUnlocked();
        });
        return null;
      }
      rethrow;
    }
  }

  Future<bool> _storeTokens(
    Map<String, dynamic> tokens,
    String phone, {
    bool refreshing = false,
    required int generation,
  }) async {
    final access = tokens['AccessToken'];
    final id = tokens['IdToken'];
    final refresh = tokens['RefreshToken'];
    final sub = _claims(id is String ? id : null)?['sub'];
    if (access is! String ||
        id is! String ||
        sub is! String ||
        (!refreshing && (refresh is! String || refresh.isEmpty))) {
      throw const AuthException(
        'Your session expired. Sign in again.',
        code: 'NotAuthorizedException',
      );
    }
    return _withSessionLock(() async {
      if (generation != _generation) return false;
      try {
        // This marker is the commit point. A partially written session must
        // never be mistaken for a verified one after an interruption.
        await _storage.delete(key: _version);
        await _storage.write(key: _access, value: access);
        await _storage.write(key: _id, value: id);
        if (refresh is String) {
          await _storage.write(key: _refresh, value: refresh);
        }
        await _storage.write(key: _phone, value: phone);
        await _storage.write(key: _lastPhone, value: phone);
        await _storage.write(key: _user, value: sub);
        if (generation != _generation) {
          // signOut is queued behind this write and must see the refresh token
          // so it can revoke it as well as removing the local session.
          return false;
        }
        await _storage.write(key: _version, value: _sessionVersion);
        return generation == _generation;
      } catch (_) {
        await _clearSessionUnlocked();
        rethrow;
      }
    });
  }

  @override
  Future<void> signOut() async {
    _generation++;
    final refresh = await _withSessionLock(() async {
      final token = await _storage.read(key: _refresh);
      await _clearSessionUnlocked();
      return token;
    });
    if (refresh != null) {
      try {
        await _request('RevokeToken', {
          'ClientId': _clientId,
          'Token': refresh,
        });
      } on AuthException {
        /* Local logout must work offline. */
      }
    }
  }

  Future<T> _withSessionLock<T>(Future<T> Function() operation) {
    final result = _sessionOperations.then((_) => operation());
    _sessionOperations = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  Future<void> _clearSessionUnlocked() async {
    for (final key in [_version, _access, _id, _refresh, _phone, _user]) {
      await _storage.delete(key: key);
    }
  }

  @override
  Future<String?> getCurrentUserId() async =>
      await _hasVerifiedSession() ? _storage.read(key: _user) : null;
  @override
  Future<String?> getCurrentPhone() => _storage.read(key: _phone);
  @override
  Future<String?> getLastUsedPhone() => _storage.read(key: _lastPhone);

  Map<String, dynamic>? _claims(String? jwt) {
    try {
      if (jwt == null) return null;
      return jsonDecode(
            utf8.decode(
              base64Url.decode(base64Url.normalize(jwt.split('.')[1])),
            ),
          )
          as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> _request(
    String operation,
    Map<String, dynamic> payload,
  ) async {
    if (_poolId.isEmpty || _clientId.isEmpty) {
      throw const AuthException(
        'Sign-in is not configured for this build.',
        code: 'NotConfigured',
      );
    }
    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse(
              'https://cognito-idp.${_poolId.split('_').first}.amazonaws.com/',
            ),
            headers: {
              'Content-Type': 'application/x-amz-json-1.1',
              'X-Amz-Target': 'AWSCognitoIdentityProviderService.$operation',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 20));
    } on Exception {
      throw const AuthException(
        'Check your connection and try again.',
        code: 'NetworkError',
      );
    }
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw const AuthException(
        'Sign-in is temporarily unavailable.',
        code: 'ServiceUnavailable',
      );
    }
    if (response.statusCode == 200) return body;
    final code = (body['__type'] as String? ?? 'AuthError').split('#').last;
    final message = switch (code) {
      'CodeMismatchException' => 'That code is incorrect. Please try again.',
      'ExpiredCodeException' => 'That code has expired. Request a new code.',
      'TooManyRequestsException' || 'LimitExceededException' =>
        'Too many attempts. Wait a little before trying again.',
      'CodeDeliveryFailureException' =>
        'The SMS could not be sent. Please try again later.',
      'NotAuthorizedException' => 'Your session expired. Sign in again.',
      _ => 'Could not complete sign-in. Please try again.',
    };
    throw AuthException(
      message,
      code: response.statusCode >= 500 ? 'ServiceUnavailable' : code,
    );
  }
}
