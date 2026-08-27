import 'package:flutter_test/flutter_test.dart';

import 'package:kirana_mobile/features/billing/domain/models/bill_model.dart';
import 'package:kirana_mobile/features/billing/domain/usecases/billing_usecases.dart';
import 'package:kirana_mobile/features/products/domain/models/product_model.dart';

void main() {
  group('Phase 13.3 — Discount Foundation UseCases & Validation', () {
    late CalculateBillTotalsUseCase calculateTotalsUseCase;
    late AddProductToBillUseCase addProductUseCase;
    late ApplyBillDiscountUseCase applyDiscountUseCase;
    late ValidateBillUseCase validateBillUseCase;

    final now = DateTime.now();
    final initialBill = BillModel(
      id: 'bill_test_discount',
      shopId: 'shop_A',
      cashierId: 'cashier_1',
      billNumber: 'BILL-DSC-001',
      createdAt: now,
      updatedAt: now,
    );

    final item1 = ProductModel(
      id: 'prod_500',
      shopId: 'shop_A',
      name: 'Dairy Milk Silk 150g',
      sellingPricePaise: 50000, // ₹500.00
      mrpPaise: 55000,
      unit: 'PCS',
      currentStock: 10,
      createdAt: now,
      updatedAt: now,
    );

    final item2 = ProductModel(
      id: 'prod_1000',
      shopId: 'shop_A',
      name: 'Basmati Rice 5kg',
      sellingPricePaise: 100000, // ₹1000.00
      mrpPaise: 110000,
      unit: 'PACK',
      currentStock: 5,
      createdAt: now,
      updatedAt: now,
    );

    setUp(() {
      calculateTotalsUseCase = CalculateBillTotalsUseCase();
      addProductUseCase = AddProductToBillUseCase(calculateTotalsUseCase);
      applyDiscountUseCase = ApplyBillDiscountUseCase(calculateTotalsUseCase);
      validateBillUseCase = ValidateBillUseCase();
    });

    test(
        '1. Feature: Bill-Level Flat Discount (₹500 subtotal - ₹50 discount = ₹450 total)',
        () {
      final bill = addProductUseCase.execute(
        bill: initialBill,
        product: item1,
        quantity: 1.0,
        isTaxEnabled: false,
      );

      expect(bill.subtotalPaise, equals(50000)); // ₹500.00

      final result = applyDiscountUseCase.execute(
        bill: bill,
        discountType: 'fixed',
        discountValue: 5000.0, // ₹50.00 in paise
        isTaxEnabled: false,
      );

      expect(result.isSuccess, isTrue);
      final discountedBill = result.dataOrNull!;
      expect(discountedBill.discountPaise, equals(5000)); // ₹50.00
      expect(discountedBill.subtotalPaise, equals(50000));
      expect(discountedBill.totalPaise, equals(45000)); // ₹450.00
    });

    test(
        '2. Feature: Bill-Level Percentage Discount (₹1000 subtotal - 10% discount = ₹900 total)',
        () {
      final bill = addProductUseCase.execute(
        bill: initialBill,
        product: item2,
        quantity: 1.0,
        isTaxEnabled: false,
      );

      expect(bill.subtotalPaise, equals(100000)); // ₹1000.00

      final result = applyDiscountUseCase.execute(
        bill: bill,
        discountType: 'percentage',
        discountValue: 10.0, // 10%
        isTaxEnabled: false,
      );

      expect(result.isSuccess, isTrue);
      final discountedBill = result.dataOrNull!;
      expect(discountedBill.discountPaise, equals(10000)); // ₹100.00
      expect(discountedBill.totalPaise, equals(90000)); // ₹900.00
    });

    test(
        '3. Feature: Discount Validation allows 100% discount and rejects 101%',
        () {
      final bill = addProductUseCase.execute(
        bill: initialBill,
        product: item1,
        quantity: 1.0,
        isTaxEnabled: false,
      );

      // 100% discount is valid (e.g. promotional 100% off)
      final valid100 = applyDiscountUseCase.execute(
        bill: bill,
        discountType: 'percentage',
        discountValue: 100.0,
        isTaxEnabled: false,
      );
      expect(valid100.isSuccess, isTrue);
      expect(valid100.dataOrNull!.totalPaise, equals(0));

      // 101% discount is rejected
      final invalid101 = applyDiscountUseCase.execute(
        bill: bill,
        discountType: 'percentage',
        discountValue: 101.0,
        isTaxEnabled: false,
      );
      expect(invalid101.isError, isTrue);
      expect(
          invalid101.failureOrNull?.message, contains('between 0% and 100%'));
    });

    test(
        '4. Feature: Discount Validation rejects Flat discount exceeding subtotal (e.g. ₹600 on ₹500 subtotal)',
        () {
      final bill = addProductUseCase.execute(
        bill: initialBill,
        product: item1, // ₹500.00 subtotal
        quantity: 1.0,
        isTaxEnabled: false,
      );

      final excessResult = applyDiscountUseCase.execute(
        bill: bill,
        discountType: 'fixed',
        discountValue: 60000.0, // ₹600.00 in paise
        isTaxEnabled: false,
      );

      expect(excessResult.isError, isTrue);
      expect(excessResult.failureOrNull?.message,
          contains('cannot exceed the bill subtotal'));
    });

    test('5. Feature: Discount Validation rejects negative discount amounts',
        () {
      final bill = addProductUseCase.execute(
        bill: initialBill,
        product: item1,
        quantity: 1.0,
        isTaxEnabled: false,
      );

      final negativeResult = applyDiscountUseCase.execute(
        bill: bill,
        discountType: 'fixed',
        discountValue: -500.0,
        isTaxEnabled: false,
      );

      expect(negativeResult.isError, isTrue);
      expect(negativeResult.failureOrNull?.message,
          contains('cannot be negative'));
    });

    test('6. Feature: Tax integration computes Tax after discount accurately',
        () {
      final billWithTax = addProductUseCase.execute(
        bill: initialBill,
        product: item2, // ₹1000.00 subtotal
        quantity: 1.0,
        isTaxEnabled: true,
        defaultTaxPercentage: 10.0, // 10% tax
      );

      // Subtotal = 100,000 paise (₹1000.00)
      // Apply 20% discount = 20,000 paise discount (₹200.00)
      // Net = 80,000 paise
      // Tax (10%) = 10,000 paise
      // Grand Total = 100,000 - 20,000 + 10,000 = 90,000 paise (₹900.00)
      final discountedResult = applyDiscountUseCase.execute(
        bill: billWithTax,
        discountType: 'percentage',
        discountValue: 20.0,
        isTaxEnabled: true,
        defaultTaxPercentage: 10.0,
      );

      expect(discountedResult.isSuccess, isTrue);
      final finalBill = discountedResult.dataOrNull!;
      expect(finalBill.subtotalPaise, equals(100000));
      expect(finalBill.discountPaise, equals(20000));
      expect(finalBill.taxTotalPaise, equals(10000));
      expect(finalBill.totalPaise, equals(90000));
    });

    test(
        '7. Feature: Clear/Remove discount resets discount to 0 and updates grand total',
        () {
      final bill = addProductUseCase.execute(
        bill: initialBill,
        product: item1,
        quantity: 1.0,
        isTaxEnabled: false,
      );

      final discounted = applyDiscountUseCase
          .execute(
            bill: bill,
            discountType: 'fixed',
            discountValue: 5000.0, // ₹50.00
            isTaxEnabled: false,
          )
          .dataOrNull!;

      expect(discounted.totalPaise, equals(45000));

      final cleared = applyDiscountUseCase
          .execute(
            bill: discounted,
            discountType: 'none',
            discountValue: 0.0,
            isTaxEnabled: false,
          )
          .dataOrNull!;

      expect(cleared.discountType, equals('none'));
      expect(cleared.discountPaise, equals(0));
      expect(cleared.totalPaise, equals(50000));
    });

    test('8. Security: RBAC rejects discount validation for INVENTORY_STAFF',
        () {
      final bill = addProductUseCase.execute(
        bill: initialBill,
        product: item1,
        quantity: 1.0,
        isTaxEnabled: false,
      );

      final validation = validateBillUseCase.execute(
        bill: bill,
        activeShopId: 'shop_A',
        userRole: 'inventory_staff',
      );

      expect(validation.isError, isTrue);
      expect(validation.failureOrNull?.message, contains('not authorized'));
    });
  });
}
