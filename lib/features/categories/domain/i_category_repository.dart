import '../../../core/database/app_database.dart';
import 'category.dart';

abstract interface class ICategoryRepository {
  Stream<List<Category>> watchAll();
  Future<List<Category>> findByType(CategoryType type);
  Future<Category?> findById(String id);
}
