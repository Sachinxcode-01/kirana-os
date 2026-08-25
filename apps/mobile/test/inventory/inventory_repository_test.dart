import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_mobile/features/inventory/domain/models/inventory_movement_model.dart';
import 'package:kirana_mobile/features/inventory/domain/models/stock_adjustment_request.dart';
import 'package:kirana_mobile/features/inventory/domain/models/stock_status.dart';
import 'package:kirana_mobile/features/products/domain/models/product_model.dart';

void main() {
  group('Inventory Domain & Stock Status Rules', () {
    test('StockStatus.fromQuantities returns correct status badge', () {
      expect(StockStatus.fromQuantities(10.0, 5.0), StockStatus.inStock);
      expect(StockStatus.fromQuantities(5.0, 5.0), StockStatus.lowStock);
      expect(StockStatus.fromQuantities(2.0, 5.0), StockStatus.lowStock);
      expect(StockStatus.fromQuantities(0.0, 5.0), StockStatus.outOfStock);
      expect(StockStatus.fromQuantities(-1.0, 5.0), StockStatus.outOfStock);
    });

    test('StockAdjustmentRequest calculates correct quantity delta', () {
      const stockIn = StockAdjustmentRequest(
        productId: 'prod_1',
        shopId: 'shop_1',
        adjustmentType: InventoryAdjustmentType.stockIn,
        quantity: 15.0,
        reason: 'Restock',
        userId: 'user_1',
      );
      expect(stockIn.calculateDelta(20.0), 15.0);

      const stockOut = StockAdjustmentRequest(
        productId: 'prod_1',
        shopId: 'shop_1',
        adjustmentType: InventoryAdjustmentType.stockOut,
        quantity: 5.0,
        reason: 'Damaged',
        userId: 'user_1',
      );
      expect(stockOut.calculateDelta(20.0), -5.0);

      const adjustment = StockAdjustmentRequest(
        productId: 'prod_1',
        shopId: 'shop_1',
        adjustmentType: InventoryAdjustmentType.adjustment,
        quantity: 35.0,
        reason: 'Audit',
        userId: 'user_1',
      );
      expect(adjustment.calculateDelta(20.0), 15.0);
    });

    test('InventoryMovementModel serialization and deserialization', () {
      final now = DateTime.now();
      final model = InventoryMovementModel(
        id: 'mov_1',
        shopId: 'shop_1',
        productId: 'prod_1',
        productName: 'Rice 5kg',
        quantityDelta: 10.0,
        balanceAfter: 35.0,
        reason: 'purchase_inward',
        performedBy: 'user_owner',
        note: 'Invoice #102',
        createdAt: now,
      );

      expect(model.isPositive, isTrue);
      expect(model.type, InventoryAdjustmentType.stockIn);

      final json = model.toJson();
      final deserialized = InventoryMovementModel.fromJson(json);

      expect(deserialized.id, 'mov_1');
      expect(deserialized.quantityDelta, 10.0);
      expect(deserialized.balanceAfter, 35.0);
      expect(deserialized.performedBy, 'user_owner');
    });

    test('ProductModel stock helper fields initialize correctly', () {
      final product = ProductModel(
        id: 'p1',
        shopId: 's1',
        name: 'Sugar 1kg',
        sellingPricePaise: 4500,
        mrpPaise: 5000,
        currentStock: 12.0,
        minStockAlert: 5.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final status = StockStatus.fromQuantities(
        product.currentStock,
        product.minStockAlert,
      );
      expect(status, StockStatus.inStock);
    });
  });
}
