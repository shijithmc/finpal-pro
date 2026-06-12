import 'dart:typed_data';

import '../../categories/domain/category.dart';
import 'scan_result.dart';

/// Contract for the AI bill scan backend (PBI-016).
/// Infrastructure layer provides the HTTP implementation.
abstract interface class IScanService {
  /// Parses a bill image via the backend Gemini proxy.
  ///
  /// [categories] is the user's own expense category list — the AI picks
  /// the category from this list only and never invents a new one.
  ///
  /// Throws [ScanException] on every failure path (quota, not-a-bill,
  /// network, service unavailable).
  Future<ScanResult> scanBill({
    required Uint8List imageBytes,
    required String mimeType,
    required List<Category> categories,
  });

  /// Returns the free-tier scan quota state for the current month.
  ///
  /// Throws [ScanException] when the backend is unreachable.
  Future<ScanQuota> getQuota();

  /// Records which AI-extracted fields the user corrected before saving.
  /// Fire-and-forget accuracy telemetry — never throws.
  Future<void> sendFeedback({
    required String scanId,
    required List<String> correctedFields,
  });
}
