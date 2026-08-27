import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../billing/domain/models/bill_model.dart';
import '../../../settings/domain/models/shop_settings_model.dart';

class PdfReceiptService {
  Future<Uint8List> generateReceiptPdf({
    required BillModel bill,
    ShopSettingsModel? shopSettings,
    Uint8List? logoBytes,
    String? shopName,
    String? shopPhone,
    String? shopAddress,
  }) async {
    final pdf = pw.Document();

    final name = shopSettings?.shopName ?? shopName ?? 'KIRANA STORE';
    final address = shopSettings?.address ?? shopAddress ?? '';
    final phone = shopSettings?.phone ?? shopPhone ?? '';
    final gstin = shopSettings?.gstin;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // 1. Header Section
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      name.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    if (address.isNotEmpty)
                      pw.Text(address,
                          style: const pw.TextStyle(
                              fontSize: 10, color: PdfColors.grey800)),
                    if (phone.isNotEmpty)
                      pw.Text('Ph: $phone',
                          style: const pw.TextStyle(
                              fontSize: 10, color: PdfColors.grey800)),
                    if (gstin != null && gstin.isNotEmpty)
                      pw.Text('GSTIN: $gstin',
                          style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey900)),
                  ],
                ),
                if (logoBytes != null && logoBytes.isNotEmpty)
                  pw.Container(
                    width: 60,
                    height: 60,
                    child: pw.Image(pw.MemoryImage(logoBytes)),
                  )
                else
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue100,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      'TAX INVOICE',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                  ),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Divider(thickness: 1, color: PdfColors.grey400),
            pw.SizedBox(height: 8),

            // 2. Bill & Customer Metadata
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Bill No: ${bill.billNumber}',
                      style: pw.TextStyle(
                          fontSize: 12, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'Date: ${_formatDate(bill.createdAt)}',
                      style: const pw.TextStyle(
                          fontSize: 10, color: PdfColors.grey700),
                    ),
                  ],
                ),
                if (bill.hasCustomer)
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Customer: ${bill.customerName}',
                        style: pw.TextStyle(
                            fontSize: 11, fontWeight: pw.FontWeight.bold),
                      ),
                      if (bill.customerPhone != null &&
                          bill.customerPhone!.isNotEmpty)
                        pw.Text(
                          'Phone: ${bill.customerPhone}',
                          style: const pw.TextStyle(
                              fontSize: 10, color: PdfColors.grey700),
                        ),
                    ],
                  ),
              ],
            ),
            pw.SizedBox(height: 16),

            // 3. Itemized Table
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue50),
              headerHeight: 24,
              cellHeight: 20,
              headerStyle:
                  pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headers: <String>['#', 'Item Name', 'Qty', 'Unit Price', 'Total'],
              data: List<List<String>>.generate(bill.items.length, (index) {
                final item = bill.items[index];
                final qtyStr = item.quantity % 1 == 0
                    ? item.quantity.toInt().toString()
                    : item.quantity.toStringAsFixed(2);
                return [
                  (index + 1).toString(),
                  item.productName,
                  '$qtyStr ${item.unit}',
                  'Rs. ${(item.unitPricePaise / 100.0).toStringAsFixed(2)}',
                  'Rs. ${(item.totalPaise / 100.0).toStringAsFixed(2)}',
                ];
              }),
              columnWidths: {
                0: const pw.FixedColumnWidth(25),
                1: const pw.FlexColumnWidth(4),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(2),
                4: const pw.FlexColumnWidth(2),
              },
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.center,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerRight,
              },
            ),
            pw.SizedBox(height: 16),

            // 4. Totals Summary
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  width: 200,
                  child: pw.Column(
                    children: [
                      _buildPdfSummaryRow(
                        'Subtotal:',
                        'Rs. ${(bill.subtotalPaise / 100.0).toStringAsFixed(2)}',
                      ),
                      if (bill.discountPaise > 0)
                        _buildPdfSummaryRow(
                          'Discount:',
                          '- Rs. ${(bill.discountPaise / 100.0).toStringAsFixed(2)}',
                          color: PdfColors.red700,
                        ),
                      if (bill.taxTotalPaise > 0)
                        _buildPdfSummaryRow(
                          'Tax:',
                          'Rs. ${(bill.taxTotalPaise / 100.0).toStringAsFixed(2)}',
                        ),
                      pw.Divider(thickness: 1, color: PdfColors.grey400),
                      _buildPdfSummaryRow(
                        'GRAND TOTAL:',
                        'Rs. ${(bill.totalPaise / 100.0).toStringAsFixed(2)}',
                        isBold: true,
                        fontSize: 14,
                        color: PdfColors.blue900,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 24),

            // 5. Payment Details & Footer
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Payment Status: ${bill.paymentStatus.toUpperCase()}',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green800,
                    ),
                  ),
                  pw.Text(
                    'Thank you for shopping with us!',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontStyle: pw.FontStyle.italic,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildPdfSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 10,
    PdfColor? color,
  }) {
    final style = pw.TextStyle(
      fontSize: fontSize,
      fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
      color: color ?? PdfColors.black,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(value, style: style),
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

final pdfReceiptServiceProvider = Provider<PdfReceiptService>((ref) {
  return PdfReceiptService();
});
