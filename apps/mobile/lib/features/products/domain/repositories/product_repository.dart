import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../database/drift/database.dart';
import '../models/product_model.dart';

abstract interface class ProductRepository {
  /// Fast sub-15ms local barcode lookup
  Future<Result<ProductData?, Failure>> getProductByBarcode(String barcode);

  /// Get product by ID
  Future<Result<ProductModel?, Failure>> getProductById(String id);

  /// Live stream of active products with optional category and search filters
  Stream<List<ProductModel>> watchProducts({
    String? categoryId,
    String? searchQuery,
  });

  /// Get products list with optional category and search filters
  Future<Result<List<ProductModel>, Failure>> getProducts({
    String? categoryId,
    String? searchQuery,
    bool refreshFromRemote = true,
  });

  /// Create product locally and queue for cloud sync
  Future<Result<ProductModel, Failure>> createProduct({
    required String name,
    required String categoryId,
    String? brand,
    String unit = 'PCS',
    required int sellingPricePaise,
    int purchasePricePaise = 0,
    int? mrpPaise,
    double minStockAlert = 5.0,
    double initialStock = 0.0,
    String? description,
    String? barcode,
    double taxRate = 0.0,
  });

  /// Update product details locally and queue for cloud sync
  Future<Result<ProductModel, Failure>> updateProduct({
    required String id,
    required String name,
    required String categoryId,
    String? brand,
    String unit = 'PCS',
    required int sellingPricePaise,
    int purchasePricePaise = 0,
    int? mrpPaise,
    double minStockAlert = 5.0,
    String? description,
  });

  /// Soft delete / archive product
  Future<Result<void, Failure>> archiveProduct(String id);

  /// Synchronize remote product catalog into local database
  Future<Result<int, Failure>> syncRemoteProducts();

  /// Upload product image (from camera/gallery file bytes)
  Future<Result<String, Failure>> uploadProductImage({
    required String productId,
    required List<int> imageBytes,
    required String fileName,
  });

  /// Remove product image reference and storage object
  Future<Result<void, Failure>> deleteProductImage({
    required String productId,
  });
}
