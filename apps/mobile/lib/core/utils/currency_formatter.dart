import 'package:intl/intl.dart';

/// Centralized currency formatting utility for KiranaOS.
/// Standardizes currency code, symbol, decimal precision, and paise conversion.
class CurrencyFormatter {
  static String format(
    double amount, {
    String symbol = '₹',
    int precision = 2,
    bool includeSymbol = true,
  }) {
    final formattedNumber = amount.toStringAsFixed(precision);
    if (!includeSymbol) return formattedNumber;
    return '$symbol$formattedNumber';
  }

  /// Formats paise integer amount (100 paise = ₹1.00) into formatted currency string.
  static String formatPaise(
    int paise, {
    String symbol = '₹',
    bool showDecimals = true,
    bool includeSymbol = true,
  }) {
    final rupees = paise / 100.0;
    final prefix = includeSymbol ? symbol : '';
    if (!showDecimals) {
      return '$prefix${NumberFormat('#,##,##0', 'en_IN').format(rupees.floor())}';
    }
    return '$prefix${NumberFormat('#,##,##0.00', 'en_IN').format(rupees)}';
  }

  /// Formats paise into compact representation (e.g. ₹1.2k, ₹1.5L).
  static String formatPaiseCompact(int paise,
      {String symbol = '₹', bool includeSymbol = true}) {
    final rupees = paise / 100.0;
    final prefix = includeSymbol ? symbol : '';
    if (rupees >= 100000) {
      return '$prefix${(rupees / 100000).toStringAsFixed(1)}L';
    } else if (rupees >= 1000) {
      return '$prefix${(rupees / 1000).toStringAsFixed(1)}k';
    }
    return formatPaise(paise, symbol: symbol, includeSymbol: includeSymbol);
  }

  /// Parses rupee string (e.g. "₹1,250.75" or "10.50") into integer paise (e.g. 125075).
  static int parseRupeesToPaise(String input) {
    final clean = input.replaceAll(RegExp(r'[^0-9\.]'), '');
    if (clean.isEmpty) return 0;
    final value = double.tryParse(clean) ?? 0.0;
    return (value * 100).round();
  }
}
