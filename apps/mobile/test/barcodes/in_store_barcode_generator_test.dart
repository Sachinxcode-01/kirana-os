import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_mobile/core/errors/result.dart';
import 'package:kirana_mobile/features/barcodes/domain/utils/in_store_barcode_generator.dart';

void main() {
  group('InStoreBarcodeGenerator EAN-13 Tests', () {
    test('calculateEan13CheckDigit computes correct check digit for known EAN-13 codes', () {
      // Known valid EAN-13 barcode: 8901030383458
      // 12 digits: 890103038345 -> Check digit: 8
      expect(InStoreBarcodeGenerator.calculateEan13CheckDigit('890103038345'), 8);

      // Known valid barcode: 8901491101837
      // 12 digits: 890149110183 -> Check digit: 7
      expect(InStoreBarcodeGenerator.calculateEan13CheckDigit('890149110183'), 7);

      // In-store prefix: 200000100500 -> Check digit computation
      final check = InStoreBarcodeGenerator.calculateEan13CheckDigit('200000100500');
      expect(check >= 0 && check <= 9, isTrue);
    });

    test('isValidEan13 accurately detects valid and invalid checksums', () {
      expect(InStoreBarcodeGenerator.isValidEan13('8901030383458'), isTrue);
      expect(InStoreBarcodeGenerator.isValidEan13('8901030383452'), isFalse); // Wrong check digit
      expect(InStoreBarcodeGenerator.isValidEan13('12345'), isFalse); // Too short
      expect(InStoreBarcodeGenerator.isValidEan13('890103038345A'), isFalse); // Non-numeric
    });

    test('generateInStoreEan13 produces valid 13-digit EAN with prefix 20', () {
      for (int i = 0; i < 20; i++) {
        final barcode = InStoreBarcodeGenerator.generateInStoreEan13();
        expect(barcode.length, 13);
        expect(barcode.startsWith('20'), isTrue);
        expect(InStoreBarcodeGenerator.isValidEan13(barcode), isTrue);
      }
    });

    test('generateInStoreEan13 handles custom SKU code correctly', () {
      final barcode = InStoreBarcodeGenerator.generateInStoreEan13(customSkuCode: '1054');
      expect(barcode.length, 13);
      expect(barcode.startsWith('200000001054'), isTrue);
      expect(InStoreBarcodeGenerator.isValidEan13(barcode), isTrue);
    });
  });

  group('Weight & Price Embedded Barcode Tests', () {
    test('encodeWeightEmbeddedBarcode formats 20 + SKU + Grams + Check', () {
      final res = InStoreBarcodeGenerator.encodeWeightEmbeddedBarcode(
        itemSku: '45',
        weightKg: 1.250, // 1250 grams
      );

      expect(res, isA<Success<String, dynamic>>());
      final barcode = (res as Success<String, dynamic>).data;
      expect(barcode.length, 13);
      expect(barcode.startsWith('200004501250'), isTrue);
      expect(InStoreBarcodeGenerator.isValidEan13(barcode), isTrue);
    });

    test('decodeEmbeddedBarcode correctly parses weight-embedded barcodes', () {
      // 1.250kg of SKU 00045
      final encodeRes = InStoreBarcodeGenerator.encodeWeightEmbeddedBarcode(
        itemSku: '00045',
        weightKg: 1.250,
      );
      final barcode = (encodeRes as Success<String, dynamic>).data;

      final decoded = InStoreBarcodeGenerator.decodeEmbeddedBarcode(barcode);
      expect(decoded, isNotNull);
      expect(decoded!.isWeightEmbedded, isTrue);
      expect(decoded.itemSku, '00045');
      expect(decoded.weightKg, closeTo(1.250, 0.001));
    });

    test('encodePriceEmbeddedBarcode formats 21 + SKU + Rupees + Check and decodes properly', () {
      final res = InStoreBarcodeGenerator.encodePriceEmbeddedBarcode(
        itemSku: '98',
        pricePaise: 45000, // ₹450
      );

      expect(res, isA<Success<String, dynamic>>());
      final barcode = (res as Success<String, dynamic>).data;
      expect(barcode.startsWith('210009800450'), isTrue);
      expect(InStoreBarcodeGenerator.isValidEan13(barcode), isTrue);

      final decoded = InStoreBarcodeGenerator.decodeEmbeddedBarcode(barcode);
      expect(decoded, isNotNull);
      expect(decoded!.isPriceEmbedded, isTrue);
      expect(decoded.itemSku, '00098');
      expect(decoded.pricePaise, 45000);
    });

    test('Rejects invalid weights or prices', () {
      final negWeight = InStoreBarcodeGenerator.encodeWeightEmbeddedBarcode(
        itemSku: '1',
        weightKg: -0.5,
      );
      expect(negWeight, isA<ErrorResult<String, dynamic>>());

      final zeroPrice = InStoreBarcodeGenerator.encodePriceEmbeddedBarcode(
        itemSku: '1',
        pricePaise: 0,
      );
      expect(zeroPrice, isA<ErrorResult<String, dynamic>>());
    });
  });
}
