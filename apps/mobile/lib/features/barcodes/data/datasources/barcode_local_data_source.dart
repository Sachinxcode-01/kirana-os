import 'package:drift/drift.dart';
import 'package:kirana_mobile/database/drift/database.dart';
import '../../domain/models/barcode_model.dart';
import 'package:kirana_mobile/features/products/domain/models/product_model.dart';

class BarcodeLocalDataSource {
  final AppDatabase _db;

  BarcodeLocalDataSource(this._db);

  Future<List<BarcodeModel>> getBarcodesForProduct(String productId) async {
    final rows = await _db.productsDao.getBarcodesForProduct(productId);
    return rows.map(_mapToModel).toList();
  }

  Stream<List<BarcodeModel>> watchBarcodesForProduct(String productId) {
    return _db.productsDao
        .watchBarcodesForProduct(productId)
        .map((rows) => rows.map(_mapToModel).toList());
  }

  Future<BarcodeModel?> getBarcodeByValue(String shopId, String barcode) async {
    final row = await _db.productsDao.getBarcodeByValue(shopId, barcode);
    if (row == null) return null;
    return _mapToModel(row);
  }

  Future<BarcodeModel?> getBarcodeById(String id) async {
    final row = await _db.productsDao.getBarcodeById(id);
    if (row == null) return null;
    return _mapToModel(row);
  }

  Future<ProductModel?> getProductByBarcode(
      String shopId, String barcode) async {
    final row = await _db.productsDao.getProductByBarcode(shopId, barcode);
    if (row == null) return null;
    final cat = row.categoryId != null
        ? await _db.categoriesDao.getCategoryById(row.categoryId!)
        : null;

    return ProductModel(
      id: row.id,
      shopId: row.shopId,
      name: row.name,
      categoryId: row.categoryId,
      categoryName: cat?.name,
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

  Future<void> saveBarcode(BarcodeModel barcode) async {
    await _db.productsDao.linkBarcode(
      ProductBarcodesTableCompanion(
        id: Value(barcode.id),
        shopId: Value(barcode.shopId),
        productId: Value(barcode.productId),
        barcode: Value(barcode.barcode),
        barcodeType: Value(barcode.barcodeType),
        isPrimary: Value(barcode.isPrimary),
        createdAt: Value(barcode.createdAt),
        updatedAt: Value(barcode.updatedAt),
      ),
    );
  }

  Future<void> deleteBarcode(String id) async {
    await _db.productsDao.deleteBarcode(id);
  }

  Future<void> enqueueSyncOperation(SyncQueueTableCompanion syncOp) async {
    await _db.syncDao.enqueueOperation(syncOp);
  }

  BarcodeModel _mapToModel(ProductBarcodeData row) {
    return BarcodeModel(
      id: row.id,
      shopId: row.shopId,
      productId: row.productId,
      barcode: row.barcode,
      barcodeType: row.barcodeType,
      isPrimary: row.isPrimary,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
