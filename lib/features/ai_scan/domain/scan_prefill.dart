/// Carries AI-extracted bill fields from the scan flow into the
/// Add Transaction form. The form stays the single write path to the
/// ledger — AI never saves a transaction directly.
final class ScanPrefillData {
  /// Server-issued scan id — used to report corrections on save.
  final String scanId;

  /// Grand total in paise, or null when the AI could not read it.
  final int? amountPaise;

  /// Merchant name (prefills the description), or null.
  final String? merchant;

  /// Bill date, or null — the form defaults to today.
  final DateTime? billDate;

  /// AI-selected category id from the user's category list, or null.
  final String? categoryId;

  const ScanPrefillData({
    required this.scanId,
    this.amountPaise,
    this.merchant,
    this.billDate,
    this.categoryId,
  });
}
