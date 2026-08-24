import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../database/drift/database.dart';

abstract interface class ProductRepository {
  /// Fast sub-15ms local barcode lookup
  Future<Result<ProductData?, Failure>> getProductByBarcode(String barcode);

  /// Live stream of active products for POS catalog
  Stream<List<ProductData>> watchProducts();

  /// Create product locally and queue for cloud sync
  Future<Result<void, Failure>> createProduct({
    required String name,
    required int mrpPaise,
    required int sellingPricePaise,
    required String barcode,
    String? categoryId,
    String? unitId,
    double initialStock = 0.0,
    double taxRate = 0.0,
  });

  /// Synchronize remote product catalog into local database
  Future<Result<int, Failure>> syncRemoteProducts();
}
