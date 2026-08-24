import 'package:kirana_mobile/core/errors/failure.dart';
import 'package:kirana_mobile/core/errors/result.dart';
import 'package:kirana_mobile/features/products/domain/models/product_model.dart';
import '../models/barcode_model.dart';

abstract interface class BarcodeRepository {
  /// Add barcode to product with validation and duplicate prevention
  Future<Result<BarcodeModel, Failure>> addBarcode({
    required String productId,
    required String barcode,
    String? barcodeType,
    bool isPrimary = false,
  });

  /// Edit existing barcode entry
  Future<Result<BarcodeModel, Failure>> updateBarcode({
    required String id,
    required String newBarcode,
    String? barcodeType,
    bool? isPrimary,
  });

  /// Remove barcode from product
  Future<Result<void, Failure>> removeBarcode(String id);

  /// Fetch all barcodes associated with product
  Future<Result<List<BarcodeModel>, Failure>> getBarcodesForProduct(
      String productId);

  /// Stream of barcodes associated with product
  Stream<List<BarcodeModel>> watchBarcodesForProduct(String productId);

  /// Sub-15ms fast indexed barcode search (Drift SQLite -> Supabase fallback -> local cache)
  Future<Result<ProductModel?, Failure>> searchProductByBarcode(String barcode);
}
