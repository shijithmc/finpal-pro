/// Central location for all hard-coded business rules and limits.
/// Change a constant here to affect behaviour across the whole app.
abstract final class AppConstants {
  /// Free-tier account cap. Enforced client-side in Sprint 1;
  /// server-side from Sprint 4 (quota API).
  static const int freeAccountLimit = 15;

  /// Free-tier monthly AI scan quota (PBI-016, Sprint 4).
  static const int freeAiScanMonthlyLimit = 10;

  /// Free-tier monthly WhatsApp submission quota (PBI-017, Sprint 6).
  static const int freeWhatsappMonthlyLimit = 5;

  /// Default currency for new accounts.
  static const String defaultCurrency = 'INR';

  /// Smallest currency unit multiplier — paise for INR (1 INR = 100 paise).
  static const int currencySubunits = 100;

  /// Maximum description length in characters.
  static const int maxDescriptionLength = 255;

  /// Maximum notes length in characters.
  static const int maxNotesLength = 1000;

  /// Maximum account name length in characters.
  static const int maxAccountNameLength = 50;

  /// Security config singleton row id.
  static const int securityConfigRowId = 1;
}
