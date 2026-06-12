import 'package:finpal_pro/features/ai_scan/domain/scan_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScanResult.fromJson', () {
    test('fromJson_fullPayload_mapsAllFields', () {
      final result = ScanResult.fromJson({
        'scanId': 'scan-123',
        'amountPaise': 54000,
        'merchant': 'Saravana Bhavan',
        'dateIso': '2026-06-12',
        'categoryId': 'cat-food',
        'confidence': 0.92,
        'scansRemaining': 7,
      });

      expect(result.scanId, 'scan-123');
      expect(result.amountPaise, 54000);
      expect(result.merchant, 'Saravana Bhavan');
      expect(result.billDate, DateTime(2026, 6, 12));
      expect(result.categoryId, 'cat-food');
      expect(result.confidence, 0.92);
      expect(result.scansRemaining, 7);
    });

    test('fromJson_nullOptionalFields_parsesPartialResult', () {
      final result = ScanResult.fromJson({
        'scanId': 'scan-456',
        'amountPaise': null,
        'merchant': null,
        'dateIso': null,
        'categoryId': null,
        'confidence': 0.3,
        'scansRemaining': 0,
      });

      expect(result.scanId, 'scan-456');
      expect(result.amountPaise, isNull);
      expect(result.merchant, isNull);
      expect(result.billDate, isNull);
      expect(result.categoryId, isNull);
      expect(result.scansRemaining, 0);
    });

    test('fromJson_unparseableDate_returnsNullBillDate', () {
      final result = ScanResult.fromJson({
        'scanId': 'scan-789',
        'dateIso': 'not-a-date',
        'confidence': 0.5,
        'scansRemaining': 3,
      });

      expect(result.billDate, isNull);
    });

    test('fromJson_missingConfidenceAndRemaining_defaultsToZero', () {
      final result = ScanResult.fromJson({'scanId': 'scan-000'});

      expect(result.confidence, 0);
      expect(result.scansRemaining, 0);
    });
  });

  group('ScanQuota', () {
    test('fromJson_mapsUsedAndLimit_computesRemaining', () {
      final quota = ScanQuota.fromJson({'used': 4, 'limit': 10});

      expect(quota.used, 4);
      expect(quota.limit, 10);
      expect(quota.remaining, 6);
    });

    test('remaining_usedExceedsLimit_clampsToZero', () {
      const quota = ScanQuota(used: 12, limit: 10);

      expect(quota.remaining, 0);
    });
  });
}
