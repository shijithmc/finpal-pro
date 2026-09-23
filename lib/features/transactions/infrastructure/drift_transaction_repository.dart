import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/i_transaction_repository.dart';
import '../domain/transaction.dart';
import '../domain/transaction_search_filter.dart';

final class DriftTransactionRepository implements ITransactionRepository {
  final AppDatabase _db;

  const DriftTransactionRepository(this._db);

  @override
  Stream<List<FinTransaction>> watchByDateRange(DateTime from, DateTime to) {
    return (_db.select(_db.transactions)
          ..where(
            (t) =>
                t.transactionDate.isBiggerOrEqualValue(
                  from.toIso8601String().substring(0, 10),
                ) &
                t.transactionDate.isSmallerOrEqualValue(
                  to.toIso8601String().substring(0, 10),
                ),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)]))
        .watch()
        .map((rows) => rows.map(FinTransaction.fromData).toList());
  }

  @override
  Future<List<FinTransaction>> searchByText(String query) async {
    if (query.trim().isEmpty) return [];
    return watchSearch(TransactionSearchFilter(query: query)).first;
  }

  @override
  Stream<List<FinTransaction>> watchSearch(TransactionSearchFilter filter) {
    final clauses = <String>[];
    final variables = <Variable>[];
    var join = '';
    if (filter.query.trim().isNotEmpty) {
      // Treat every word as a literal prefix, not as FTS query syntax. Terms
      // may match either description or notes, in any order.
      final terms = RegExp(r'[\p{L}\p{N}]+', unicode: true)
          .allMatches(filter.query)
          .map((match) => '"${match.group(0)}"*')
          .toList();
      if (terms.isEmpty) return Stream.value([]);
      join = 'INNER JOIN transactions_fts ON t.rowid = transactions_fts.rowid';
      clauses.add('transactions_fts MATCH ?');
      variables.add(Variable.withString(terms.join(' AND ')));
    }
    if (filter.from != null) {
      clauses.add('t.transaction_date >= ?');
      variables.add(Variable.withString(_date(filter.from!)));
    }
    if (filter.to != null) {
      clauses.add('t.transaction_date <= ?');
      variables.add(Variable.withString(_date(filter.to!)));
    }
    if (filter.accountIds.isNotEmpty) {
      final placeholders = List.filled(filter.accountIds.length, '?').join(',');
      clauses.add(
        '(t.debit_account_id IN ($placeholders) OR t.credit_account_id IN ($placeholders))',
      );
      variables.addAll([
        ...filter.accountIds.map(Variable.withString),
        ...filter.accountIds.map(Variable.withString),
      ]);
    }
    if (filter.categoryIds.isNotEmpty) {
      final placeholders = List.filled(
        filter.categoryIds.length,
        '?',
      ).join(',');
      clauses.add('t.category_id IN ($placeholders)');
      variables.addAll(filter.categoryIds.map(Variable.withString));
    }
    if (filter.type != null) {
      clauses.add('t.type = ?');
      variables.add(Variable.withString(filter.type!.name));
    }
    if (filter.minAmount != null) {
      clauses.add('t.amount >= ?');
      variables.add(Variable.withInt(filter.minAmount!));
    }
    if (filter.maxAmount != null) {
      clauses.add('t.amount <= ?');
      variables.add(Variable.withInt(filter.maxAmount!));
    }
    final where = clauses.isEmpty ? '' : 'WHERE ${clauses.join(' AND ')}';
    return _db
        .customSelect(
          'SELECT t.* FROM transactions t $join $where '
          'ORDER BY t.transaction_date DESC, t.created_at DESC, t.id',
          variables: variables,
          readsFrom: {_db.transactions},
        )
        .map((row) => FinTransaction.fromData(_db.transactions.map(row.data)))
        .watch();
  }

  static String _date(DateTime date) => date.toIso8601String().substring(0, 10);

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
    final row = await (_db.select(
      _db.transactions,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
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
  Future<void> update(String id, TransactionsCompanion companion) =>
      _db.updateTransaction(id, companion);

  @override
  Future<void> delete(String id) => _db.deleteTransaction(id);

  @override
  Future<void> toggleBookmark(String id, bool bookmarked) async {
    await (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(isBookmarked: Value(bookmarked)),
    );
  }
}
