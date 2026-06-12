import 'package:equatable/equatable.dart';

/// Parsed bill fields returned by the scan backend (PBI-016).
///
/// Every extracted field is nullable — a partial parse is a valid outcome
/// and the user completes the missing fields on the expense form.
final class ScanResult extends Equatable {
  /// Server-issued id for this scan — used for correction telemetry.
  final String scanId;

  /// Grand total in paise, or null when unreadable.
  final int? amountPaise;

  /// Merchant / store name, or null when unreadable.
  final String? merchant;

  /// Bill date, or null when unreadable.
  final DateTime? billDate;

  /// AI-selected category id from the user's own category list, or null
  /// when the model had no confident match.
  final String? categoryId;

  /// Overall extraction confidence in [0, 1].
  final double confidence;

  /// Free-tier scans remaining this month after this scan.
  final int scansRemaining;

  const ScanResult({
    required this.scanId,
    this.amountPaise,
    this.merchant,
    this.billDate,
    this.categoryId,
    required this.confidence,
    required this.scansRemaining,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    final dateIso = json['dateIso'] as String?;
    return ScanResult(
      scanId: json['scanId'] as String,
      amountPaise: (json['amountPaise'] as num?)?.toInt(),
      merchant: json['merchant'] as String?,
      billDate: dateIso == null ? null : DateTime.tryParse(dateIso),
      categoryId: json['categoryId'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      scansRemaining: (json['scansRemaining'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    scanId,
    amountPaise,
    merchant,
    billDate,
    categoryId,
    confidence,
    scansRemaining,
  ];
}

/// Monthly free-tier scan quota state.
final class ScanQuota extends Equatable {
  final int used;
  final int limit;

  const ScanQuota({required this.used, required this.limit});

  int get remaining => (limit - used) < 0 ? 0 : limit - used;

  factory ScanQuota.fromJson(Map<String, dynamic> json) {
    return ScanQuota(
      used: (json['used'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [used, limit];
}

/// Machine-readable scan failure categories — drive the recovery UX.
enum ScanFailureCode {
  /// The image is not a bill, receipt, or invoice.
  notABill,

  /// Monthly free-tier scan limit reached (HTTP 429).
  quotaExhausted,

  /// Backend or AI service unavailable / not configured (HTTP 503).
  serviceUnavailable,

  /// Missing or expired session token (HTTP 401/403).
  unauthorized,

  /// The AI could not read the bill (HTTP 502) or the image was rejected.
  parseFailed,

  /// Image failed server-side validation (HTTP 400).
  invalidImage,

  /// Device offline or the request could not reach the backend.
  network,
}

/// Thrown when a scan operation fails. [message] is user-presentable.
final class ScanException implements Exception {
  final ScanFailureCode code;
  final String message;

  const ScanException(this.code, this.message);

  @override
  String toString() => 'ScanException[${code.name}]: $message';
}
