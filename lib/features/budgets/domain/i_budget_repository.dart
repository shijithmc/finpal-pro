import '../../../core/database/app_database.dart';
import 'budget.dart';

abstract interface class IBudgetRepository {
  Stream<List<Budget>> watchForMonth(int year, int month);

  Future<Budget?> findById(String id);

  Future<void> create(BudgetsCompanion companion);

  Future<void> update(String id, int limitPaise);

  Future<void> delete(String id);
}
