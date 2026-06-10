import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../accounts/application/providers.dart' show appDatabaseProvider;
import '../../categories/application/providers.dart'
    show categoryRepositoryProvider;

/// Category expense breakdown for a given month: categoryId → paise.
final categoryBreakdownProvider =
    FutureProvider.family<Map<String, int>, DateTime>((ref, month) async {
      final db = ref.watch(appDatabaseProvider);
      return db.getCategoryBreakdown(month.year, month.month);
    });

/// Category names for resolving IDs → labels in charts.
/// Re-uses the same stream as budget categories.
final analyticsCategoryNamesProvider = StreamProvider<Map<String, String>>((
  ref,
) async* {
  await for (final cats in ref.watch(categoryRepositoryProvider).watchAll()) {
    yield {for (final c in cats) c.id: c.name};
  }
});

/// Global monthly income/expense trend for last [n] months (newest-first).
final monthlyTrendProvider = FutureProvider.family<List<MonthlyTotals>, int>((
  ref,
  months,
) async {
  final db = ref.watch(appDatabaseProvider);
  return db.getGlobalMonthlyTrend(months);
});
