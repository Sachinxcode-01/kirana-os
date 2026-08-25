import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../products/domain/models/product_model.dart';
import '../models/inventory_movement_model.dart';
import '../models/stock_adjustment_request.dart';

abstract class InventoryRepository {
  Future<Result<ProductModel, Failure>> getStockDetails(
      String shopId, String productId);

  Future<Result<InventoryMovementModel, Failure>> adjustStock(
      StockAdjustmentRequest request);

  Future<Result<List<InventoryMovementModel>, Failure>> getInventoryHistory({
    required String shopId,
    String? productId,
    int limit = 20,
    int offset = 0,
  });

  Future<Result<List<ProductModel>, Failure>> getLowStockProducts(
      String shopId);
}
