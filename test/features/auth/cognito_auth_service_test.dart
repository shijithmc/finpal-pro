import 'dart:async';
import 'dart:convert';
import 'package:finpal_pro/features/auth/domain/i_auth_service.dart';
import 'package:finpal_pro/features/auth/infrastructure/cognito_auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _phone = '9876543210';
const _storage = FlutterSecureStorage();
final _now = DateTime.utc(2026, 9, 23);
String _jwt(Map<String, dynamic> claims) =>
    'header.${base64Url.encode(utf8.encode(jsonEncode(claims)))}.signature';
String _access({bool expired = false}) =>
    _jwt({'exp': _now.millisecondsSinceEpoch ~/ 1000 + (expired ? -10 : 3600)});
Map<String, dynamic> _tokens() => {
  'AccessToken': _access(),
  'IdToken': _jwt({'sub': 'user-1'}),
  'RefreshToken': 'refresh-token',
};
http.Response _ok(Map<String, dynamic> body) =>
    http.Response(jsonEncode(body), 200);
http.Response _error(String code) =>
    http.Response(jsonEncode({'__type': code}), 400);
String _operation(http.Request r) => r.headers['X-Amz-Target']!.split('.').last;
CognitoAuthService _service(
  Future<http.Response> Function(http.Request) handle,
) => CognitoAuthService(
  storage: _storage,
  httpClient: MockClient(handle),
  poolId: 'ap-south-1_test',
  clientId: 'otp-client',
  now: () => _now,
);
const _challenge = OtpChallenge(
  phoneNumber: _phone,
  username: '+91$_phone',
  kind: OtpChallengeKind.signIn,
  session: 'challenge-session',
);
void _verifiedStorage({bool expired = true}) =>
    FlutterSecureStorage.setMockInitialValues({
      'finpal_auth_version': 'sms-otp-v1:otp-client',
      'finpal_cognito_access': _access(expired: expired),
      'finpal_cognito_refresh': 'refresh-token',
      'finpal_phone': _phone,
      'finpal_user_id': 'user-1',
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test(
    'new user receives code without password or stored login; confirmation session signs in',
    () async {
      final operations = <String>[];
      final service = _service((request) async {
        final operation = _operation(request);
        operations.add(operation);
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        switch (operation) {
          case 'SignUp':
            expect(body.containsKey('Password'), isFalse);
            return _ok({'UserConfirmed': false, 'Session': 'signup-session'});
          case 'ConfirmSignUp':
            expect(body['ConfirmationCode'], '123456');
            expect(body['Session'], 'signup-session');
            return _ok({'Session': 'confirmed-session'});
          case 'InitiateAuth':
            expect(body['AuthFlow'], 'USER_AUTH');
            expect(body['Session'], 'confirmed-session');
            return _ok({'AuthenticationResult': _tokens()});
          default:
            throw StateError(operation);
        }
      });
      final challenge = await service.requestSignIn(_phone);
      expect(challenge.kind, OtpChallengeKind.signUp);
      expect(await _storage.read(key: 'finpal_cognito_access'), isNull);
      expect(await service.verifySignIn(challenge, '123456'), isNull);
      expect(await service.isLoggedIn(), isTrue);
      expect(await service.getCurrentUserId(), 'user-1');
      expect(operations, ['SignUp', 'ConfirmSignUp', 'InitiateAuth']);
    },
  );

  test(
    'existing user requests SMS challenge and verifies before persisting tokens',
    () async {
      final service = _service((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        switch (_operation(request)) {
          case 'SignUp':
            return _error('UsernameExistsException');
          case 'InitiateAuth':
            expect(body['AuthParameters']['PREFERRED_CHALLENGE'], 'SMS_OTP');
            return _ok({'ChallengeName': 'SMS_OTP', 'Session': 'session'});
          case 'RespondToAuthChallenge':
            expect(body['ChallengeResponses']['SMS_OTP_CODE'], '12345678');
            expect(body['Session'], 'session');
            return _ok({'AuthenticationResult': _tokens()});
          default:
            throw StateError('Unexpected operation');
        }
      });
      final challenge = await service.requestSignIn(_phone);
      expect(await _storage.read(key: 'finpal_cognito_access'), isNull);
      await service.verifySignIn(challenge, '12345678');
      expect(await service.getAccessToken(), _access());
    },
  );

  test('unconfirmed account can resend signup code', () async {
    final calls = <String>[];
    final service = _service((r) async {
      calls.add(_operation(r));
      return switch (_operation(r)) {
        'SignUp' => _error('UsernameExistsException'),
        'InitiateAuth' => _error('UserNotConfirmedException'),
        'ResendConfirmationCode' => _ok({}),
        _ => throw StateError('Unexpected operation'),
      };
    });
    expect((await service.requestSignIn(_phone)).kind, OtpChallengeKind.signUp);
    expect(calls.last, 'ResendConfirmationCode');
  });

  test('wrong or expired code never stores tokens', () async {
    for (final code in ['CodeMismatchException', 'ExpiredCodeException']) {
      final service = _service((_) async => _error(code));
      await expectLater(
        service.verifySignIn(_challenge, '123456'),
        throwsA(isA<AuthException>().having((e) => e.code, 'code', code)),
      );
      expect(await service.isLoggedIn(), isFalse);
    }
  });

  test(
    'unexpected passwordless tokens before code verification are rejected',
    () async {
      final service = _service(
        (r) async => _operation(r) == 'SignUp'
            ? _error('UsernameExistsException')
            : _ok({'AuthenticationResult': _tokens()}),
      );
      await expectLater(
        service.requestSignIn(_phone),
        throwsA(isA<AuthException>()),
      );
      expect(await _storage.read(key: 'finpal_cognito_access'), isNull);
    },
  );

  test('old phone-only session cannot access or refresh auth', () async {
    FlutterSecureStorage.setMockInitialValues({
      'finpal_cognito_access': _access(),
      'finpal_cognito_refresh': 'old-token',
      'finpal_last_phone': _phone,
    });
    final service = _service(
      (_) async => throw StateError('Must not refresh unsafe session'),
    );
    expect(await service.isLoggedIn(), isFalse);
    expect(await service.getCurrentUserId(), isNull);
    expect(await service.getLastUsedPhone(), _phone);
  });

  test(
    'concurrent expired access-token requests share one refresh and retain refresh token',
    () async {
      _verifiedStorage();
      var calls = 0;
      final pending = Completer<http.Response>();
      final service = _service((r) async {
        calls++;
        expect(jsonDecode(r.body)['AuthFlow'], 'REFRESH_TOKEN_AUTH');
        return pending.future;
      });
      final first = service.getAccessToken();
      final second = service.getAccessToken();
      await Future<void>.delayed(Duration.zero);
      pending.complete(
        _ok({'AuthenticationResult': _tokens()..remove('RefreshToken')}),
      );
      expect(await first, _access());
      expect(await second, _access());
      expect(calls, 1);
      expect(
        await _storage.read(key: 'finpal_cognito_refresh'),
        'refresh-token',
      );
    },
  );

  test(
    'rejected refresh clears session; network failure preserves offline access',
    () async {
      _verifiedStorage();
      final rejected = _service((_) async => _error('NotAuthorizedException'));
      expect(await rejected.isLoggedIn(), isFalse);
      expect(await _storage.read(key: 'finpal_cognito_refresh'), isNull);
      _verifiedStorage();
      final offline = _service(
        (_) async => throw http.ClientException('offline'),
      );
      expect(await offline.isLoggedIn(), isTrue);
      await expectLater(
        offline.getAccessToken(),
        throwsA(isA<AuthException>()),
      );
    },
  );

  test('sign-out during refresh cannot restore a session', () async {
    _verifiedStorage();
    final pending = Completer<http.Response>();
    final started = Completer<void>();
    final service = _service((r) async {
      if (_operation(r) == 'RevokeToken') return _ok({});
      started.complete();
      return pending.future;
    });
    final refreshed = service.getAccessToken();
    await started.future;
    await service.signOut();
    pending.complete(_ok({'AuthenticationResult': _tokens()}));
    expect(await refreshed, isNull);
    expect(await service.isLoggedIn(), isFalse);
  });
}
