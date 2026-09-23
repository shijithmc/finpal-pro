import 'dart:async';
import 'dart:convert';

import 'package:finpal_pro/features/auth/domain/i_auth_service.dart';
import 'package:finpal_pro/features/auth/infrastructure/cognito_auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';

class _Storage extends Mock implements FlutterSecureStorage {}

final _now = DateTime.utc(2026, 9, 23);
String _jwt(Map<String, dynamic> claims) =>
    'header.${base64Url.encode(utf8.encode(jsonEncode(claims)))}.signature';
Map<String, dynamic> _tokens(String user, {bool expired = false}) => {
  'AccessToken': _jwt({
    'sub': user,
    'exp': _now.millisecondsSinceEpoch ~/ 1000 + (expired ? -10 : 3600),
  }),
  'IdToken': _jwt({'sub': user}),
  'RefreshToken': 'refresh-$user',
};
const _challenge = OtpChallenge(
  phoneNumber: '9876543210',
  username: '+919876543210',
  kind: OtpChallengeKind.signIn,
  session: 'session',
);
http.Response _ok(Map<String, dynamic> value) =>
    http.Response(jsonEncode(value), 200);
String _operation(http.Request request) =>
    request.headers['X-Amz-Target']!.split('.').last;

void main() {
  late _Storage storage;
  late Map<String, String> values;
  Completer<void>? blocked;
  Completer<void>? release;
  String? blockedKey;

  setUp(() {
    storage = _Storage();
    values = {};
    blocked = null;
    release = null;
    blockedKey = null;
    when(
      () => storage.read(key: any(named: 'key')),
    ).thenAnswer((call) async => values[call.namedArguments[#key]]);
    when(() => storage.delete(key: any(named: 'key'))).thenAnswer((call) async {
      values.remove(call.namedArguments[#key]);
    });
    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((call) async {
      final key = call.namedArguments[#key] as String;
      if (key == blockedKey) {
        blockedKey = null;
        blocked!.complete();
        await release!.future;
      }
      values[key] = call.namedArguments[#value] as String;
    });
  });

  CognitoAuthService service(
    Future<http.Response> Function(http.Request) handle,
  ) => CognitoAuthService(
    storage: storage,
    httpClient: MockClient(handle),
    poolId: 'ap-south-1_test',
    clientId: 'otp-client',
    now: () => _now,
  );

  void pausePhoneWrite() {
    blocked = Completer<void>();
    release = Completer<void>();
    blockedKey = 'finpal_phone';
  }

  test(
    'session reads cannot erase credentials while verification is committing',
    () async {
      pausePhoneWrite();
      final auth = service(
        (_) async => _ok({'AuthenticationResult': _tokens('new-user')}),
      );
      final verification = auth.verifySignIn(_challenge, '123456');
      await blocked!.future;
      final user = auth.getCurrentUserId();
      release!.complete();
      await verification;
      expect(await user, 'new-user');
      expect(await auth.getAccessToken(), _tokens('new-user')['AccessToken']);
    },
  );

  test(
    'sign-out waits for an in-flight commit, cancels it and revokes its refresh token',
    () async {
      pausePhoneWrite();
      String? revoked;
      final auth = service((request) async {
        if (_operation(request) == 'RevokeToken') {
          revoked = (jsonDecode(request.body) as Map)['Token'] as String;
          return _ok({});
        }
        return _ok({'AuthenticationResult': _tokens('new-user')});
      });
      final verification = expectLater(
        auth.verifySignIn(_challenge, '123456'),
        throwsA(isA<AuthException>()),
      );
      await blocked!.future;
      final logout = auth.signOut();
      release!.complete();
      await verification;
      await logout;
      expect(await auth.isLoggedIn(), isFalse);
      expect(values['finpal_cognito_access'], isNull);
      expect(values['finpal_auth_version'], isNull);
      expect(revoked, 'refresh-new-user');
    },
  );

  test(
    'a previous user refresh cannot replace a newly verified session',
    () async {
      final old = _tokens('old-user', expired: true);
      values.addAll({
        'finpal_auth_version': 'sms-otp-v1:otp-client',
        'finpal_cognito_access': old['AccessToken'] as String,
        'finpal_cognito_refresh': 'refresh-old-user',
        'finpal_phone': '9876543210',
        'finpal_user_id': 'old-user',
      });
      final started = Completer<void>();
      final response = Completer<http.Response>();
      final auth = service((request) async {
        if (_operation(request) == 'InitiateAuth') {
          started.complete();
          return response.future;
        }
        return _ok({'AuthenticationResult': _tokens('new-user')});
      });
      final refresh = auth.getAccessToken();
      await started.future;
      await auth.verifySignIn(_challenge, '123456');
      response.complete(_ok({'AuthenticationResult': _tokens('old-user')}));
      expect(await refresh, isNull);
      expect(await auth.getCurrentUserId(), 'new-user');
      expect(await auth.getAccessToken(), _tokens('new-user')['AccessToken']);
    },
  );
}
