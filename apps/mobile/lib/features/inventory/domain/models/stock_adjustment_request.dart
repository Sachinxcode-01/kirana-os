import 'inventory_movement_model.dart';

class StockAdjustmentRequest {
  final String productId;
  final String shopId;
  final InventoryAdjustmentType adjustmentType;
  final double quantity;
  final String reason;
  final String? note;
  final String userId;

  const StockAdjustmentRequest({
    required this.productId,
    required this.shopId,
    required this.adjustmentType,
    required this.quantity,
    required this.reason,
    this.note,
    required this.userId,
  });

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
}
