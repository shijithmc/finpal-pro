import 'package:drift/drift.dart' show OrderingTerm;

import '../../../core/database/app_database.dart';
import '../domain/category.dart';
import '../domain/i_category_repository.dart';

final class DriftCategoryRepository implements ICategoryRepository {
  final AppDatabase _db;

  const DriftCategoryRepository(this._db);

  @override
  Stream<List<Category>> watchAll() {
    return (_db.select(_db.categories)
          ..orderBy([
            (c) => OrderingTerm(expression: c.sortOrder),
          ]))
        .watch()
        .map((rows) => rows.map(Category.fromData).toList());
  }

  @override
  Future<List<Category>> findByType(CategoryType type) async {
    final rows = await (_db.select(_db.categories)
          ..where((c) => c.type.isInValues([type, CategoryType.both]))
          ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
        .get();
    return rows.map(Category.fromData).toList();
  }

  @override
  Future<Category?> findById(String id) async {
    final row = await (_db.select(_db.categories)
          ..where((c) => c.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : Category.fromData(row);
  }
}
