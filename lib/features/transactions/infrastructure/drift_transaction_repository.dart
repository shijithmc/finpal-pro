import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/i_transaction_repository.dart';
import '../domain/transaction.dart';

final class DriftTransactionRepository implements ITransactionRepository {
  final AppDatabase _db;

  const DriftTransactionRepository(this._db);

  @override
  Stream<List<FinTransaction>> watchByDateRange(DateTime from, DateTime to) {
    return (_db.select(_db.transactions)
          ..where((t) =>
              t.transactionDate.isBiggerOrEqualValue(
                  from.toIso8601String().substring(0, 10)) &
              t.transactionDate.isSmallerOrEqualValue(
                  to.toIso8601String().substring(0, 10)))
          ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)]))
        .watch()
        .map((rows) => rows.map(FinTransaction.fromData).toList());
  }

  @override
  Future<List<FinTransaction>> searchByText(String query) async {
    if (query.trim().isEmpty) return [];
    final rows = await _db.searchTransactions(query.trim());
    return rows.map(FinTransaction.fromData).toList();
  }

  @override
  Stream<List<FinTransaction>> watchBookmarked() {
    return (_db.select(_db.transactions)
          ..where((t) => t.isBookmarked.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)]))
        .watch()
        .map((rows) => rows.map(FinTransaction.fromData).toList());
  }

  @override
  Future<FinTransaction?> findById(String id) async {
    final row = await (_db.select(_db.transactions)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : FinTransaction.fromData(row);
  }

  @override
  Future<void> create(TransactionsCompanion companion) {
    return _db.writeTransaction(
      companion,
      companion.debitAccountId.value,
      companion.creditAccountId.value,
    );
  }

  @override
  Future<void> update(String id, TransactionsCompanion companion) async {
    await (_db.update(_db.transactions)..where((t) => t.id.equals(id)))
        .write(companion);
  }

  @override
  Future<void> delete(String id) async {
    await (_db.delete(_db.transactions)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> toggleBookmark(String id, bool bookmarked) async {
    await (_db.update(_db.transactions)..where((t) => t.id.equals(id)))
        .write(TransactionsCompanion(isBookmarked: Value(bookmarked)));
  }
}
