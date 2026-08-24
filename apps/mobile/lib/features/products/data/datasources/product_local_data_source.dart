import '../../../../database/drift/database.dart';

class ProductLocalDataSource {
  final AppDatabase _db;

  ProductLocalDataSource(this._db);

  Future<ProductData?> getProductByBarcode(String shopId, String barcode) {
    return _db.productsDao.getProductByBarcode(shopId, barcode);
  }

  Stream<List<ProductData>> watchProducts(String shopId) {
    return _db.productsDao.watchProducts(shopId);
  }

  Future<void> upsertProduct(ProductsTableCompanion product) {
    return _db.productsDao.upsertProduct(product);
  }

  Future<void> linkBarcode(ProductBarcodesTableCompanion barcode) {
    return _db.productsDao.linkBarcode(barcode);
  }

  Future<void> enqueueSyncOperation(SyncQueueTableCompanion syncOp) {
    return _db.syncDao.enqueueOperation(syncOp);
  }
}
