import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_mobile/features/barcodes/domain/utils/barcode_validator.dart';

void main() {
  group('BarcodeValidator Unit Tests', () {
    test('Normalizes barcode input correctly', () {
      expect(BarcodeValidator.normalize('  8901030 383742  '), '8901030383742');
      expect(BarcodeValidator.normalize(' ean-1234 '), 'EAN-1234');
    });

    test('Validates EAN-13, EAN-8, UPC-A, Code-128, Code-39 successfully', () {
      expect(BarcodeValidator.validate('8901030383742').isSuccess, isTrue);
      expect(BarcodeValidator.validate('89012345').isSuccess, isTrue);
      expect(BarcodeValidator.validate('012345678905').isSuccess, isTrue);
      expect(BarcodeValidator.validate('CODE128-PROD_1').isSuccess, isTrue);
    });

    test('Rejects empty or whitespace barcode', () {
      final res = BarcodeValidator.validate('   ');
      expect(res.isError, isTrue);
      expect(res.failureOrNull?.message, 'Barcode cannot be empty');
    });

    test('Rejects short barcodes (<3 chars)', () {
      final res = BarcodeValidator.validate('12');
      expect(res.isError, isTrue);
      expect(res.failureOrNull?.message,
          'Barcode must be at least 3 characters long');
    });

    test('Rejects excessively long barcodes (>64 chars)', () {
      final longBarcode = 'A' * 65;
      final res = BarcodeValidator.validate(longBarcode);
      expect(res.isError, isTrue);
      expect(res.failureOrNull?.message,
          'Barcode length cannot exceed 64 characters');
    });

    test('Rejects barcodes with invalid control or special characters', () {
      final res = BarcodeValidator.validate('8901030@#\$%');
      expect(res.isError, isTrue);
      expect(
          res.failureOrNull?.message, contains('contains invalid characters'));
    });

    test('Auto-detects barcode format types accurately', () {
      expect(BarcodeValidator.detectType('8901030383742'), BarcodeType.ean13);
      expect(BarcodeValidator.detectType('12345678'), BarcodeType.ean8);
      expect(BarcodeValidator.detectType('012345678905'), BarcodeType.upcA);
      expect(BarcodeValidator.detectType('123456'), BarcodeType.upcE);
      expect(BarcodeValidator.detectType('PROD-123_ABC'), BarcodeType.code128);
    });
  });
}
