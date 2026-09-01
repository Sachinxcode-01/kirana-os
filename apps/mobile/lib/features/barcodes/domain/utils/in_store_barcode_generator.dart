import 'dart:math';
import 'package:kirana_mobile/core/errors/failure.dart';
import 'package:kirana_mobile/core/errors/result.dart';

/// Embedded barcode payload for loose/weighed commodities
class EmbeddedBarcodeResult {
  final String prefix; // '20' for weight, '21' for price
  final String itemSku; // 5-digit product SKU
  final double? weightKg; // Weight in Kilograms (if weight-embedded)
  final int? pricePaise; // Price in Paise (if price-embedded)
  final String fullBarcode;

  const EmbeddedBarcodeResult({
    required this.prefix,
    required this.itemSku,
    this.weightKg,
    this.pricePaise,
    required this.fullBarcode,
  });

  bool get isWeightEmbedded => prefix == '20' && weightKg != null;
  bool get isPriceEmbedded => prefix == '21' && pricePaise != null;
}

class InStoreBarcodeGenerator {
  /// Calculate EAN-13 Luhn Check Digit for a 12-digit string
  static int calculateEan13CheckDigit(String twelveDigits) {
    if (twelveDigits.length != 12 || !RegExp(r'^\d{12}$').hasMatch(twelveDigits)) {
      throw ArgumentError('Input must be exactly 12 numeric digits');
    }

    int sum = 0;
    for (int i = 0; i < 12; i++) {
      final digit = int.parse(twelveDigits[i]);
      // Alternating weights: 1 for odd index (0, 2, 4...), 3 for even index (1, 3, 5...)
      sum += (i % 2 == 0) ? digit * 1 : digit * 3;
    }

    final remainder = sum % 10;
    return (remainder == 0) ? 0 : (10 - remainder);
  }

  /// Verify if a 13-digit barcode has a valid EAN-13 Luhn check digit
  static bool isValidEan13(String barcode) {
    if (barcode.length != 13 || !RegExp(r'^\d{13}$').hasMatch(barcode)) {
      return false;
    }
    final expectedCheck = calculateEan13CheckDigit(barcode.substring(0, 12));
    final actualCheck = int.parse(barcode[12]);
    return expectedCheck == actualCheck;
  }

  /// Generate standard in-store 13-digit EAN barcode
  /// Prefix: 20 to 29 (GS1 reserved for internal in-store retail use)
  static String generateInStoreEan13({
    String prefix = '20',
    String? customSkuCode,
  }) {
    if (prefix.length != 2 || !RegExp(r'^[2-9][0-9]$').hasMatch(prefix)) {
      prefix = '20';
    }

    String skuPart;
    if (customSkuCode != null && RegExp(r'^\d+$').hasMatch(customSkuCode)) {
      // Pad or trim to 10 digits
      skuPart = customSkuCode.padLeft(10, '0');
      if (skuPart.length > 10) {
        skuPart = skuPart.substring(skuPart.length - 10);
      }
    } else {
      // Generate 10 pseudo-random numeric digits
      final rand = Random();
      final p1 = rand.nextInt(90000) + 10000;
      final p2 = rand.nextInt(90000) + 10000;
      skuPart = '$p1$p2';
    }

    final twelveDigits = '$prefix$skuPart';
    final checkDigit = calculateEan13CheckDigit(twelveDigits);
    return '$twelveDigits$checkDigit';
  }

  /// Encode weight-embedded EAN-13 barcode for loose items
  /// Format: 20 (Prefix) + 5-digit SKU + 5-digit Weight in Grams + 1-digit Check
  /// Example: SKU 00123, 1.250kg -> 200012301250C
  static Result<String, Failure> encodeWeightEmbeddedBarcode({
    required String itemSku,
    required double weightKg,
  }) {
    if (weightKg <= 0 || weightKg > 99.999) {
      return const ErrorResult(
        ValidationFailure('Weight must be between 0.001 kg and 99.999 kg'),
      );
    }

    final cleanSku = itemSku.replaceAll(RegExp(r'\D'), '');
    final sku5 = cleanSku.padLeft(5, '0');
    final formattedSku = sku5.length > 5 ? sku5.substring(sku5.length - 5) : sku5;

    final grams = (weightKg * 1000).round();
    final weight5 = grams.toString().padLeft(5, '0');

    final twelveDigits = '20$formattedSku$weight5';
    final checkDigit = calculateEan13CheckDigit(twelveDigits);
    return Success('$twelveDigits$checkDigit');
  }

  /// Encode price-embedded EAN-13 barcode
  /// Format: 21 (Prefix) + 5-digit SKU + 5-digit Price in Rupees + 1-digit Check
  static Result<String, Failure> encodePriceEmbeddedBarcode({
    required String itemSku,
    required int pricePaise,
  }) {
    if (pricePaise <= 0 || pricePaise > 9999900) {
      return const ErrorResult(
        ValidationFailure('Price must be between ₹1 and ₹99,999'),
      );
    }

    final cleanSku = itemSku.replaceAll(RegExp(r'\D'), '');
    final sku5 = cleanSku.padLeft(5, '0');
    final formattedSku = sku5.length > 5 ? sku5.substring(sku5.length - 5) : sku5;

    final rupees = pricePaise ~/ 100;
    final price5 = rupees.toString().padLeft(5, '0');

    final twelveDigits = '21$formattedSku$price5';
    final checkDigit = calculateEan13CheckDigit(twelveDigits);
    return Success('$twelveDigits$checkDigit');
  }

  /// Decode variable in-store barcode (detects if barcode has embedded weight or price)
  static EmbeddedBarcodeResult? decodeEmbeddedBarcode(String barcode) {
    final clean = barcode.trim();
    if (clean.length != 13 || !isValidEan13(clean)) {
      return null;
    }

    final prefix = clean.substring(0, 2);
    final sku = clean.substring(2, 7);
    final valueStr = clean.substring(7, 12);

    if (prefix == '20') {
      // Weight in grams
      final grams = int.tryParse(valueStr) ?? 0;
      final kg = grams / 1000.0;
      return EmbeddedBarcodeResult(
        prefix: '20',
        itemSku: sku,
        weightKg: kg,
        fullBarcode: clean,
      );
    } else if (prefix == '21') {
      // Price in Rupees
      final rupees = int.tryParse(valueStr) ?? 0;
      final paise = rupees * 100;
      return EmbeddedBarcodeResult(
        prefix: '21',
        itemSku: sku,
        pricePaise: paise,
        fullBarcode: clean,
      );
    }

    return null;
  }
}
