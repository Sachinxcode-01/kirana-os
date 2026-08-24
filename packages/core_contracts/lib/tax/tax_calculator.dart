import '../currency/money.dart';

/// Result of a Goods and Services Tax (GST) calculation.
final class TaxBreakdown {
  /// Base price before tax in paise
  final Money basePrice;

  /// Total tax amount in paise
  final Money totalTax;

  /// Central GST component (50% of total tax in intra-state)
  final Money cgst;

  /// State GST component (50% of total tax in intra-state)
  final Money sgst;

  /// Integrated GST component (100% of tax in inter-state)
  final Money igst;

  /// Final gross price in paise
  final Money grossPrice;

  /// Applied tax rate percentage (e.g. 5.0, 12.0, 18.0, 28.0)
  final double ratePercentage;

  const TaxBreakdown({
    required this.basePrice,
    required this.totalTax,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.grossPrice,
    required this.ratePercentage,
  });
}

/// Pure business calculator for Indian GST tax slabs.
abstract final class TaxCalculator {
  /// Computes tax when selling price is inclusive of GST.
  static TaxBreakdown calculateInclusive({
    required Money grossAmount,
    required double taxRatePercentage,
    bool isInterState = false,
  }) {
    if (taxRatePercentage <= 0.0) {
      return TaxBreakdown(
        basePrice: grossAmount,
        totalTax: Money.zero,
        cgst: Money.zero,
        sgst: Money.zero,
        igst: Money.zero,
        grossPrice: grossAmount,
        ratePercentage: 0.0,
      );
    }

    // Base = Gross * 100 / (100 + Rate)
    final basePaise = ((grossAmount.paise * 10000) / (10000 + (taxRatePercentage * 100))).round();
    final basePrice = Money.fromPaise(basePaise);
    final totalTax = grossAmount - basePrice;

    if (isInterState) {
      return TaxBreakdown(
        basePrice: basePrice,
        totalTax: totalTax,
        cgst: Money.zero,
        sgst: Money.zero,
        igst: totalTax,
        grossPrice: grossAmount,
        ratePercentage: taxRatePercentage,
      );
    } else {
      final cgstPaise = (totalTax.paise / 2).round();
      final sgstPaise = totalTax.paise - cgstPaise;
      return TaxBreakdown(
        basePrice: basePrice,
        totalTax: totalTax,
        cgst: Money.fromPaise(cgstPaise),
        sgst: Money.fromPaise(sgstPaise),
        igst: Money.zero,
        grossPrice: grossAmount,
        ratePercentage: taxRatePercentage,
      );
    }
  }

  /// Computes tax when base price is exclusive of GST.
  static TaxBreakdown calculateExclusive({
    required Money baseAmount,
    required double taxRatePercentage,
    bool isInterState = false,
  }) {
    if (taxRatePercentage <= 0.0) {
      return TaxBreakdown(
        basePrice: baseAmount,
        totalTax: Money.zero,
        cgst: Money.zero,
        sgst: Money.zero,
        igst: Money.zero,
        grossPrice: baseAmount,
        ratePercentage: 0.0,
      );
    }

    final taxPaise = ((baseAmount.paise * taxRatePercentage) / 100.0).round();
    final totalTax = Money.fromPaise(taxPaise);
    final grossPrice = baseAmount + totalTax;

    if (isInterState) {
      return TaxBreakdown(
        basePrice: baseAmount,
        totalTax: totalTax,
        cgst: Money.zero,
        sgst: Money.zero,
        igst: totalTax,
        grossPrice: grossPrice,
        ratePercentage: taxRatePercentage,
      );
    } else {
      final cgstPaise = (taxPaise / 2).round();
      final sgstPaise = taxPaise - cgstPaise;
      return TaxBreakdown(
        basePrice: baseAmount,
        totalTax: totalTax,
        cgst: Money.fromPaise(cgstPaise),
        sgst: Money.fromPaise(sgstPaise),
        igst: Money.zero,
        grossPrice: grossPrice,
        ratePercentage: taxRatePercentage,
      );
    }
  }
}
