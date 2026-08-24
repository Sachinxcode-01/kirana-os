import 'package:test/test.dart';
import 'package:core_contracts/currency/money.dart';
import 'package:core_contracts/tax/tax_calculator.dart';

void main() {
  group('Money Paise Invariants', () {
    test('Zero floating point rounding error in addition', () {
      final m1 = Money.fromPaise(10); // ₹0.10
      final m2 = Money.fromPaise(20); // ₹0.20
      final sum = m1 + m2;
      expect(sum.paise, 30);
      expect(sum.inRupees, 0.30);
      expect(sum.format(), '₹0.30');
    });

    test('Paise multiplication and division', () {
      final price = Money.fromPaise(24500); // ₹245.00
      final total = price * 3;
      expect(total.paise, 73500);
      expect(total.format(), '₹735.00');
    });
  });

  group('GST Tax Calculations', () {
    test('Calculate 5% inclusive GST', () {
      final gross = Money.fromPaise(10500); // ₹105.00
      final result = TaxCalculator.calculateInclusive(
        grossAmount: gross,
        taxRatePercentage: 5.0,
      );
      expect(result.basePrice.paise, 10000); // ₹100.00
      expect(result.totalTax.paise, 500);    // ₹5.00
      expect(result.cgst.paise, 250);        // ₹2.50
      expect(result.sgst.paise, 250);        // ₹2.50
    });

    test('Calculate 18% exclusive GST', () {
      final base = Money.fromPaise(10000); // ₹100.00
      final result = TaxCalculator.calculateExclusive(
        baseAmount: base,
        taxRatePercentage: 18.0,
      );
      expect(result.totalTax.paise, 1800);   // ₹18.00
      expect(result.grossPrice.paise, 11800);// ₹118.00
      expect(result.cgst.paise, 900);        // ₹9.00
      expect(result.sgst.paise, 900);        // ₹9.00
    });
  });
}
