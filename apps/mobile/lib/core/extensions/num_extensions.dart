import '../utils/currency_formatter.dart';

/// Extension helpers on numbers for price formatting and widget spacing.
extension NumPaiseExtension on int {
  /// Converts integer paise directly to formatted INR string (e.g. 15000 -> "₹150.00").
  String toRupeesString({bool includeSymbol = true}) =>
      CurrencyFormatter.formatPaise(this, includeSymbol: includeSymbol);

  /// Converts integer paise to compact notation (e.g. 1500000 -> "₹15K").
  String toRupeesCompact() => CurrencyFormatter.formatPaiseCompact(this);
}

extension NumDoublePaiseExtension on double {
  /// Converts rupee double to formatted string.
  String toRupeeDisplay() =>
      CurrencyFormatter.formatPaise((this * 100).round());
}
