/// Contract for backup, restore, and export operations.
/// Infrastructure implementation uses path_provider + share_plus.
abstract interface class IBackupService {
  /// Exports all transactions as a TSV file and shares it via the OS share sheet.
  /// Returns the path of the written file.
  Future<String> exportTransactionsTsv();

  /// Creates a full JSON backup of accounts, categories, and transactions,
  /// shares it via the OS share sheet, and returns the file path.
  Future<String> createJsonBackup();

  /// Restores the database from a JSON backup file at [filePath].
  /// DESTRUCTIVE — replaces all existing data after user confirmation.
  /// Throws [BackupRestoreException] on schema mismatch or parse failure.
  Future<void> restoreFromJson(String filePath);

  /// Returns the ISO-8601 timestamp of the most recent backup, or null.
  Future<DateTime?> lastBackupTime();
}

/// Thrown when a restore operation fails due to a schema or parse error.
final class BackupRestoreException implements Exception {
  final String message;

  const BackupRestoreException(this.message);

  @override
  String toString() => 'BackupRestoreException: $message';
}
