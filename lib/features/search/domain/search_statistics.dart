import '../../../core/database/app_database.dart';
import '../../transactions/domain/transaction.dart';

/// Derived from exactly the displayed search results, never monthly aggregates.
final class SearchStatistics {
  final int income;
  final int expense;
  final int transfers;
  final Map<String?, int> expensesByCategory;

  const SearchStatistics({
    required this.income,
    required this.expense,
    required this.transfers,
    required this.expensesByCategory,
  });

  int get net => income - expense;

  factory SearchStatistics.fromTransactions(List<FinTransaction> transactions) {
    var income = 0;
    var expense = 0;
    var transfers = 0;
    final categories = <String?, int>{};
    for (final tx in transactions) {
      final amount = tx.amount.subunits;
      switch (tx.type) {
        case TransactionType.income:
          income += amount;
        case TransactionType.expense:
          expense += amount;
          categories.update(
            tx.categoryId,
            (sum) => sum + amount,
            ifAbsent: () => amount,
          );
        case TransactionType.transfer:
          transfers += amount;
      }
    }
    return SearchStatistics(
      income: income,
      expense: expense,
      transfers: transfers,
      expensesByCategory: Map.unmodifiable(categories),
    );
  }
}
