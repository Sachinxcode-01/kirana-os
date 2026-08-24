import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/categories_table.dart';
import '../tables/products_table.dart';

part 'categories_dao.g.dart';

@DriftAccessor(tables: [CategoriesTable, ProductsTable])
class CategoriesDao extends DatabaseAccessor<AppDatabase>
    with _$CategoriesDaoMixin {
  CategoriesDao(super.db);

  /// Watch all categories for a shop
  Stream<List<CategoryData>> watchCategories(
    String shopId, {
    bool activeOnly = true,
  }) {
    final query = select(categoriesTable)
      ..where((t) =>
          t.shopId.equals(shopId) &
          (activeOnly ? t.isActive.equals(true) : const Constant(true)))
      ..orderBy([
        (t) => OrderingTerm.asc(t.sortOrder),
        (t) => OrderingTerm.asc(t.name),
      ]);
    return query.watch();
  }

  /// Get all categories
  Future<List<CategoryData>> getCategories(
    String shopId, {
    bool activeOnly = true,
  }) {
    final query = select(categoriesTable)
      ..where((t) =>
          t.shopId.equals(shopId) &
          (activeOnly ? t.isActive.equals(true) : const Constant(true)))
      ..orderBy([
        (t) => OrderingTerm.asc(t.sortOrder),
        (t) => OrderingTerm.asc(t.name),
      ]);
    return query.get();
  }

  /// Search categories by query string (case-insensitive)
  Future<List<CategoryData>> searchCategories(
    String shopId,
    String query, {
    bool activeOnly = true,
  }) {
    final term = '%${query.trim().toLowerCase()}%';
    final q = select(categoriesTable)
      ..where((t) =>
          t.shopId.equals(shopId) &
          (activeOnly ? t.isActive.equals(true) : const Constant(true)) &
          (t.name.lower().like(term) | t.description.lower().like(term)))
      ..orderBy([
        (t) => OrderingTerm.asc(t.sortOrder),
        (t) => OrderingTerm.asc(t.name),
      ]);
    return q.get();
  }

  /// Get single category by ID
  Future<CategoryData?> getCategoryById(String id) {
    return (select(categoriesTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Get category by exact name in shop (case-insensitive for duplicate checks)
  Future<CategoryData?> getCategoryByName(String shopId, String name) {
    return (select(categoriesTable)
          ..where((t) =>
              t.shopId.equals(shopId) &
              t.name.lower().equals(name.trim().toLowerCase()) &
              t.isActive.equals(true)))
        .getSingleOrNull();
  }

  /// Upsert category record
  Future<void> upsertCategory(CategoriesTableCompanion category) async {
    await into(categoriesTable).insertOnConflictUpdate(category);
  }

  /// Soft delete / archive category
  Future<void> softDeleteCategory(String id) async {
    await (update(categoriesTable)..where((t) => t.id.equals(id))).write(
      CategoriesTableCompanion(
        isActive: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Count products associated with category
  Future<int> countActiveProductsInCategory(String categoryId) async {
    final countExp = productsTable.id.count();
    final query = selectOnly(productsTable)
      ..addColumns([countExp])
      ..where(productsTable.categoryId.equals(categoryId) &
          productsTable.isActive.equals(true));

    final result = await query.getSingle();
    return result.read(countExp) ?? 0;
  }
}
