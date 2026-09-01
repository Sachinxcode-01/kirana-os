import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../features/settings/domain/models/shop_settings_model.dart';
import '../models/barcode_label_models.dart';

final barcodeLabelPdfBuilderProvider = Provider<BarcodeLabelPdfBuilder>((ref) {
  return BarcodeLabelPdfBuilder();
});

class BarcodeLabelPdfBuilder {
  static String _formatRupees(int paise) {
    final double rupees = paise / 100.0;
    return '₹${rupees.toStringAsFixed(2)}';
  }

  /// Builds printable PDF containing all batch label items
  Future<Uint8List> buildLabelPdf({
    required List<BarcodeLabelBatchItem> batchItems,
    required BarcodeLabelTemplate template,
    required BarcodeLabelConfig config,
    ShopSettingsModel? shopSettings,
  }) async {
    final doc = pw.Document();

    final shopName = config.customShopHeader.trim().isNotEmpty
        ? config.customShopHeader.trim()
        : (shopSettings?.shopName ?? 'KIRANA STORE');

    // Flatten batch items by their quantity into individual labels
    final List<BarcodeLabelBatchItem> flatLabels = [];
    for (final item in batchItems) {
      for (int i = 0; i < item.quantity; i++) {
        flatLabels.add(item);
      }
    }

    if (flatLabels.isEmpty) {
      // Empty document fallback
      doc.addPage(
        pw.Page(
          pageFormat: template.pageFormat,
          build: (context) => pw.Center(
            child: pw.Text(
              'No labels to print',
              style: const pw.TextStyle(fontSize: 12),
            ),
          ),
        ),
      );
      return doc.save();
    }

    if (template.isRoll) {
      // Roll mode: 1 Page = 1 Label sticker
      for (final labelItem in flatLabels) {
        doc.addPage(
          pw.Page(
            pageFormat: template.pageFormat,
            margin: const pw.EdgeInsets.all(2 * PdfPageFormat.mm),
            build: (context) {
              return _buildSingleLabelContent(
                labelItem: labelItem,
                template: template,
                config: config,
                shopName: shopName,
              );
            },
          ),
        );
      }
    } else {
      // Sheet mode: Multiple labels arranged on A4 grid
      final labelsPerPage = template.columns * template.rows;
      final totalPages = (flatLabels.length / labelsPerPage).ceil();

      for (int pageIdx = 0; pageIdx < totalPages; pageIdx++) {
        final startIdx = pageIdx * labelsPerPage;
        final endIdx = (startIdx + labelsPerPage > flatLabels.length)
            ? flatLabels.length
            : startIdx + labelsPerPage;
        final pageSlice = flatLabels.sublist(startIdx, endIdx);

        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(6 * PdfPageFormat.mm),
            build: (context) {
              return _buildA4GridPage(
                labels: pageSlice,
                template: template,
                config: config,
                shopName: shopName,
              );
            },
          ),
        );
      }
    }

    return doc.save();
  }

  /// Builds single label widget
  pw.Widget _buildSingleLabelContent({
    required BarcodeLabelBatchItem labelItem,
    required BarcodeLabelTemplate template,
    required BarcodeLabelConfig config,
    required String shopName,
  }) {
    final product = labelItem.product;
    final barcode = labelItem.barcode.trim();
    final isEan13 = barcode.length == 13 && RegExp(r'^\d{13}$').hasMatch(barcode);

    // Font size scaling based on label format
    final double shopFontSize = template == BarcodeLabelTemplate.roll38x25 ? 6.5 : 7.5;
    final double titleFontSize = template == BarcodeLabelTemplate.roll38x25 ? 7.0 : 8.5;
    final double priceFontSize = template == BarcodeLabelTemplate.roll38x25 ? 8.5 : 10.0;
    final double barcodeHeight = template == BarcodeLabelTemplate.roll38x25
        ? 14 * PdfPageFormat.mm
        : (template == BarcodeLabelTemplate.roll58x40
            ? 22 * PdfPageFormat.mm
            : 16 * PdfPageFormat.mm);

    return pw.Container(
      alignment: pw.Alignment.center,
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // Shop Header
          if (config.includeShopName && shopName.isNotEmpty)
            pw.Text(
              shopName.toUpperCase(),
              style: pw.TextStyle(
                fontSize: shopFontSize,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
              maxLines: 1,
              overflow: pw.TextOverflow.clip,
            ),

          // Product Name & Unit
          pw.Text(
            '${product.name} (${product.unit})',
            style: pw.TextStyle(
              fontSize: titleFontSize,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
            textAlign: pw.TextAlign.center,
            maxLines: 1,
            overflow: pw.TextOverflow.clip,
          ),

          // Barcode Lines & Digits
          pw.SizedBox(
            height: barcodeHeight,
            width: double.infinity,
            child: isEan13
                ? pw.BarcodeWidget(
                    barcode: pw.Barcode.ean13(),
                    data: barcode,
                    drawText: true,
                    textStyle: const pw.TextStyle(fontSize: 6.5),
                  )
                : pw.BarcodeWidget(
                    barcode: pw.Barcode.code128(),
                    data: barcode.isEmpty ? 'KIRANA' : barcode,
                    drawText: true,
                    textStyle: const pw.TextStyle(fontSize: 6.5),
                  ),
          ),

          // Price Row (Selling Price + MRP)
          if (config.includePrice)
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (config.includeMrp &&
                    product.mrpPaise > labelItem.effectiveSellingPricePaise) ...[
                  pw.Text(
                    'MRP ${_formatRupees(product.mrpPaise)} ',
                    style: const pw.TextStyle(
                      fontSize: 6.5,
                      decoration: pw.TextDecoration.lineThrough,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(width: 3),
                ],
                pw.Text(
                  'OUR PRICE: ${_formatRupees(labelItem.effectiveSellingPricePaise)}',
                  style: pw.TextStyle(
                    fontSize: priceFontSize,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
              ],
            ),

          // Dates / Batch Info Row
          if (config.includePackedDate || config.includeExpiryDate)
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                if (config.includePackedDate && labelItem.packedDate != null)
                  pw.Text(
                    'PKD: ${_formatDate(labelItem.packedDate!)}',
                    style: const pw.TextStyle(fontSize: 5.5, color: PdfColors.grey800),
                  ),
                if (config.includeExpiryDate && labelItem.expiryDate != null)
                  pw.Text(
                    'EXP: ${_formatDate(labelItem.expiryDate!)}',
                    style: const pw.TextStyle(fontSize: 5.5, color: PdfColors.grey800),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  /// Builds A4 Sheet Grid Layout
  pw.Widget _buildA4GridPage({
    required List<BarcodeLabelBatchItem> labels,
    required BarcodeLabelTemplate template,
    required BarcodeLabelConfig config,
    required String shopName,
  }) {
    final cols = template.columns;
    final rows = template.rows;

    final List<pw.TableRow> tableRows = [];
    int labelPointer = 0;

    for (int r = 0; r < rows; r++) {
      final List<pw.Widget> rowCells = [];
      for (int c = 0; c < cols; c++) {
        if (labelPointer < labels.length) {
          final item = labels[labelPointer];
          rowCells.add(
            pw.Container(
              padding: const pw.EdgeInsets.all(1.5 * PdfPageFormat.mm),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
              ),
              child: _buildSingleLabelContent(
                labelItem: item,
                template: template,
                config: config,
                shopName: shopName,
              ),
            ),
          );
          labelPointer++;
        } else {
          // Empty placeholder cell
          rowCells.add(
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey200, width: 0.2),
              ),
            ),
          );
        }
      }
      tableRows.add(pw.TableRow(children: rowCells));
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      children: tableRows,
    );
  }

  static String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year.toString().substring(2)}';
  }
}
