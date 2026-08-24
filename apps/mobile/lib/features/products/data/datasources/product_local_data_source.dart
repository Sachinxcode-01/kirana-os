import '../../../../database/drift/database.dart';
import '../../domain/models/product_model.dart';

class ProductLocalDataSource {
  final AppDatabase _db;

  ProductLocalDataSource(this._db);

  Future<ProductData?> getProductByBarcode(String shopId, String barcode) {
    return _db.productsDao.getProductByBarcode(shopId, barcode);
  }

  Future<ProductModel?> getProductById(String id) async {
    final row = await _db.productsDao.getProductById(id);
    if (row == null) return null;
    final cat = row.categoryId != null
        ? await _db.categoriesDao.getCategoryById(row.categoryId!)
        : null;
    return _mapToModel(row, cat?.name);
  }

  Future<ProductModel?> getProductByName(String shopId, String name) async {
    final row = await _db.productsDao.getProductByName(shopId, name);
    if (row == null) return null;
    final cat = row.categoryId != null
        ? await _db.categoriesDao.getCategoryById(row.categoryId!)
        : null;
    return _mapToModel(row, cat?.name);
  }

  Stream<List<ProductModel>> watchProducts(
    String shopId, {
    String? categoryId,
    String? searchQuery,
  }) {
    return _db.productsDao
        .watchProducts(
      shopId,
      categoryId: categoryId,
      searchQuery: searchQuery,
    )
        .asyncMap((rows) async {
      final models = <ProductModel>[];
      for (final row in rows) {
        final cat = row.categoryId != null
            ? await _db.categoriesDao.getCategoryById(row.categoryId!)
            : null;
        models.add(_mapToModel(row, cat?.name));
      }
      return models;
    });
  }

  Future<List<ProductModel>> getProducts(
    String shopId, {
    String? categoryId,
    String? searchQuery,
  }) async {
    final rows = await _db.productsDao.getProducts(
      shopId,
      categoryId: categoryId,
      searchQuery: searchQuery,
    );
    final models = <ProductModel>[];
    for (final row in rows) {
      final cat = row.categoryId != null
          ? await _db.categoriesDao.getCategoryById(row.categoryId!)
          : null;
      models.add(_mapToModel(row, cat?.name));
    }
    return models;
  }

  Future<void> upsertProduct(ProductsTableCompanion product) {
    return _db.productsDao.upsertProduct(product);
  }

  Future<void> softDeleteProduct(String id) {
    return _db.productsDao.softDeleteProduct(id);
  }

  Future<void> linkBarcode(ProductBarcodesTableCompanion barcode) {
    return _db.productsDao.linkBarcode(barcode);
  }

  Future<void> enqueueSyncOperation(SyncQueueTableCompanion syncOp) {
    return _db.syncDao.enqueueOperation(syncOp);
  }

  ProductModel _mapToModel(ProductData row, String? categoryName) {
    return ProductModel(
      id: row.id,
      shopId: row.shopId,
      name: row.name,
      categoryId: row.categoryId,
      categoryName: categoryName,
      brand: row.brand,
      unit: row.unit,
      sellingPricePaise: row.sellingPricePaise.toInt(),
      purchasePricePaise: row.purchasePricePaise.toInt(),
      mrpPaise: row.mrpPaise.toInt(),
      currentStock: row.currentStock,
      minStockAlert: row.minStockAlert,
      description: row.description,
      regionalName: row.regionalName,
      hsnCode: row.hsnCode,
      taxRatePercentage: row.taxRatePercentage,
      isTaxInclusive: row.isTaxInclusive,
      isLoose: row.isLoose,
      isActive: row.isActive,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
