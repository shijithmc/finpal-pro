import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:finpal_pro/features/auth/domain/i_auth_service.dart';
import 'package:finpal_pro/features/auth/infrastructure/cognito_auth_service.dart';

/// In-memory FlutterSecureStorage double — routes read/write/delete to a map.
class _FakeSecureStorage implements FlutterSecureStorage {
  final Map<String, String> store = {};

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final key = invocation.namedArguments[#key] as String?;
    switch (invocation.memberName) {
      case #read:
        return Future<String?>.value(store[key]);
      case #write:
        final value = invocation.namedArguments[#value] as String?;
        if (value == null) {
          store.remove(key);
        } else {
          store[key!] = value;
        }
        return Future<void>.value();
      case #delete:
        store.remove(key);
        return Future<void>.value();
      default:
        return super.noSuchMethod(invocation);
    }
  }
}

/// Builds an unsigned JWT whose payload carries the given claims.
String _fakeJwt(Map<String, dynamic> claims) {
  final header = base64Url.encode(utf8.encode(jsonEncode({'alg': 'none'})));
  final payload = base64Url.encode(utf8.encode(jsonEncode(claims)));
  return '$header.$payload.signature';
}

String _authSuccessBody() => jsonEncode({
  'AuthenticationResult': {
    'AccessToken': 'access-token',
    'IdToken': _fakeJwt({'sub': 'user-123'}),
    'RefreshToken': 'refresh-token',
  },
});

String _cognitoError(String type, String message) =>
    jsonEncode({'__type': type, 'message': message});

void main() {
  const phone = '9876543210';
  const pin = '123456';

  group('CognitoAuthService.signIn', () {
    test(
      'returns success and stores tokens when Cognito authenticates',
      () async {
        final storage = _FakeSecureStorage();
        late Map<String, dynamic> sentBody;
        final service = CognitoAuthService(
          storage: storage,
          httpClient: MockClient((request) async {
            sentBody = jsonDecode(request.body) as Map<String, dynamic>;
            return http.Response(_authSuccessBody(), 200);
          }),
        );

        final outcome = await service.signIn(phone, pin);

        expect(outcome, SignInOutcome.success);
        expect(sentBody['AuthFlow'], 'USER_PASSWORD_AUTH');
        expect(sentBody['AuthParameters'], {
          'USERNAME': '+91$phone',
          'PASSWORD': pin,
        });
        expect(storage.store['finpal_cognito_access'], 'access-token');
        expect(storage.store['finpal_cognito_refresh'], 'refresh-token');
        expect(storage.store['finpal_user_id'], 'user-123');
        expect(storage.store['finpal_phone'], phone);
        expect(storage.store['finpal_last_phone'], phone);
      },
    );

    test('returns userNotFound when the number has no account', () async {
      final service = CognitoAuthService(
        storage: _FakeSecureStorage(),
        httpClient: MockClient(
          (_) async => http.Response(
            _cognitoError('UserNotFoundException', 'User does not exist.'),
            400,
          ),
        ),
      );

      expect(await service.signIn(phone, pin), SignInOutcome.userNotFound);
    });

    test('returns wrongPin when the PIN does not match', () async {
      final service = CognitoAuthService(
        storage: _FakeSecureStorage(),
        httpClient: MockClient(
          (_) async => http.Response(
            _cognitoError(
              'NotAuthorizedException',
              'Incorrect username or password.',
            ),
            400,
          ),
        ),
      );

      expect(await service.signIn(phone, pin), SignInOutcome.wrongPin);
    });

    test(
      'throws AuthException with the Cognito code on other errors',
      () async {
        final service = CognitoAuthService(
          storage: _FakeSecureStorage(),
          httpClient: MockClient(
            (_) async => http.Response(
              _cognitoError('TooManyRequestsException', 'Rate exceeded'),
              400,
            ),
          ),
        );

        expect(
          () => service.signIn(phone, pin),
          throwsA(
            isA<AuthException>().having(
              (e) => e.code,
              'code',
              'TooManyRequestsException',
            ),
          ),
        );
      },
    );

    test('rejects a non-6-digit PIN before any network call', () async {
      final service = CognitoAuthService(
        storage: _FakeSecureStorage(),
        httpClient: MockClient(
          (_) async => fail('No HTTP call expected for an invalid PIN'),
        ),
      );

      expect(
        () => service.signIn(phone, '12345'),
        throwsA(
          isA<AuthException>().having((e) => e.code, 'code', 'InvalidPin'),
        ),
      );
    });
  });

  group('CognitoAuthService.register', () {
    test('signs up with the PIN as password, then signs in', () async {
      final storage = _FakeSecureStorage();
      final targets = <String>[];
      late Map<String, dynamic> signUpBody;
      final service = CognitoAuthService(
        storage: storage,
        httpClient: MockClient((request) async {
          final target = request.headers['X-Amz-Target'] ?? '';
          targets.add(target);
          if (target.endsWith('SignUp')) {
            signUpBody = jsonDecode(request.body) as Map<String, dynamic>;
            return http.Response(jsonEncode({'UserConfirmed': true}), 200);
          }
          return http.Response(_authSuccessBody(), 200);
        }),
      );

      await service.register(phone, pin);

      expect(targets, [
        'AWSCognitoIdentityProviderService.SignUp',
        'AWSCognitoIdentityProviderService.InitiateAuth',
      ]);
      expect(signUpBody['Username'], '+91$phone');
      expect(signUpBody['Password'], pin);
      expect(storage.store['finpal_cognito_access'], 'access-token');
    });

    test(
      'falls back to sign-in when the number was registered concurrently',
      () async {
        final storage = _FakeSecureStorage();
        final service = CognitoAuthService(
          storage: storage,
          httpClient: MockClient((request) async {
            final target = request.headers['X-Amz-Target'] ?? '';
            if (target.endsWith('SignUp')) {
              return http.Response(
                _cognitoError('UsernameExistsException', 'User exists'),
                400,
              );
            }
            return http.Response(_authSuccessBody(), 200);
          }),
        );

        await service.register(phone, pin);

        expect(storage.store['finpal_cognito_access'], 'access-token');
      },
    );

    test('throws IncorrectPin when the existing account has another PIN', () {
      final service = CognitoAuthService(
        storage: _FakeSecureStorage(),
        httpClient: MockClient((request) async {
          final target = request.headers['X-Amz-Target'] ?? '';
          if (target.endsWith('SignUp')) {
            return http.Response(
              _cognitoError('UsernameExistsException', 'User exists'),
              400,
            );
          }
          return http.Response(
            _cognitoError(
              'NotAuthorizedException',
              'Incorrect username or password.',
            ),
            400,
          );
        }),
      );

      expect(
        () => service.register(phone, pin),
        throwsA(
          isA<AuthException>().having((e) => e.code, 'code', 'IncorrectPin'),
        ),
      );
    });
  });
}
