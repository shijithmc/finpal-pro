import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/budget.dart';
import '../domain/i_budget_repository.dart';

final class DriftBudgetRepository implements IBudgetRepository {
  final AppDatabase _db;

  const DriftBudgetRepository(this._db);

  @override
  Stream<List<Budget>> watchForMonth(int year, int month) {
    return (_db.select(_db.budgets)
          ..where((b) => b.year.equals(year) & b.month.equals(month)))
        .watch()
        .map((rows) => rows.map(Budget.fromData).toList());
  }

  @override
  Future<Budget?> findById(String id) async {
    final row = await (_db.select(
      _db.budgets,
    )..where((b) => b.id.equals(id))).getSingleOrNull();
    return row == null ? null : Budget.fromData(row);
  }

  @override
  Future<void> create(BudgetsCompanion companion) =>
      _db.into(_db.budgets).insert(companion);

  @override
  Future<void> update(String id, int limitPaise) async {
    await (_db.update(_db.budgets)..where((b) => b.id.equals(id))).write(
      BudgetsCompanion(limitPaise: Value(limitPaise)),
    );
  }

  @override
  Future<void> delete(String id) async {
    await (_db.delete(_db.budgets)..where((b) => b.id.equals(id))).go();
  }
}
