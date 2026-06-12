import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/database/app_database.dart';
import '../../categories/application/providers.dart';
import '../application/providers.dart';
import '../domain/scan_prefill.dart';
import '../domain/scan_result.dart';

/// Snap & Save — AI bill scanner entry screen (PBI-016, #61–#64).
///
/// Flow: consent (first time) → camera/gallery capture → backend Gemini
/// parse → Add Transaction form prefilled. Every failure path offers
/// manual entry — scanning is never a dead end.
class ScanBillPage extends ConsumerStatefulWidget {
  const ScanBillPage({super.key});

  @override
  ConsumerState<ScanBillPage> createState() => _ScanBillPageState();
}

class _ScanBillPageState extends ConsumerState<ScanBillPage> {
  final _picker = ImagePicker();
  bool _processing = false;
  bool _cancelled = false;

  Future<void> _startScan(ImageSource source) async {
    // One-time consent gate before any image leaves the device (slice D).
    final consentStore = ref.read(consentStoreProvider);
    if (!await consentStore.hasAiScanConsent()) {
      if (!mounted) return;
      final accepted = await _showConsentSheet();
      if (accepted != true) return;
      await consentStore.grantAiScanConsent();
    }

    final XFile? file;
    try {
      file = await _picker.pickImage(
        source: source,
        // Downscale on-device: keeps the upload ~100–400 KB, well under the
        // backend's payload cap, and is plenty for Gemini to read a bill.
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80,
      );
    } on Exception {
      if (!mounted) return;
      _showErrorDialog(
        title: 'Camera unavailable',
        message:
            'Could not open the ${source == ImageSource.camera ? 'camera' : 'gallery'}. '
            'Check the app permission in your device settings, or enter the '
            'expense manually.',
      );
      return;
    }
    if (file == null || !mounted) return;

    setState(() {
      _processing = true;
      _cancelled = false;
    });

    try {
      final bytes = await file.readAsBytes();
      final mimeType = _mimeTypeFromName(file.name);
      final categories = await ref
          .read(categoryRepositoryProvider)
          .findByType(CategoryType.expense);

      final result = await ref
          .read(scanServiceProvider)
          .scanBill(
            imageBytes: bytes,
            mimeType: mimeType,
            categories: categories,
          );

      if (!mounted || _cancelled) return;
      ref.invalidate(scanQuotaProvider);
      context.pushReplacement(
        '/transactions/new',
        extra: ScanPrefillData(
          scanId: result.scanId,
          amountPaise: result.amountPaise,
          merchant: result.merchant,
          billDate: result.billDate,
          categoryId: result.categoryId,
        ),
      );
    } on ScanException catch (e) {
      if (!mounted || _cancelled) return;
      ref.invalidate(scanQuotaProvider);
      switch (e.code) {
        case ScanFailureCode.quotaExhausted:
          _showQuotaDialog(e.message);
        case ScanFailureCode.notABill:
          _showErrorDialog(title: 'Not a bill', message: e.message);
        case ScanFailureCode.unauthorized:
          _showErrorDialog(title: 'Session expired', message: e.message);
        case ScanFailureCode.invalidImage:
        case ScanFailureCode.parseFailed:
          _showErrorDialog(
            title: 'Could not read this bill',
            message: e.message,
          );
        case ScanFailureCode.serviceUnavailable:
        case ScanFailureCode.network:
          _showErrorDialog(title: 'Scan unavailable', message: e.message);
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  /// Consent copy stays in full sentences — this is an informed-consent
  /// disclosure, not UI chrome.
  Future<bool?> _showConsentSheet() {
    final theme = Theme.of(context);
    return showModalBottomSheet<bool>(
      context: context,
      isDismissible: false,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.privacy_tip_outlined,
                size: 40,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                'AI bill reading',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Bill photos you scan are sent securely to Google Gemini to '
                'read the amount, merchant, date, and category. Images are '
                'used only to create your expense and are not stored on our '
                'servers. See our Privacy Policy for details.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.of(sheetContext).pop(true),
                child: const Text('I agree'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(false),
                child: const Text('Not now'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuotaDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Monthly scan limit reached'),
        content: Text(
          '$message\n\nFinPal Pro with unlimited AI scans is coming soon. '
          'You can still add this expense manually.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.pushReplacement('/transactions/new');
            },
            child: const Text('Enter manually'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog({required String title, required String message}) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Try again'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.pushReplacement('/transactions/new');
            },
            child: const Text('Enter manually'),
          ),
        ],
      ),
    );
  }

  static String _mimeTypeFromName(String name) {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    return switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      _ => 'image/jpeg',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quotaAsync = ref.watch(scanQuotaProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Scan Bill')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _processing
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Reading your bill…',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'This usually takes a few seconds',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => setState(() {
                        _cancelled = true;
                        _processing = false;
                      }),
                      child: const Text('Cancel'),
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.document_scanner_outlined,
                      size: 72,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Snap a bill, get an expense',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AI reads the amount, merchant, date, and picks a '
                      'category. You review before anything is saved.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    quotaAsync.when(
                      loading: () => const SizedBox(height: 20),
                      error: (_, _) => const SizedBox(height: 20),
                      data: (q) => Text(
                        '${q.remaining} of ${q.limit} free scans left this month',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: q.remaining == 0
                              ? theme.colorScheme.error
                              : theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => _startScan(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Take photo'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _startScan(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Choose image'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () =>
                          context.pushReplacement('/transactions/new'),
                      child: const Text('Enter manually instead'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
