/// Centralized tax calculator for KiranaOS POS & Billing.
/// Handles tax resolution, tax-inclusive & tax-exclusive item calculations in paise,
/// and bill tax totals while respecting shop-level tax toggle.
class TaxCalculator {
  static const List<double> supportedTaxRates = [0.0, 5.0, 12.0, 18.0, 28.0];

  /// Resolves the effective tax rate percentage for a product based on shop settings.
  static double resolveEffectiveTaxRate({
    required bool isShopTaxEnabled,
    required double shopDefaultTaxRate,
    required String productTaxType, // 'shop_default', 'exempt', 'custom'
    required double productTaxRate,
  }) {
    if (!isShopTaxEnabled) return 0.0;
    if (productTaxType == 'exempt') return 0.0;
    if (productTaxType == 'custom') return productTaxRate;
    return shopDefaultTaxRate;
  }

  /// Calculates tax amount in paise for an item subtotal in paise.
  static int calculateItemTaxPaise({
    required int subtotalPaise,
    required double taxRatePercentage,
    required bool isTaxInclusive,
  }) {
    if (subtotalPaise <= 0 || taxRatePercentage <= 0.0) return 0;

    if (isTaxInclusive) {
      // Tax included in selling price: subtotal * (rate / (100 + rate))
      final tax =
          subtotalPaise * (taxRatePercentage / (100.0 + taxRatePercentage));
      return tax.round();
    } else {
      // Tax added to selling price: subtotal * (rate / 100)
      final tax = subtotalPaise * (taxRatePercentage / 100.0);
      return tax.round();
    }
  }

  /// Calculates total bill tax in paise from a list of item tax amounts.
  static int calculateTotalBillTaxPaise(List<int> itemTaxAmountsPaise) {
    return itemTaxAmountsPaise.fold<int>(0, (sum, tax) => sum + tax);
  }
}
