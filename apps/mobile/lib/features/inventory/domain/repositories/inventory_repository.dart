import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../products/domain/models/product_model.dart';
import '../models/inventory_movement_model.dart';
import '../models/stock_adjustment_request.dart';

import '../models/stock_status.dart';

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

  Future<Result<List<ProductModel>, Failure>> getFilteredProducts(
    String shopId, {
    String? categoryId,
    String? searchQuery,
    StockStatusFilter? statusFilter,
  });

  Future<Result<ProductModel, Failure>> updateStockSettings({
    required String productId,
    required double minStockAlert,
    double? maxStockAlert,
  });
}
