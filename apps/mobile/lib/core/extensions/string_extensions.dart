/// String utility extensions for KiranaOS.
extension StringExtension on String {
  /// Converts string to integer paise.
  int toPaise() {
    final cleaned = replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleaned.isEmpty) return 0;
    final value = double.tryParse(cleaned) ?? 0.0;
    return (value * 100).round();
  }

  /// Capitalizes first letter of the string.
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Validates standard 10-digit Indian mobile number.
  bool get isValidIndianPhone {
    final clean = replaceAll(RegExp(r'[^0-9]'), '');
    return clean.length == 10 && RegExp(r'^[6-9]').hasMatch(clean);
  }

  /// Validates standard 15-character GSTIN format.
  bool get isValidGstin {
    final clean = trim().toUpperCase();
    return RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$')
        .hasMatch(clean);
  }
}
