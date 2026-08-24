import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:kirana_mobile/database/drift/database.dart';
import '../../domain/models/category_model.dart';

class CategoryLocalDataSource {
  final AppDatabase _db;

  CategoryLocalDataSource(this._db);

  Stream<List<CategoryModel>> watchCategories(
    String shopId, {
    String? searchQuery,
  }) {
    return _db.categoriesDao.watchCategories(shopId).asyncMap((rows) async {
      final models = <CategoryModel>[];
      for (final row in rows) {
        if (searchQuery != null && searchQuery.trim().isNotEmpty) {
          final term = searchQuery.trim().toLowerCase();
          final matchesName = row.name.toLowerCase().contains(term);
          final matchesDesc =
              row.description?.toLowerCase().contains(term) ?? false;
          if (!matchesName && !matchesDesc) continue;
        }

        final productCount =
            await _db.categoriesDao.countActiveProductsInCategory(row.id);
        models.add(_mapToModel(row, productCount));
      }
      return models;
    });
  }

  Future<List<CategoryModel>> getCategories(String shopId) async {
    final rows = await _db.categoriesDao.getCategories(shopId);
    final models = <CategoryModel>[];
    for (final row in rows) {
      final productCount =
          await _db.categoriesDao.countActiveProductsInCategory(row.id);
      models.add(_mapToModel(row, productCount));
    }
    return models;
  }

  Future<List<CategoryModel>> searchCategories(
    String shopId,
    String query,
  ) async {
    final rows = await _db.categoriesDao.searchCategories(shopId, query);
    final models = <CategoryModel>[];
    for (final row in rows) {
      final productCount =
          await _db.categoriesDao.countActiveProductsInCategory(row.id);
      models.add(_mapToModel(row, productCount));
    }
    return models;
  }

  Future<CategoryModel?> getCategoryById(String id) async {
    final row = await _db.categoriesDao.getCategoryById(id);
    if (row == null) return null;
    final productCount =
        await _db.categoriesDao.countActiveProductsInCategory(row.id);
    return _mapToModel(row, productCount);
  }

  Future<CategoryModel?> getCategoryByName(String shopId, String name) async {
    final row = await _db.categoriesDao.getCategoryByName(shopId, name);
    if (row == null) return null;
    final productCount =
        await _db.categoriesDao.countActiveProductsInCategory(row.id);
    return _mapToModel(row, productCount);
  }

  Future<void> saveCategory(CategoryModel category) async {
    await _db.categoriesDao.upsertCategory(
      CategoriesTableCompanion(
        id: Value(category.id),
        shopId: Value(category.shopId),
        name: Value(category.name),
        description: Value(category.description),
        parentId: Value(category.parentId),
        iconUrl: Value(category.iconUrl),
        sortOrder: Value(category.sortOrder),
        isActive: Value(category.isActive),
        createdAt: Value(category.createdAt),
        updatedAt: Value(category.updatedAt),
      ),
    );
  }

  Future<void> saveCategories(List<CategoryModel> categories) async {
    await _db.batch((batch) {
      for (final cat in categories) {
        batch.insert(
          _db.categoriesTable,
          CategoriesTableCompanion(
            id: Value(cat.id),
            shopId: Value(cat.shopId),
            name: Value(cat.name),
            description: Value(cat.description),
            parentId: Value(cat.parentId),
            iconUrl: Value(cat.iconUrl),
            sortOrder: Value(cat.sortOrder),
            isActive: Value(cat.isActive),
            createdAt: Value(cat.createdAt),
            updatedAt: Value(cat.updatedAt),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> softDeleteCategory(String id) async {
    await _db.categoriesDao.softDeleteCategory(id);
  }

  Future<int> countActiveProductsInCategory(String categoryId) async {
    return _db.categoriesDao.countActiveProductsInCategory(categoryId);
  }

  Future<void> enqueueSyncOperation({
    required String operationId,
    required String shopId,
    required String entityId,
    required String operationType, // 'INSERT', 'UPDATE', 'DELETE'
    required Map<String, dynamic> payload,
  }) async {
    await _db.syncDao.enqueueOperation(
      SyncQueueTableCompanion(
        operationId: Value(operationId),
        shopId: Value(shopId),
        entityType: const Value('category'),
        entityId: Value(entityId),
        operationType: Value(operationType),
        payload: Value(jsonEncode(payload)),
        status: const Value('PENDING'),
        retryCount: const Value(0),
        createdAt: Value(DateTime.now()),
      ),
    );
  }

  CategoryModel _mapToModel(CategoryData row, int productCount) {
    return CategoryModel(
      id: row.id,
      shopId: row.shopId,
      name: row.name,
      description: row.description,
      parentId: row.parentId,
      iconUrl: row.iconUrl,
      sortOrder: row.sortOrder,
      isActive: row.isActive,
      productCount: productCount,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
