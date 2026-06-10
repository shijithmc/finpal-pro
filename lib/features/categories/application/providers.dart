import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../domain/category.dart';
import '../domain/i_category_repository.dart';
import '../infrastructure/drift_category_repository.dart';
import '../../accounts/application/providers.dart';

final categoryRepositoryProvider = Provider<ICategoryRepository>((ref) {
  return DriftCategoryRepository(ref.read(appDatabaseProvider));
});

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(categoryRepositoryProvider).watchAll();
});

final categoriesTreeProvider = StreamProvider<List<Category>>((ref) {
  return ref
      .watch(categoryRepositoryProvider)
      .watchAll()
      .map(buildCategoryTree);
});

final expenseCategoriesProvider = FutureProvider<List<Category>>((ref) {
  return ref.read(categoryRepositoryProvider).findByType(CategoryType.expense);
});

final incomeCategoriesProvider = FutureProvider<List<Category>>((ref) {
  return ref.read(categoryRepositoryProvider).findByType(CategoryType.income);
});
