import 'package:pdf/pdf.dart';
import '../../../../features/products/domain/models/product_model.dart';

/// Available physical label formats
enum BarcodeLabelTemplate {
  roll50x25,
  roll38x25,
  roll58x40,
  sheet24A4,
  sheet48A4,
  sheet65A4;

  String get label {
    switch (this) {
      case BarcodeLabelTemplate.roll50x25:
        return 'Roll (50 × 25 mm)';
      case BarcodeLabelTemplate.roll38x25:
        return 'Roll (38 × 25 mm)';
      case BarcodeLabelTemplate.roll58x40:
        return 'Roll (58 × 40 mm)';
      case BarcodeLabelTemplate.sheet24A4:
        return 'A4 Sheet (24 labels • 3×8)';
      case BarcodeLabelTemplate.sheet48A4:
        return 'A4 Sheet (48 labels • 4×12)';
      case BarcodeLabelTemplate.sheet65A4:
        return 'A4 Sheet (65 labels • 5×13)';
    }
  }

  bool get isRoll =>
      this == BarcodeLabelTemplate.roll50x25 ||
      this == BarcodeLabelTemplate.roll38x25 ||
      this == BarcodeLabelTemplate.roll58x40;

  int get columns {
    switch (this) {
      case BarcodeLabelTemplate.roll50x25:
      case BarcodeLabelTemplate.roll38x25:
      case BarcodeLabelTemplate.roll58x40:
        return 1;
      case BarcodeLabelTemplate.sheet24A4:
        return 3;
      case BarcodeLabelTemplate.sheet48A4:
        return 4;
      case BarcodeLabelTemplate.sheet65A4:
        return 5;
    }
  }

  int get rows {
    switch (this) {
      case BarcodeLabelTemplate.roll50x25:
      case BarcodeLabelTemplate.roll38x25:
      case BarcodeLabelTemplate.roll58x40:
        return 1;
      case BarcodeLabelTemplate.sheet24A4:
        return 8;
      case BarcodeLabelTemplate.sheet48A4:
        return 12;
      case BarcodeLabelTemplate.sheet65A4:
        return 13;
    }
  }

  double get labelWidthMm {
    switch (this) {
      case BarcodeLabelTemplate.roll50x25:
        return 50.0;
      case BarcodeLabelTemplate.roll38x25:
        return 38.0;
      case BarcodeLabelTemplate.roll58x40:
        return 58.0;
      case BarcodeLabelTemplate.sheet24A4:
        return 66.0; // 3 columns on ~210mm A4
      case BarcodeLabelTemplate.sheet48A4:
        return 48.5; // 4 columns on ~210mm A4
      case BarcodeLabelTemplate.sheet65A4:
        return 38.1; // 5 columns on ~210mm A4
    }
  }

  double get labelHeightMm {
    switch (this) {
      case BarcodeLabelTemplate.roll50x25:
        return 25.0;
      case BarcodeLabelTemplate.roll38x25:
        return 25.0;
      case BarcodeLabelTemplate.roll58x40:
        return 40.0;
      case BarcodeLabelTemplate.sheet24A4:
        return 33.8; // 8 rows on ~297mm A4
      case BarcodeLabelTemplate.sheet48A4:
        return 22.0; // 12 rows on ~297mm A4
      case BarcodeLabelTemplate.sheet65A4:
        return 21.2; // 13 rows on ~297mm A4
    }
  }

  PdfPageFormat get pageFormat {
    if (isRoll) {
      return PdfPageFormat(
        labelWidthMm * PdfPageFormat.mm,
        labelHeightMm * PdfPageFormat.mm,
        marginAll: 1 * PdfPageFormat.mm,
      );
    }
    return PdfPageFormat.a4;
  }
}

/// Item in the batch label generation queue
class BarcodeLabelBatchItem {
  final ProductModel product;
  final String barcode;
  final int quantity; // Number of labels to print
  final int? overridePricePaise;
  final String? batchNumber;
  final DateTime? packedDate;
  final DateTime? expiryDate;

  const BarcodeLabelBatchItem({
    required this.product,
    required this.barcode,
    this.quantity = 1,
    this.overridePricePaise,
    this.batchNumber,
    this.packedDate,
    this.expiryDate,
  });

  int get effectiveSellingPricePaise =>
      overridePricePaise ?? product.sellingPricePaise;

  BarcodeLabelBatchItem copyWith({
    ProductModel? product,
    String? barcode,
    int? quantity,
    int? overridePricePaise,
    String? batchNumber,
    DateTime? packedDate,
    DateTime? expiryDate,
  }) {
    return BarcodeLabelBatchItem(
      product: product ?? this.product,
      barcode: barcode ?? this.barcode,
      quantity: quantity ?? this.quantity,
      overridePricePaise: overridePricePaise ?? this.overridePricePaise,
      batchNumber: batchNumber ?? this.batchNumber,
      packedDate: packedDate ?? this.packedDate,
      expiryDate: expiryDate ?? this.expiryDate,
    );
  }
}

/// Configuration toggles for barcode label presentation
class BarcodeLabelConfig {
  final bool includeShopName;
  final bool includePrice;
  final bool includeMrp;
  final bool includePackedDate;
  final bool includeExpiryDate;
  final bool includeBatchNumber;
  final String customShopHeader;

  const BarcodeLabelConfig({
    this.includeShopName = true,
    this.includePrice = true,
    this.includeMrp = true,
    this.includePackedDate = true,
    this.includeExpiryDate = false,
    this.includeBatchNumber = false,
    this.customShopHeader = '',
  });

  BarcodeLabelConfig copyWith({
    bool? includeShopName,
    bool? includePrice,
    bool? includeMrp,
    bool? includePackedDate,
    bool? includeExpiryDate,
    bool? includeBatchNumber,
    String? customShopHeader,
  }) {
    return BarcodeLabelConfig(
      includeShopName: includeShopName ?? this.includeShopName,
      includePrice: includePrice ?? this.includePrice,
      includeMrp: includeMrp ?? this.includeMrp,
      includePackedDate: includePackedDate ?? this.includePackedDate,
      includeExpiryDate: includeExpiryDate ?? this.includeExpiryDate,
      includeBatchNumber: includeBatchNumber ?? this.includeBatchNumber,
      customShopHeader: customShopHeader ?? this.customShopHeader,
    );
  }
}
