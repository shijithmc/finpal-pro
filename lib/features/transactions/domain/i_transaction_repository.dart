import '../../../core/database/app_database.dart';
import 'transaction.dart';

abstract interface class ITransactionRepository {
  Stream<List<FinTransaction>> watchByDateRange(DateTime from, DateTime to);

  Future<List<FinTransaction>> searchByText(String query);

  Stream<List<FinTransaction>> watchBookmarked();

  Future<FinTransaction?> findById(String id);

  /// Atomic write: inserts transaction + updates account balances + aggregates.
  Future<void> create(TransactionsCompanion companion);

  Future<void> update(String id, TransactionsCompanion companion);

  Future<void> delete(String id);

  Future<void> toggleBookmark(String id, bool bookmarked);
}
