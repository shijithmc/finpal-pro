import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../auth/domain/i_auth_service.dart';
import '../../categories/domain/category.dart';
import '../domain/i_scan_service.dart';
import '../domain/scan_result.dart';

/// HTTP implementation of [IScanService] against the FinPal backend
/// scan proxy (API Gateway + Lambda + Gemini).
///
/// The Gemini API key never reaches this client — all AI calls go through
/// the authenticated backend proxy.
final class ApiScanService implements IScanService {
  final http.Client _client;
  final IAuthService _auth;
  final String _baseUrl;

  ApiScanService({
    required IAuthService authService,
    http.Client? client,
    String? baseUrl,
  }) : _auth = authService,
       _client = client ?? http.Client(),
       _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  @override
  Future<ScanResult> scanBill({
    required Uint8List imageBytes,
    required String mimeType,
    required List<Category> categories,
  }) async {
    _ensureConfigured();
    final headers = await _authHeaders();

    final http.Response response;
    try {
      response = await _client.post(
        Uri.parse('$_baseUrl/v1/scan'),
        headers: headers,
        body: jsonEncode({
          'imageBase64': base64Encode(imageBytes),
          'mimeType': mimeType,
          'categories': [
            for (final c in categories) {'id': c.id, 'name': c.name},
          ],
        }),
      );
    } on Exception {
      throw const ScanException(
        ScanFailureCode.network,
        'Could not reach the scan service. Check your connection and try again.',
      );
    }

    if (response.statusCode == 200) {
      return ScanResult.fromJson(_decode(response.body));
    }
    throw _mapError(response);
  }

  @override
  Future<ScanQuota> getQuota() async {
    _ensureConfigured();
    final headers = await _authHeaders();

    final http.Response response;
    try {
      response = await _client.get(
        Uri.parse('$_baseUrl/v1/scan/quota'),
        headers: headers,
      );
    } on Exception {
      throw const ScanException(
        ScanFailureCode.network,
        'Could not reach the scan service.',
      );
    }

    if (response.statusCode == 200) {
      return ScanQuota.fromJson(_decode(response.body));
    }
    throw _mapError(response);
  }

  @override
  Future<void> sendFeedback({
    required String scanId,
    required List<String> correctedFields,
  }) async {
    // Best-effort telemetry — never surfaces an error to the user.
    try {
      _ensureConfigured();
      final headers = await _authHeaders();
      await _client.post(
        Uri.parse('$_baseUrl/v1/scan/feedback'),
        headers: headers,
        body: jsonEncode({
          'scanId': scanId,
          'correctedFields': correctedFields,
        }),
      );
    } on Exception {
      // Swallowed by design: a lost correction event must not break saving.
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _ensureConfigured() {
    if (_baseUrl.isEmpty) {
      throw const ScanException(
        ScanFailureCode.serviceUnavailable,
        'AI scanning is not configured for this build. '
        'You can still add the expense manually.',
      );
    }
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await _auth.getAccessToken();
    if (token == null || token.isEmpty) {
      throw const ScanException(
        ScanFailureCode.unauthorized,
        'Your session has expired. Sign in again to scan bills.',
      );
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Map<String, dynamic> _decode(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } on FormatException {
      throw const ScanException(
        ScanFailureCode.parseFailed,
        'The scan service returned an unexpected response.',
      );
    }
  }

  ScanException _mapError(http.Response response) {
    String detail = '';
    try {
      detail =
          (jsonDecode(response.body) as Map<String, dynamic>)['detail']
              as String? ??
          '';
    } on FormatException {
      // Non-JSON error body — fall through to status-based messages.
    }

    return switch (response.statusCode) {
      401 || 403 => const ScanException(
        ScanFailureCode.unauthorized,
        'Your session has expired. Sign in again to scan bills.',
      ),
      422 => ScanException(
        ScanFailureCode.notABill,
        detail.isNotEmpty
            ? detail
            : 'This image does not look like a bill or receipt.',
      ),
      429 => ScanException(
        ScanFailureCode.quotaExhausted,
        detail.isNotEmpty
            ? detail
            : 'You have used all your free scans for this month.',
      ),
      400 => ScanException(
        ScanFailureCode.invalidImage,
        detail.isNotEmpty ? detail : 'This image could not be uploaded.',
      ),
      503 => ScanException(
        ScanFailureCode.serviceUnavailable,
        detail.isNotEmpty
            ? detail
            : 'AI scanning is temporarily unavailable. '
                  'Please enter the expense manually.',
      ),
      _ => ScanException(
        ScanFailureCode.parseFailed,
        detail.isNotEmpty
            ? detail
            : 'The bill could not be read. Try a clearer photo.',
      ),
    };
  }
}
