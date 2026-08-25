import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_mobile/features/barcode/presentation/widgets/scan_result_sheet.dart';
import 'package:kirana_mobile/features/barcodes/domain/utils/barcode_validator.dart';
import 'package:kirana_mobile/features/products/domain/models/product_model.dart';

void main() {
  group('ScanResultSheet Component Tests', () {
    testWidgets('Renders product details when product is found',
        (WidgetTester tester) async {
      final sampleProduct = ProductModel(
        id: 'prod_101',
        shopId: 'shop_1',
        name: 'Amul Butter 500g',
        categoryName: 'Dairy',
        unit: 'PCS',
        sellingPricePaise: 27500,
        mrpPaise: 29000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      bool scanAgainPressed = false;
      bool viewProductPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScanResultSheet(
              barcode: '8901262010052',
              product: sampleProduct,
              onScanAgain: () => scanAgainPressed = true,
              onViewProduct: () => viewProductPressed = true,
            ),
          ),
        ),
      );

      // Verify UI text
      expect(find.text('Product Scanned'), findsOneWidget);
      expect(find.text('8901262010052'), findsOneWidget);
      expect(find.text('Amul Butter 500g'), findsOneWidget);
      expect(find.text('Dairy'), findsOneWidget);
      expect(find.text('₹275.00'), findsOneWidget);
      expect(find.text('View Product'), findsOneWidget);
      expect(find.text('Scan Again'), findsOneWidget);

      // Tap actions
      await tester.tap(find.text('Scan Again'));
      expect(scanAgainPressed, isTrue);

      await tester.tap(find.text('View Product'));
      expect(viewProductPressed, isTrue);
    });

    testWidgets('Renders unknown barcode state when product is not found',
        (WidgetTester tester) async {
      bool addProductPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScanResultSheet(
              barcode: '9998887776665',
              product: null,
              onScanAgain: () {},
              onAddProduct: () => addProductPressed = true,
            ),
          ),
        ),
      );

      // Verify UI text
      expect(find.text('Barcode Not Recognized'), findsOneWidget);
      expect(find.text('9998887776665'), findsOneWidget);
      expect(find.text('No product found in catalog for "9998887776665".'),
          findsOneWidget);
      expect(find.text('+ Add Product'), findsOneWidget);

      await tester.tap(find.text('+ Add Product'));
      expect(addProductPressed, isTrue);
    });

    testWidgets('Displays offline banner when isOffline is true',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScanResultSheet(
              barcode: '8901030383742',
              product: null,
              isOffline: true,
              onScanAgain: () {},
            ),
          ),
        ),
      );

      expect(find.text('Product not available offline.'), findsOneWidget);
      expect(
          find.text(
              'Offline — searching saved products. Remote lookup requires internet.'),
          findsOneWidget);
    });
  });

  group('Retail Barcode Scanner Formats Validation', () {
    test('Recognizes ITF / Interleaved 2 of 5 retail barcodes', () {
      expect(BarcodeValidator.validate('12345678901234').isSuccess, isTrue);
      expect(BarcodeValidator.detectType('12345678901234'), BarcodeType.code39);
    });

    test('Normalizes camera scanned raw barcode strings', () {
      expect(BarcodeValidator.normalize(' 8901030383742 \n'), '8901030383742');
      expect(BarcodeValidator.normalize('ean-13_sample '), 'EAN-13_SAMPLE');
    });
  });
}
