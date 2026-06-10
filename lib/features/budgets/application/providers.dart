import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../accounts/application/providers.dart' show appDatabaseProvider;
import '../../categories/application/providers.dart'
    show categoryRepositoryProvider;
import '../domain/budget.dart';
import '../domain/i_budget_repository.dart';
import '../infrastructure/drift_budget_repository.dart';

final budgetRepositoryProvider = Provider<IBudgetRepository>((ref) {
  return DriftBudgetRepository(ref.read(appDatabaseProvider));
});

/// Stream of budgets + spend for the selected month.
final budgetsWithSpendProvider =
    StreamProvider.family<List<BudgetWithSpend>, DateTime>((ref, month) async* {
      final repo = ref.watch(budgetRepositoryProvider);
      final db = ref.watch(appDatabaseProvider);
      final categoriesAsync = ref.watch(budgetCategoriesProvider);
      final categories = categoriesAsync.valueOrNull ?? [];
      final catMap = {for (final c in categories) c.id: c.name};

      await for (final budgets in repo.watchForMonth(month.year, month.month)) {
        final spendMap = await db.getCategoryExpensesForMonth(
          month.year,
          month.month,
        );
        yield budgets
            .map(
              (b) => BudgetWithSpend(
                budget: b,
                spentPaise: spendMap[b.categoryId] ?? 0,
                categoryName: catMap[b.categoryId] ?? b.categoryId,
              ),
            )
            .toList()
          ..sort((a, b) => b.progress.compareTo(a.progress));
      }
    });

/// Creates a budget entry for a category/month.
Future<void> createBudget({
  required IBudgetRepository repo,
  required String categoryId,
  required int year,
  required int month,
  required int limitPaise,
}) {
  return repo.create(
    BudgetsCompanion.insert(
      id: const Uuid().v4(),
      categoryId: categoryId,
      year: year,
      month: month,
      limitPaise: limitPaise,
    ),
  );
}

/// Stream of all expense categories for the budget editor.
final budgetCategoriesProvider = StreamProvider((ref) {
  return ref.watch(categoryRepositoryProvider).watchAll();
});
