import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_mobile/features/barcodes/domain/models/barcode_label_models.dart';
import 'package:kirana_mobile/features/barcodes/domain/services/barcode_label_pdf_builder.dart';
import 'package:kirana_mobile/features/products/domain/models/product_model.dart';
import 'package:kirana_mobile/features/settings/domain/models/shop_settings_model.dart';

void main() {
  late BarcodeLabelPdfBuilder pdfBuilder;

  final sampleProduct1 = ProductModel(
    id: 'prod-101',
    shopId: 'shop-1',
    name: 'Tata Sampann Toor Dal',
    unit: 'KG',
    sellingPricePaise: 16500, // ₹165.00
    mrpPaise: 19000, // ₹190.00
    barcode: '8901030383458',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final sampleProduct2 = ProductModel(
    id: 'prod-102',
    shopId: 'shop-1',
    name: 'Loose Premium Sugar',
    unit: 'KG',
    sellingPricePaise: 4400, // ₹44.00
    mrpPaise: 5000,
    barcode: null, // loose un-barcoded item
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final sampleShopSettings = const ShopSettingsModel(
    shopId: 'shop-1',
    shopName: 'Gupta Kirana & General Store',
    address: 'Shop 4, Main Market, Delhi',
    phone: '9876543210',
  );

  setUp(() {
    pdfBuilder = BarcodeLabelPdfBuilder();
  });

  group('BarcodeLabelPdfBuilder Tests', () {
    test('Builds valid PDF bytes for Roll 50x25 template', () async {
      final batchItems = [
        BarcodeLabelBatchItem(
          product: sampleProduct1,
          barcode: sampleProduct1.barcode!,
          quantity: 2,
          packedDate: DateTime(2026, 9, 1),
        ),
        BarcodeLabelBatchItem(
          product: sampleProduct2,
          barcode: '200000001024',
          quantity: 3,
          packedDate: DateTime(2026, 9, 1),
        ),
      ];

      final pdfBytes = await pdfBuilder.buildLabelPdf(
        batchItems: batchItems,
        template: BarcodeLabelTemplate.roll50x25,
        config: const BarcodeLabelConfig(),
        shopSettings: sampleShopSettings,
      );

      expect(pdfBytes, isNotEmpty);
      // Verify standard PDF header magic bytes "%PDF-"
      final header = ascii.decode(pdfBytes.sublist(0, 5));
      expect(header, '%PDF-');
    });

    test('Builds valid PDF bytes for A4 Sheet 24-up grid template', () async {
      final batchItems = [
        BarcodeLabelBatchItem(
          product: sampleProduct1,
          barcode: sampleProduct1.barcode!,
          quantity: 28, // Spans across 2 pages (24 per page)
          packedDate: DateTime(2026, 9, 1),
        ),
      ];

      final pdfBytes = await pdfBuilder.buildLabelPdf(
        batchItems: batchItems,
        template: BarcodeLabelTemplate.sheet24A4,
        config: const BarcodeLabelConfig(
          includeShopName: true,
          includePrice: true,
          includeMrp: true,
          includePackedDate: true,
        ),
        shopSettings: sampleShopSettings,
      );

      expect(pdfBytes, isNotEmpty);
      final header = ascii.decode(pdfBytes.sublist(0, 5));
      expect(header, '%PDF-');
    });

    test('Handles empty batch items gracefully with placeholder page', () async {
      final pdfBytes = await pdfBuilder.buildLabelPdf(
        batchItems: [],
        template: BarcodeLabelTemplate.roll38x25,
        config: const BarcodeLabelConfig(),
      );

      expect(pdfBytes, isNotEmpty);
      final header = ascii.decode(pdfBytes.sublist(0, 5));
      expect(header, '%PDF-');
    });
  });
}
