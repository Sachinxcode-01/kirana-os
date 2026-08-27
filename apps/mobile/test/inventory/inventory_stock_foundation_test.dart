import 'package:flutter_test/flutter_test.dart';

import 'package:kirana_mobile/features/inventory/domain/models/adjustment_reason.dart';
import 'package:kirana_mobile/features/inventory/domain/models/inventory_movement_model.dart';
import 'package:kirana_mobile/features/inventory/domain/models/stock_adjustment_request.dart';
import 'package:kirana_mobile/features/products/domain/models/product_model.dart';

void main() {
  group('Phase 13.5 — Inventory Stock Foundation Logic & Models', () {
    final now = DateTime.now();

    final pieceProduct = ProductModel(
      id: 'prod_oil_1',
      shopId: 'shop_A',
      name: 'Sunflower Oil 1L',
      sellingPricePaise: 16000,
      mrpPaise: 18000,
      unit: 'PCS',
      isLoose: false,
      currentStock: 24.0,
      minStockAlert: 5.0,
      createdAt: now,
      updatedAt: now,
    );

    final looseProduct = ProductModel(
      id: 'prod_sugar_2',
      shopId: 'shop_A',
      name: 'Loose Sugar 1kg',
      sellingPricePaise: 4200,
      mrpPaise: 4800,
      unit: 'KG',
      isLoose: true,
      currentStock: 12.500, // 12.5 kg decimal quantity
      minStockAlert: 3.000,
      createdAt: now,
      updatedAt: now,
    );

    test(
        '1. Feature: Stock Quantity Strategy supports decimal and integer quantities',
        () {
      expect(pieceProduct.currentStock, equals(24.0));
      expect(looseProduct.currentStock, equals(12.5));
      expect(looseProduct.isLoose, isTrue);
    });

    test(
        '2. Feature: Stock Adjustment Modes (Add, Remove, Set Stock calculations)',
        () {
      // 1. Add Stock (+10)
      final addReq = StockAdjustmentRequest(
        productId: pieceProduct.id,
        shopId: 'shop_A',
        adjustmentType: InventoryAdjustmentType.stockIn,
        quantity: 10.0,
        reason: AdjustmentReason.openingStock.label,
        userId: 'user_1',
      );
      expect(addReq.calculateDelta(pieceProduct.currentStock), equals(10.0));
      expect(addReq.calculateNewStock(pieceProduct.currentStock), equals(34.0));

      // 2. Remove Stock (-5)
      final removeReq = StockAdjustmentRequest(
        productId: pieceProduct.id,
        shopId: 'shop_A',
        adjustmentType: InventoryAdjustmentType.stockOut,
        quantity: 5.0,
        reason: AdjustmentReason.damaged.label,
        userId: 'user_1',
      );
      expect(removeReq.calculateDelta(pieceProduct.currentStock), equals(-5.0));
      expect(
          removeReq.calculateNewStock(pieceProduct.currentStock), equals(19.0));

      // 3. Set Stock (= 50)
      final setReq = StockAdjustmentRequest(
        productId: pieceProduct.id,
        shopId: 'shop_A',
        adjustmentType: InventoryAdjustmentType.adjustment,
        quantity: 50.0, // Set to 50
        reason: AdjustmentReason.physicalCountCorrection.label,
        userId: 'user_1',
      );
      expect(setReq.calculateDelta(pieceProduct.currentStock),
          equals(26.0)); // 50 - 24 = 26
      expect(setReq.calculateNewStock(pieceProduct.currentStock), equals(50.0));
    });

    test(
        '3. Feature: Stock Status Indicator Boundaries (IN STOCK, LOW STOCK, OUT OF STOCK)',
        () {
      // 1. In Stock (24 > 5)
      expect(pieceProduct.currentStock > pieceProduct.minStockAlert, isTrue);

      // 2. Low Stock (4 <= 5)
      final lowStockProd = pieceProduct.copyWith(currentStock: 4.0);
      final isLow = lowStockProd.currentStock > 0 &&
          lowStockProd.currentStock <= lowStockProd.minStockAlert;
      expect(isLow, isTrue);

      // 3. Out of Stock (0 <= 0)
      final outOfStockProd = pieceProduct.copyWith(currentStock: 0.0);
      final isOut = outOfStockProd.currentStock <= 0;
      expect(isOut, isTrue);
    });

    test('4. Feature: Mandatory Adjustment Reasons parsing', () {
      final r1 = AdjustmentReason.fromString('Physical Count Correction');
      final r2 = AdjustmentReason.fromString('Damaged');
      final r3 = AdjustmentReason.fromString('Expired');
      final r4 = AdjustmentReason.fromString('Opening Stock');
      final r5 = AdjustmentReason.fromString('Unknown reason fallback');

      expect(r1, equals(AdjustmentReason.physicalCountCorrection));
      expect(r2, equals(AdjustmentReason.damaged));
      expect(r3, equals(AdjustmentReason.expired));
      expect(r4, equals(AdjustmentReason.openingStock));
      expect(r5, equals(AdjustmentReason.other));
    });

    test(
        '5. Feature: Immutable Inventory Movement Record parsing and audit properties',
        () {
      final json = {
        'id': 'mov_101',
        'shop_id': 'shop_A',
        'product_id': 'prod_oil_1',
        'previous_quantity': 24.0,
        'quantity_delta': 10.0,
        'balance_after': 34.0,
        'reason': 'purchase_inward',
        'adjustment_reason': 'Opening Stock',
        'performed_by': 'user_mgr_1',
        'created_at': now.toIso8601String(),
      };

      final movement = InventoryMovementModel.fromJson(json);
      expect(movement.id, equals('mov_101'));
      expect(movement.previousQuantity, equals(24.0));
      expect(movement.quantityDelta, equals(10.0));
      expect(movement.balanceAfter, equals(34.0));
      expect(movement.isPositive, isTrue);
      expect(movement.displayReason, equals('Opening Stock'));
    });
  });
}
