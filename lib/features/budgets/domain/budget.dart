import 'package:equatable/equatable.dart';

import '../../../core/database/app_database.dart';

/// Monthly spend budget for a category.
final class Budget extends Equatable {
  final String id;
  final String categoryId;
  final int year;
  final int month;

  /// Budget limit in paise (smallest currency unit).
  final int limitPaise;

  const Budget({
    required this.id,
    required this.categoryId,
    required this.year,
    required this.month,
    required this.limitPaise,
  });

  factory Budget.fromData(BudgetData data) => Budget(
    id: data.id,
    categoryId: data.categoryId,
    year: data.year,
    month: data.month,
    limitPaise: data.limitPaise,
  );

  double get limitMajorUnits => limitPaise / 100.0;

  @override
  List<Object?> get props => [id, categoryId, year, month, limitPaise];
}

/// Budget with real-time spend data for the dashboard.
final class BudgetWithSpend extends Equatable {
  final Budget budget;

  /// Actual spend in paise for this category/month.
  final int spentPaise;

  /// Category name (resolved from categories table).
  final String categoryName;

  const BudgetWithSpend({
    required this.budget,
    required this.spentPaise,
    required this.categoryName,
  });

  double get spentMajorUnits => spentPaise / 100.0;
  double get limitMajorUnits => budget.limitMajorUnits;

  /// 0.0–1.0 spend ratio. Capped at 1.0 for progress indicators.
  double get progress =>
      budget.limitPaise == 0 ? 0 : (spentPaise / budget.limitPaise).clamp(0, 1);

  bool get isOverBudget => spentPaise > budget.limitPaise;
  bool get isNearLimit => !isOverBudget && progress >= 0.8;

  @override
  List<Object?> get props => [budget, spentPaise, categoryName];
}
