import 'package:kirana_mobile/core/errors/failure.dart';
import 'package:kirana_mobile/core/errors/result.dart';

enum BarcodeType {
  ean13,
  ean8,
  upcA,
  upcE,
  code128,
  code39,
  qrCode,
  custom;

  String get code {
    switch (this) {
      case BarcodeType.ean13:
        return 'EAN_13';
      case BarcodeType.ean8:
        return 'EAN_8';
      case BarcodeType.upcA:
        return 'UPC_A';
      case BarcodeType.upcE:
        return 'UPC_E';
      case BarcodeType.code128:
        return 'CODE_128';
      case BarcodeType.code39:
        return 'CODE_39';
      case BarcodeType.qrCode:
        return 'QR_CODE';
      case BarcodeType.custom:
        return 'CUSTOM';
    }
  }

  static BarcodeType fromCode(String code) {
    switch (code.toUpperCase()) {
      case 'EAN_13':
        return BarcodeType.ean13;
      case 'EAN_8':
        return BarcodeType.ean8;
      case 'UPC_A':
        return BarcodeType.upcA;
      case 'UPC_E':
        return BarcodeType.upcE;
      case 'CODE_128':
        return BarcodeType.code128;
      case 'CODE_39':
        return BarcodeType.code39;
      case 'QR_CODE':
        return BarcodeType.qrCode;
      default:
        return BarcodeType.custom;
    }
  }
}

class BarcodeValidator {
  static const int minLength = 3;
  static const int maxLength = 64;

  /// Clean & normalize raw input barcode string
  static String normalize(String raw) {
    return raw.trim().replaceAll(RegExp(r'\s+'), '').toUpperCase();
  }

  /// Auto-detect barcode format type
  static BarcodeType detectType(String code) {
    final cleaned = normalize(code);
    if (RegExp(r'^\d{13}$').hasMatch(cleaned)) return BarcodeType.ean13;
    if (RegExp(r'^\d{8}$').hasMatch(cleaned)) return BarcodeType.ean8;
    if (RegExp(r'^\d{12}$').hasMatch(cleaned)) return BarcodeType.upcA;
    if (RegExp(r'^\d{6}$').hasMatch(cleaned)) return BarcodeType.upcE;
    if (RegExp(r'^[A-Z0-9\-\.\ \$\/\+\%]+$').hasMatch(cleaned)) {
      return BarcodeType.code39;
    }
    if (RegExp(r'^[A-Z0-9_\-\/]+$').hasMatch(cleaned)) {
      return BarcodeType.code128;
    }
    return BarcodeType.custom;
  }

  /// Validate raw barcode string
  static Result<String, Failure> validate(String rawBarcode) {
    final clean = normalize(rawBarcode);

    if (clean.isEmpty) {
      return const ErrorResult(ValidationFailure('Barcode cannot be empty'));
    }

    if (clean.length < minLength) {
      return ErrorResult(ValidationFailure(
          'Barcode must be at least $minLength characters long'));
    }

    if (clean.length > maxLength) {
      return ErrorResult(ValidationFailure(
          'Barcode length cannot exceed $maxLength characters'));
    }

    // Allow digits, uppercase letters, hyphens, underscores, slashes, dots
    final validCharsRegex = RegExp(r'^[A-Z0-9_\-\/\.\+]+$');
    if (!validCharsRegex.hasMatch(clean)) {
      return const ErrorResult(ValidationFailure(
          'Barcode contains invalid characters. Only alphanumeric, hyphens, and slashes are allowed.'));
    }

    return Success(clean);
  }
}
