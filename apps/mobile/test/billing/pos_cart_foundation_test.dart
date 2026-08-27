import 'package:flutter_test/flutter_test.dart';

import 'package:kirana_mobile/features/billing/domain/models/bill_model.dart';
import 'package:kirana_mobile/features/billing/domain/usecases/billing_usecases.dart';
import 'package:kirana_mobile/features/products/domain/models/product_model.dart';

void main() {
  group('Phase 13.2 — POS Cart Foundation UseCases', () {
    late CalculateBillTotalsUseCase calculateTotalsUseCase;
    late AddProductToBillUseCase addProductUseCase;
    late UpdateBillItemQuantityUseCase updateQuantityUseCase;
    late RemoveBillItemUseCase removeItemUseCase;

    final now = DateTime.now();
    final initialBill = BillModel(
      id: 'bill_test_1',
      shopId: 'shop_A',
      cashierId: 'cashier_1',
      billNumber: 'BILL-001',
      createdAt: now,
      updatedAt: now,
    );

    final p1 = ProductModel(
      id: 'prod_1',
      shopId: 'shop_A',
      name: 'Fortune Sunlite Refined Oil 1L',
      sellingPricePaise: 14500, // ₹145.00
      mrpPaise: 16000,
      unit: 'LITRE',
      currentStock: 20,
      createdAt: now,
      updatedAt: now,
    );

    final p2 = ProductModel(
      id: 'prod_2',
      shopId: 'shop_A',
      name: 'Aashirvaad Shuddh Chakki Atta 5kg',
      sellingPricePaise: 24000, // ₹240.00
      mrpPaise: 26000,
      unit: 'KG',
      currentStock: 15,
      createdAt: now,
      updatedAt: now,
    );

    setUp(() {
      calculateTotalsUseCase = CalculateBillTotalsUseCase();
      addProductUseCase = AddProductToBillUseCase(calculateTotalsUseCase);
      updateQuantityUseCase =
          UpdateBillItemQuantityUseCase(calculateTotalsUseCase);
      removeItemUseCase = RemoveBillItemUseCase(calculateTotalsUseCase);
    });

    test(
        '1. Feature: Add Product to Cart creates item snapshot and computes subtotal',
        () {
      final billWithP1 = addProductUseCase.execute(
        bill: initialBill,
        product: p1,
        quantity: 1.0,
        isTaxEnabled: false,
      );

      expect(billWithP1.items.length, equals(1));
      expect(billWithP1.items.first.productId, equals('prod_1'));
      expect(billWithP1.items.first.productName,
          equals('Fortune Sunlite Refined Oil 1L'));
      expect(billWithP1.items.first.unitPricePaise, equals(14500));
      expect(billWithP1.subtotalPaise, equals(14500));
      expect(billWithP1.totalPaise, equals(14500));
    });

    test(
        '2. Feature: Duplicate Product scan increments quantity on existing row',
        () {
      final step1 = addProductUseCase.execute(
        bill: initialBill,
        product: p1,
        quantity: 1.0,
        isTaxEnabled: false,
      );

      // Scan/add same product a second time
      final step2 = addProductUseCase.execute(
        bill: step1,
        product: p1,
        quantity: 1.0,
        isTaxEnabled: false,
      );

      expect(step2.items.length, equals(1),
          reason: 'Should NOT create a second cart row');
      expect(step2.items.first.quantity, equals(2.0));
      expect(step2.subtotalPaise, equals(29000)); // ₹290.00
      expect(step2.totalPaise, equals(29000));
    });

    test(
        '3. Feature: Cart Quantity Control supports increment, decrement, and totals recalculation',
        () {
      final step1 = addProductUseCase.execute(
        bill: initialBill,
        product: p1,
        quantity: 1.0,
        isTaxEnabled: false,
      );
      final itemId = step1.items.first.id;

      // Increment quantity to 3
      final step2 = updateQuantityUseCase.execute(
        bill: step1,
        itemId: itemId,
        newQuantity: 3.0,
        isTaxEnabled: false,
      );
      expect(step2.items.first.quantity, equals(3.0));
      expect(step2.subtotalPaise, equals(43500)); // ₹435.00

      // Decrement quantity back to 2
      final step3 = updateQuantityUseCase.execute(
        bill: step2,
        itemId: itemId,
        newQuantity: 2.0,
        isTaxEnabled: false,
      );
      expect(step3.items.first.quantity, equals(2.0));
      expect(step3.subtotalPaise, equals(29000));
    });

    test(
        '4. Feature: Remove Cart Item immediately updates subtotal and totals without altering catalog',
        () {
      final billWithP1 = addProductUseCase.execute(
        bill: initialBill,
        product: p1,
        quantity: 1.0,
        isTaxEnabled: false,
      );
      final billWithBoth = addProductUseCase.execute(
        bill: billWithP1,
        product: p2,
        quantity: 1.0,
        isTaxEnabled: false,
      );

      expect(billWithBoth.items.length, equals(2));
      expect(billWithBoth.subtotalPaise,
          equals(38500)); // 14500 + 24000 = 38500 (₹385.00)

      final p1ItemId =
          billWithBoth.items.firstWhere((i) => i.productId == 'prod_1').id;

      final billAfterRemoval = removeItemUseCase.execute(
        bill: billWithBoth,
        itemId: p1ItemId,
        isTaxEnabled: false,
      );

      expect(billAfterRemoval.items.length, equals(1));
      expect(billAfterRemoval.items.first.productId, equals('prod_2'));
      expect(billAfterRemoval.subtotalPaise, equals(24000));
      expect(billAfterRemoval.totalPaise, equals(24000));
    });

    test(
        '5. Feature: Tax calculations respect Phase 12.4 configuration with integer paise math',
        () {
      final billWithTax = addProductUseCase.execute(
        bill: initialBill,
        product: p1,
        quantity: 2.0,
        isTaxEnabled: true,
        defaultTaxPercentage: 5.0, // 5% GST
      );

      // Subtotal = 14500 * 2 = 29000 (₹290.00)
      // Tax = 29000 * 0.05 = 1450 (₹14.50)
      // Total = 29000 + 1450 = 30450 (₹304.50)
      expect(billWithTax.subtotalPaise, equals(29000));
      expect(billWithTax.taxTotalPaise, equals(1450));
      expect(billWithTax.totalPaise, equals(30450));
    });
  });
}
