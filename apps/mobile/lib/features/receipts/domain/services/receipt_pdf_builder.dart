import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../billing/domain/models/bill_model.dart';
import '../../../settings/domain/models/shop_settings_model.dart';
import '../models/printer_device_model.dart';

final receiptPdfBuilderProvider = Provider<ReceiptPdfBuilder>((ref) {
  return ReceiptPdfBuilder();
});

class ReceiptPdfBuilder {
  static PdfPageFormat pageFormatToPdfFormat(PrinterPageFormat format) {
    switch (format) {
      case PrinterPageFormat.a4:
        return PdfPageFormat.a4;
      case PrinterPageFormat.roll58mm:
        // 58mm roll width, dynamic height
        return const PdfPageFormat(
          58 * PdfPageFormat.mm,
          200 * PdfPageFormat.mm,
        );
      case PrinterPageFormat.roll80mm:
        // 80mm roll width, dynamic height
        return const PdfPageFormat(
          80 * PdfPageFormat.mm,
          200 * PdfPageFormat.mm,
        );
    }
  }

  Future<Uint8List> buildReceiptPdf({
    required BillModel bill,
    ShopSettingsModel? shopSettings,
    required PrinterDeviceModel printerSettings,
  }) async {
    final doc = pw.Document();

    final isColor = printerSettings.isColor;
    final pageFormat = pageFormatToPdfFormat(printerSettings.pageFormat);
    final isRoll = printerSettings.pageFormat != PrinterPageFormat.a4;

    // Color scheme
    final primaryColor =
        isColor ? PdfColor.fromHex('#1B6CA8') : PdfColors.black;
    final accentColor =
        isColor ? PdfColor.fromHex('#2196F3') : PdfColors.grey700;
    final bgColor = isColor ? PdfColor.fromHex('#EBF5FB') : PdfColors.grey200;
    final mutedColor = PdfColors.grey600;

    final shopName = shopSettings?.shopName ?? 'KIRANA STORE';
    final shopAddress = shopSettings?.address ?? '';
    final shopPhone = shopSettings?.phone ?? '';
    final gstin = shopSettings?.gstin ?? '';

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.all(isRoll ? 6 : 20),
        build: (ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // ---- HEADER ----
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 8),
                decoration: pw.BoxDecoration(
                  color: bgColor,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      shopName.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: isRoll ? 11 : 16,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    if (shopAddress.isNotEmpty)
                      pw.Text(
                        shopAddress,
                        style: pw.TextStyle(
                            fontSize: isRoll ? 7 : 10, color: mutedColor),
                        textAlign: pw.TextAlign.center,
                      ),
                    if (shopPhone.isNotEmpty)
                      pw.Text(
                        'Ph: $shopPhone',
                        style: pw.TextStyle(
                            fontSize: isRoll ? 7 : 10, color: mutedColor),
                        textAlign: pw.TextAlign.center,
                      ),
                    if (gstin.isNotEmpty)
                      pw.Text(
                        'GSTIN: $gstin',
                        style: pw.TextStyle(
                            fontSize: isRoll ? 7 : 9,
                            color: mutedColor,
                            fontStyle: pw.FontStyle.italic),
                        textAlign: pw.TextAlign.center,
                      ),
                  ],
                ),
              ),

              pw.SizedBox(height: 6),
              pw.Divider(color: accentColor, thickness: 1),
              pw.SizedBox(height: 4),

              // ---- BILL INFO ----
              _infoRow('Bill No:', bill.billNumber,
                  fontSize: isRoll ? 7.5 : 10),
              _infoRow('Date:', _formatDate(bill.createdAt),
                  fontSize: isRoll ? 7.5 : 10),
              if (bill.hasCustomer && bill.customerName != null)
                _infoRow('Customer:', bill.customerName!,
                    fontSize: isRoll ? 7.5 : 10),
              if (bill.hasCustomer && bill.customerPhone != null)
                _infoRow('Phone:', bill.customerPhone!,
                    fontSize: isRoll ? 7.5 : 10),

              pw.SizedBox(height: 4),
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 4),

              // ---- TABLE HEADER ----
              _tableHeader(isRoll: isRoll, primaryColor: primaryColor),
              pw.Divider(color: PdfColors.grey400),

              // ---- ITEMS ----
              ...bill.items.map((item) {
                final qtyStr = item.quantity % 1 == 0
                    ? item.quantity.toInt().toString()
                    : item.quantity.toStringAsFixed(2);
                final price = (item.unitPricePaise / 100).toStringAsFixed(2);
                final total = (item.totalPaise / 100).toStringAsFixed(2);

                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: isRoll ? 3 : 4,
                        child: pw.Text(
                          item.productName,
                          style: pw.TextStyle(fontSize: isRoll ? 7.5 : 10),
                        ),
                      ),
                      pw.SizedBox(
                        width: isRoll ? 20 : 30,
                        child: pw.Text(
                          qtyStr,
                          style: pw.TextStyle(fontSize: isRoll ? 7.5 : 10),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      if (!isRoll)
                        pw.SizedBox(
                          width: 50,
                          child: pw.Text(
                            '₹$price',
                            style: pw.TextStyle(fontSize: 10),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      pw.SizedBox(
                        width: isRoll ? 36 : 50,
                        child: pw.Text(
                          '₹$total',
                          style: pw.TextStyle(
                            fontSize: isRoll ? 7.5 : 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              pw.Divider(thickness: 1.5, color: accentColor),
              pw.SizedBox(height: 4),

              // ---- TOTALS ----
              _totalRow('Subtotal',
                  '₹${(bill.subtotalPaise / 100).toStringAsFixed(2)}',
                  fontSize: isRoll ? 7.5 : 10),
              if (bill.discountPaise > 0)
                _totalRow('Discount',
                    '- ₹${(bill.discountPaise / 100).toStringAsFixed(2)}',
                    fontSize: isRoll ? 7.5 : 10, valueColor: PdfColors.red700),
              if (bill.taxTotalPaise > 0)
                _totalRow(
                    'Tax', '₹${(bill.taxTotalPaise / 100).toStringAsFixed(2)}',
                    fontSize: isRoll ? 7.5 : 10),

              pw.SizedBox(height: 2),
              pw.Divider(thickness: 2, color: primaryColor),

              // Grand total row
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'GRAND TOTAL',
                    style: pw.TextStyle(
                      fontSize: isRoll ? 9 : 13,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  pw.Text(
                    '₹${(bill.totalPaise / 100).toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: isRoll ? 10 : 14,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
              pw.Divider(thickness: 2, color: primaryColor),
              pw.SizedBox(height: 4),

              // Payment status badge
              pw.Center(
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: bill.paymentStatus == 'paid'
                        ? (isColor
                            ? PdfColor.fromHex('#E8F5E9')
                            : PdfColors.grey200)
                        : (isColor
                            ? PdfColor.fromHex('#FBE9E7')
                            : PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(20),
                  ),
                  child: pw.Text(
                    bill.paymentStatus == 'paid' ? '✓ PAID' : '⚠ UNPAID',
                    style: pw.TextStyle(
                      fontSize: isRoll ? 8 : 11,
                      fontWeight: pw.FontWeight.bold,
                      color: bill.paymentStatus == 'paid'
                          ? (isColor
                              ? PdfColor.fromHex('#2E7D32')
                              : PdfColors.black)
                          : (isColor
                              ? PdfColor.fromHex('#BF360C')
                              : PdfColors.grey800),
                    ),
                  ),
                ),
              ),

              pw.SizedBox(height: 8),
              pw.Divider(color: PdfColors.grey300),

              // Footer
              pw.Center(
                child: pw.Text(
                  'Thank you for shopping!',
                  style: pw.TextStyle(
                    fontSize: isRoll ? 7.5 : 10,
                    color: mutedColor,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'Powered by KiranaOS',
                  style: pw.TextStyle(
                    fontSize: isRoll ? 6 : 8,
                    color: PdfColors.grey400,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  Future<Uint8List> buildTestPagePdf({
    required PrinterDeviceModel printer,
  }) async {
    final doc = pw.Document();
    final pageFormat = pageFormatToPdfFormat(printer.pageFormat);
    final isRoll = printer.pageFormat != PrinterPageFormat.a4;
    final primaryColor =
        printer.isColor ? PdfColor.fromHex('#1B6CA8') : PdfColors.black;
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.all(isRoll ? 6 : 20),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Center(
              child: pw.Text(
                'KIRANA OS',
                style: pw.TextStyle(
                    fontSize: isRoll ? 12 : 18,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryColor),
              ),
            ),
            pw.Center(
              child: pw.Text(
                'TEST PAGE',
                style: pw.TextStyle(
                    fontSize: isRoll ? 8 : 12,
                    color: printer.isColor
                        ? PdfColor.fromHex('#2196F3')
                        : PdfColors.grey700),
              ),
            ),
            pw.Divider(thickness: 2, color: primaryColor),
            pw.SizedBox(height: 8),
            _infoRow('Printer:', printer.name, fontSize: isRoll ? 7.5 : 10),
            _infoRow('Connection:', printer.connectionType.toUpperCase(),
                fontSize: isRoll ? 7.5 : 10),
            _infoRow('Paper:', printer.pageFormat.label,
                fontSize: isRoll ? 7.5 : 10),
            _infoRow('Color Mode:', printer.isColor ? 'COLOR' : 'BLACK & WHITE',
                fontSize: isRoll ? 7.5 : 10),
            _infoRow('IP / URL:', printer.url ?? printer.address,
                fontSize: isRoll ? 7.5 : 10),
            _infoRow('Date/Time:', dateStr, fontSize: isRoll ? 7.5 : 10),
            pw.SizedBox(height: 8),
            pw.Divider(thickness: 1.5, color: primaryColor),
            pw.Center(
              child: pw.Text(
                'CONNECTION OK ✓',
                style: pw.TextStyle(
                    fontSize: isRoll ? 9 : 12,
                    fontWeight: pw.FontWeight.bold,
                    color: printer.isColor
                        ? PdfColor.fromHex('#2E7D32')
                        : PdfColors.black),
              ),
            ),
            pw.Divider(thickness: 1.5, color: primaryColor),
          ],
        ),
      ),
    );

    return doc.save();
  }

  pw.Widget _tableHeader(
      {required bool isRoll, required PdfColor primaryColor}) {
    return pw.Row(
      children: [
        pw.Expanded(
          flex: isRoll ? 3 : 4,
          child: pw.Text('ITEM',
              style: pw.TextStyle(
                  fontSize: isRoll ? 7.5 : 9,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor)),
        ),
        pw.SizedBox(
          width: isRoll ? 20 : 30,
          child: pw.Text('QTY',
              style: pw.TextStyle(
                  fontSize: isRoll ? 7.5 : 9,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor),
              textAlign: pw.TextAlign.right),
        ),
        if (!isRoll)
          pw.SizedBox(
            width: 50,
            child: pw.Text('PRICE',
                style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryColor),
                textAlign: pw.TextAlign.right),
          ),
        pw.SizedBox(
          width: isRoll ? 36 : 50,
          child: pw.Text('TOTAL',
              style: pw.TextStyle(
                  fontSize: isRoll ? 7.5 : 9,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor),
              textAlign: pw.TextAlign.right),
        ),
      ],
    );
  }

  pw.Widget _infoRow(String label, String value, {double fontSize = 10}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 65,
            child: pw.Text(label,
                style:
                    pw.TextStyle(fontSize: fontSize, color: PdfColors.grey700)),
          ),
          pw.Expanded(
            child: pw.Text(value,
                style: pw.TextStyle(
                    fontSize: fontSize, fontWeight: pw.FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  pw.Widget _totalRow(String label, String value,
      {double fontSize = 10, PdfColor? valueColor}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style:
                  pw.TextStyle(fontSize: fontSize, color: PdfColors.grey700)),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: fontSize,
                  fontWeight: pw.FontWeight.bold,
                  color: valueColor)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $hh:$mm';
  }
}
