import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/providers.dart';
import '../domain/i_scan_service.dart';
import '../domain/scan_result.dart';
import '../infrastructure/api_scan_service.dart';
import '../infrastructure/consent_store.dart';

final scanServiceProvider = Provider<IScanService>((ref) {
  return ApiScanService(authService: ref.read(authServiceProvider));
});

final consentStoreProvider = Provider<ConsentStore>((ref) => ConsentStore());

/// Free-tier quota for the current month. autoDispose + invalidate after
/// each scan keeps the displayed count fresh.
final scanQuotaProvider = FutureProvider.autoDispose<ScanQuota>((ref) {
  return ref.read(scanServiceProvider).getQuota();
});
