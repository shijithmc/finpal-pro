import 'dart:convert';
import 'dart:typed_data';

import 'package:finpal_pro/core/database/app_database.dart';
import 'package:finpal_pro/features/ai_scan/domain/scan_result.dart';
import 'package:finpal_pro/features/ai_scan/infrastructure/api_scan_service.dart';
import 'package:finpal_pro/features/auth/domain/i_auth_service.dart';
import 'package:finpal_pro/features/categories/domain/category.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final class _FakeAuthService implements IAuthService {
  final String? token;
  const _FakeAuthService({this.token});

  @override
  Future<String?> getAccessToken() async => token;

  @override
  Future<bool> isLoggedIn() async => token != null;

  @override
  Future<void> signIn(String phoneNumber) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<String?> getCurrentUserId() async => 'user-1';

  @override
  Future<String?> getCurrentPhone() async => null;

  @override
  Future<String?> getLastUsedPhone() async => null;
}

const _baseUrl = 'https://api.example.com';

final _categories = [
  const Category(
    id: 'cat-food',
    name: 'Food & Dining',
    type: CategoryType.expense,
    isSystem: true,
    sortOrder: 1,
  ),
];

ApiScanService _service(
  MockClient client, {
  String? token = 'valid-token',
  String baseUrl = _baseUrl,
}) {
  return ApiScanService(
    authService: _FakeAuthService(token: token),
    client: client,
    baseUrl: baseUrl,
  );
}

Future<ScanResult> _scan(ApiScanService service) {
  return service.scanBill(
    imageBytes: Uint8List.fromList([1, 2, 3]),
    mimeType: 'image/jpeg',
    categories: _categories,
  );
}

void main() {
  group('ApiScanService.scanBill', () {
    test('scanBill_success_returnsParsedResultAndSendsAuthHeader', () async {
      late http.Request captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'scanId': 'scan-1',
            'amountPaise': 31200,
            'merchant': 'Apollo Pharmacy',
            'dateIso': '2026-06-10',
            'categoryId': 'cat-food',
            'confidence': 0.88,
            'scansRemaining': 9,
          }),
          200,
        );
      });

      final result = await _scan(_service(client));

      expect(captured.url.path, '/v1/scan');
      expect(captured.headers['Authorization'], 'Bearer valid-token');
      final sentBody = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(sentBody['mimeType'], 'image/jpeg');
      expect(sentBody['categories'], [
        {'id': 'cat-food', 'name': 'Food & Dining'},
      ]);
      expect(result.amountPaise, 31200);
      expect(result.scansRemaining, 9);
    });

    test('scanBill_http429_throwsQuotaExhausted', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({'code': 'QUOTA_EXHAUSTED', 'detail': 'Limit reached.'}),
          429,
        ),
      );

      await expectLater(
        _scan(_service(client)),
        throwsA(
          isA<ScanException>().having(
            (e) => e.code,
            'code',
            ScanFailureCode.quotaExhausted,
          ),
        ),
      );
    });

    test('scanBill_http422_throwsNotABill', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({'code': 'NOT_A_BILL', 'detail': 'Not a bill.'}),
          422,
        ),
      );

      await expectLater(
        _scan(_service(client)),
        throwsA(
          isA<ScanException>().having(
            (e) => e.code,
            'code',
            ScanFailureCode.notABill,
          ),
        ),
      );
    });

    test('scanBill_http503_throwsServiceUnavailable', () async {
      final client = MockClient((_) async => http.Response('oops', 503));

      await expectLater(
        _scan(_service(client)),
        throwsA(
          isA<ScanException>().having(
            (e) => e.code,
            'code',
            ScanFailureCode.serviceUnavailable,
          ),
        ),
      );
    });

    test(
      'scanBill_noStoredToken_throwsUnauthorizedWithoutNetworkCall',
      () async {
        var called = false;
        final client = MockClient((_) async {
          called = true;
          return http.Response('{}', 200);
        });

        await expectLater(
          _scan(_service(client, token: null)),
          throwsA(
            isA<ScanException>().having(
              (e) => e.code,
              'code',
              ScanFailureCode.unauthorized,
            ),
          ),
        );
        expect(called, isFalse);
      },
    );

    test('scanBill_emptyBaseUrl_throwsServiceUnavailable', () async {
      final client = MockClient((_) async => http.Response('{}', 200));

      await expectLater(
        _scan(_service(client, baseUrl: '')),
        throwsA(
          isA<ScanException>().having(
            (e) => e.code,
            'code',
            ScanFailureCode.serviceUnavailable,
          ),
        ),
      );
    });

    test('scanBill_networkFailure_throwsNetwork', () async {
      final client = MockClient(
        (_) async => throw http.ClientException('down'),
      );

      await expectLater(
        _scan(_service(client)),
        throwsA(
          isA<ScanException>().having(
            (e) => e.code,
            'code',
            ScanFailureCode.network,
          ),
        ),
      );
    });
  });

  group('ApiScanService.getQuota', () {
    test('getQuota_success_returnsQuota', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/v1/scan/quota');
        return http.Response(jsonEncode({'used': 3, 'limit': 10}), 200);
      });

      final quota = await _service(client).getQuota();

      expect(quota.used, 3);
      expect(quota.remaining, 7);
    });
  });

  group('ApiScanService.sendFeedback', () {
    test('sendFeedback_serverError_neverThrows', () async {
      final client = MockClient((_) async => http.Response('error', 500));

      await _service(
        client,
      ).sendFeedback(scanId: 'scan-1', correctedFields: const ['category']);
    });

    test('sendFeedback_networkFailure_neverThrows', () async {
      final client = MockClient(
        (_) async => throw http.ClientException('down'),
      );

      await _service(client).sendFeedback(
        scanId: 'scan-1',
        correctedFields: const ['amount', 'category'],
      );
    });
  });
}
