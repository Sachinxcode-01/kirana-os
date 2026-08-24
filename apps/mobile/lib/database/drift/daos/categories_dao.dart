import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/categories_table.dart';

part 'categories_dao.g.dart';

@DriftAccessor(tables: [CategoriesTable])
class CategoriesDao extends DatabaseAccessor<AppDatabase>
    with _$CategoriesDaoMixin {
  CategoriesDao(super.db);

  /// Watch all categories for a shop ordered by sort order and name
  Stream<List<CategoryData>> watchCategories(String shopId) {
    return (select(categoriesTable)
          ..where((t) => t.shopId.equals(shopId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm.asc(t.name)
          ]))
        .watch();
  }

  /// Get all categories
  Future<List<CategoryData>> getCategories(String shopId) {
    return (select(categoriesTable)
          ..where((t) => t.shopId.equals(shopId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  /// Upsert category
  Future<void> upsertCategory(CategoriesTableCompanion category) async {
    await into(categoriesTable).insertOnConflictUpdate(category);
  }
}
