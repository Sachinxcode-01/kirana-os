import 'inventory_movement_model.dart';
import 'adjustment_reason.dart';

class StockAdjustmentRequest {
  final String productId;
  final String shopId;
  final InventoryAdjustmentType adjustmentType;
  final double quantity;
  final String reason;
  final String? note;
  final String userId;
  final String? idempotencyKey;

  const StockAdjustmentRequest({
    required this.productId,
    required this.shopId,
    required this.adjustmentType,
    required this.quantity,
    required this.reason,
    this.note,
    required this.userId,
    this.idempotencyKey,
  });

  AdjustmentReason get parsedReason => AdjustmentReason.fromString(reason);

  double calculateDelta(double currentStock) {
    switch (adjustmentType) {
      case InventoryAdjustmentType.stockIn:
        return quantity.abs();
      case InventoryAdjustmentType.stockOut:
        return -quantity.abs();
      case InventoryAdjustmentType.adjustment:
        return quantity - currentStock;
    }
  }

  double calculateNewStock(double currentStock) {
    return currentStock + calculateDelta(currentStock);
  }

  bool isDecrease() => adjustmentType == InventoryAdjustmentType.stockOut;
}
