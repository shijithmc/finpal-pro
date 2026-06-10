import '../../../core/database/app_database.dart';
import 'account.dart';

/// Contract for account persistence. Infrastructure layer implements this.
abstract interface class IAccountRepository {
  /// Live stream of all non-archived accounts, sorted by sort_order.
  Stream<List<Account>> watchAll();

  /// Returns a single account or null if not found.
  Future<Account?> findById(String id);

  /// Returns count of non-archived accounts (used for free-tier cap check).
  Future<int> countActive();

  /// Inserts a new account. Throws [DuplicateAccountNameException] if name exists.
  Future<void> create(AccountsCompanion companion);

  /// Updates an existing account's mutable fields.
  Future<void> update(String id, AccountsCompanion companion);

  /// Soft-deletes (archives) an account. Physical delete is not supported.
  Future<void> archive(String id);
}

/// Thrown when attempting to create or rename an account to a name already in use.
final class DuplicateAccountNameException implements Exception {
  final String name;
  const DuplicateAccountNameException(this.name);
  @override
  String toString() => 'Account name "$name" is already in use';
}

/// Thrown when free-tier account cap is exceeded.
final class AccountLimitExceededException implements Exception {
  final int limit;
  const AccountLimitExceededException(this.limit);
  @override
  String toString() => 'Free tier allows a maximum of $limit accounts';
}
