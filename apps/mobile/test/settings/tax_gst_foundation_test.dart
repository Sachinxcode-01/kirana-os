import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_mobile/core/utils/tax_calculator.dart';
import 'package:kirana_mobile/features/products/domain/models/product_model.dart';
import 'package:kirana_mobile/features/settings/domain/models/shop_settings_model.dart';

void main() {
  group('KIRANAOS PHASE 12.4 — Tax / GST Foundation Tests', () {
    test('1. Tax OFF by default: resolves effective tax rate to 0.0%', () {
      const defaultSettings = ShopSettingsModel(
        shopId: 'shop_tax_101',
        shopName: 'Green Grocery',
        phone: '9876543210',
      );

      expect(defaultSettings.isTaxEnabled, isFalse);

      final effectiveRate = TaxCalculator.resolveEffectiveTaxRate(
        isShopTaxEnabled: defaultSettings.isTaxEnabled,
        shopDefaultTaxRate: defaultSettings.defaultTaxPercentage,
        productTaxType: 'custom',
        productTaxRate: 18.0,
      );

      expect(effectiveRate, equals(0.0));
    });

    test(
        '2. Tax ON: Resolves shop_default, exempt, and custom tax rates correctly',
        () {
      const isShopTaxEnabled = true;
      const shopDefaultTaxRate = 12.0;

      // Shop default product
      final shopDefaultRate = TaxCalculator.resolveEffectiveTaxRate(
        isShopTaxEnabled: isShopTaxEnabled,
        shopDefaultTaxRate: shopDefaultTaxRate,
        productTaxType: 'shop_default',
        productTaxRate: 0.0,
      );
      expect(shopDefaultRate, equals(12.0));

      // Exempt product
      final exemptRate = TaxCalculator.resolveEffectiveTaxRate(
        isShopTaxEnabled: isShopTaxEnabled,
        shopDefaultTaxRate: shopDefaultTaxRate,
        productTaxType: 'exempt',
        productTaxRate: 18.0,
      );
      expect(exemptRate, equals(0.0));

      // Custom product (e.g. 28%)
      final customRate = TaxCalculator.resolveEffectiveTaxRate(
        isShopTaxEnabled: isShopTaxEnabled,
        shopDefaultTaxRate: shopDefaultTaxRate,
        productTaxType: 'custom',
        productTaxRate: 28.0,
      );
      expect(customRate, equals(28.0));
    });

    test('3. Tax calculation: Inclusive vs Exclusive pricing in paise', () {
      // Subtotal ₹100.00 = 10000 paise with 18% tax
      final inclusiveTaxPaise = TaxCalculator.calculateItemTaxPaise(
        subtotalPaise: 10000,
        taxRatePercentage: 18.0,
        isTaxInclusive: true,
      );
      // 10000 * (18 / 118) = 1525.42 -> 1525 paise (₹15.25)
      expect(inclusiveTaxPaise, equals(1525));

      final exclusiveTaxPaise = TaxCalculator.calculateItemTaxPaise(
        subtotalPaise: 10000,
        taxRatePercentage: 18.0,
        isTaxInclusive: false,
      );
      // 10000 * (18 / 100) = 1800 paise (₹18.00)
      expect(exclusiveTaxPaise, equals(1800));
    });

    test('4. Supported tax rates validation', () {
      expect(TaxCalculator.supportedTaxRates,
          containsAll([0.0, 5.0, 12.0, 18.0, 28.0]));
    });

    test('5. Product model default taxType is shop_default', () {
      final product = ProductModel(
        id: 'prod_101',
        shopId: 'shop_101',
        name: 'Basmati Rice 5kg',
        sellingPricePaise: 45000,
        mrpPaise: 50000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(product.taxType, equals('shop_default'));
      expect(product.taxRatePercentage, equals(0.0));
    });

    test('6. Historical bill tax snapshot immutability verification', () {
      // Create initial product with 5% tax
      final originalProduct = ProductModel(
        id: 'prod_oil_101',
        shopId: 'shop_101',
        name: 'Sunflower Oil 1L',
        sellingPricePaise: 15000,
        mrpPaise: 17000,
        taxType: 'custom',
        taxRatePercentage: 5.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Snapshot taken at billing time
      final snapshottedTaxRate = originalProduct.taxRatePercentage;
      final billItemTaxPaise = TaxCalculator.calculateItemTaxPaise(
        subtotalPaise: originalProduct.sellingPricePaise,
        taxRatePercentage: snapshottedTaxRate,
        isTaxInclusive: true,
      );

      // Product tax rate updated later to 12%
      final updatedProduct = originalProduct.copyWith(
        taxRatePercentage: 12.0,
        updatedAt: DateTime.now(),
      );

      // Verify historical bill item tax remains preserved at 5% snapshot
      expect(snapshottedTaxRate, equals(5.0));
      expect(billItemTaxPaise, equals(714)); // 15000 * (5/105) = 714 paise

      // Verify new bill uses updated 12% rate
      final newBillItemTaxPaise = TaxCalculator.calculateItemTaxPaise(
        subtotalPaise: updatedProduct.sellingPricePaise,
        taxRatePercentage: updatedProduct.taxRatePercentage,
        isTaxInclusive: true,
      );
      expect(
          newBillItemTaxPaise, equals(1607)); // 15000 * (12/112) = 1607 paise
    });
  });
}
