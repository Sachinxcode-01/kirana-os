import 'package:intl/intl.dart';

/// Formatter for converting integer paise to formatted Indian Rupee strings.
abstract final class CurrencyFormatter {
  static final NumberFormat _inrFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final NumberFormat _inrCompact = NumberFormat.compactCurrency(
    locale: 'en_IN',
    symbol: '₹',
  );

  /// Formats paise integer (e.g. 145050 -> "₹1,450.50").
  static String formatPaise(int paise, {bool includeSymbol = true}) {
    final rupees = paise / 100.0;
    if (!includeSymbol) {
      return NumberFormat.decimalPatternDigits(
              locale: 'en_IN', decimalDigits: 2)
          .format(rupees);
    }
    return _inrFormatter.format(rupees).trim();
  }

  /// Compact formatting for dashboard stats (e.g. 15000000 -> "₹1.5L").
  static String formatPaiseCompact(int paise) {
    return _inrCompact.format(paise / 100.0).trim();
  }

  /// Parses user rupee text input (e.g. "14.50") into integer paise (1450).
  static int parseRupeesToPaise(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleaned.isEmpty) return 0;
    final value = double.tryParse(cleaned) ?? 0.0;
    return (value * 100).round();
  }
}
