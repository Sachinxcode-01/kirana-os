import '../../../../core/extensions/num_extensions.dart';
import '../../../billing/domain/models/bill_model.dart';
import '../../../settings/domain/models/shop_settings_model.dart';
import '../models/printer_device_model.dart';

class ReceiptFormatterService {
  String formatThermalReceipt({
    required BillModel bill,
    ShopSettingsModel? shopSettings,
    required PrinterPaperWidth paperWidth,
    String? shopName,
    String? shopPhone,
    String? shopAddress,
  }) {
    final cols = paperWidth.columns;
    final buffer = StringBuffer();

    final name = shopSettings?.shopName ?? shopName ?? 'KIRANA STORE';
    final address =
        shopSettings?.address ?? shopAddress ?? 'Main Road, Market Area';
    final phone = shopSettings?.phone ?? shopPhone ?? '';
    final gstin = shopSettings?.gstin;

    // 1. Header (Centered)
    buffer.writeln(_centerText(name.toUpperCase(), cols));
    if (address.isNotEmpty) {
      buffer.writeln(_centerText(address, cols));
    }
    if (phone.isNotEmpty) {
      buffer.writeln(_centerText('Ph: $phone', cols));
    }
    if (gstin != null && gstin.isNotEmpty) {
      buffer.writeln(_centerText('GSTIN: $gstin', cols));
    }
    buffer.writeln(_divider(cols, '-'));

    // 2. Bill Info
    buffer.writeln(_twoColumn('Bill No:', bill.billNumber, cols));
    buffer.writeln(_twoColumn('Date:', _formatDate(bill.createdAt), cols));
    if (bill.hasCustomer) {
      buffer.writeln(_twoColumn('Cust Name:', bill.customerName!, cols));
      if (bill.customerPhone != null) {
        buffer.writeln(_twoColumn('Cust Phone:', bill.customerPhone!, cols));
      }
    }
    buffer.writeln(_divider(cols, '-'));

    // 3. Item Table Header
    if (paperWidth == PrinterPaperWidth.mm58) {
      buffer.writeln(_threeColumn('Item', 'Qty', 'Amt', cols));
    } else {
      buffer.writeln(_fourColumn('Item Name', 'Qty', 'Price', 'Amount', cols));
    }
    buffer.writeln(_divider(cols, '-'));

    // 4. Line Items
    for (final item in bill.items) {
      final nameLines = _wrapText(
          item.productName, paperWidth == PrinterPaperWidth.mm58 ? 16 : 24);
      final qtyStr = item.quantity % 1 == 0
          ? item.quantity.toInt().toString()
          : item.quantity.toStringAsFixed(2);
      final priceStr = item.unitPricePaise.toRupeesString();
      final totalStr = item.totalPaise.toRupeesString();

      if (paperWidth == PrinterPaperWidth.mm58) {
        // Line 1: Name
        buffer.writeln(nameLines.first);
        for (int i = 1; i < nameLines.length; i++) {
          buffer.writeln('  ${nameLines[i]}');
        }
        // Line 2: Qty x Price ... Total
        buffer.writeln(_twoColumn('  $qtyStr x $priceStr', totalStr, cols));
      } else {
        // 80mm columns
        final firstLine = _fourColumn(
          nameLines.first,
          qtyStr,
          priceStr,
          totalStr,
          cols,
        );
        buffer.writeln(firstLine);
        for (int i = 1; i < nameLines.length; i++) {
          buffer.writeln('  ${nameLines[i]}');
        }
      }
    }

    buffer.writeln(_divider(cols, '='));

    // 5. Totals Breakdown
    buffer.writeln(
        _twoColumn('Subtotal:', bill.subtotalPaise.toRupeesString(), cols));

    if (bill.discountPaise > 0) {
      buffer.writeln(_twoColumn(
          'Discount:', '- ${bill.discountPaise.toRupeesString()}', cols));
    }

    if (bill.taxTotalPaise > 0) {
      buffer.writeln(
          _twoColumn('Tax:', bill.taxTotalPaise.toRupeesString(), cols));
    }

    buffer.writeln(_divider(cols, '-'));
    buffer.writeln(
        _twoColumn('GRAND TOTAL:', bill.totalPaise.toRupeesString(), cols));
    buffer.writeln(_divider(cols, '='));

    // 6. Payment & Footer
    final paymentMode = bill.paymentStatus == 'paid' ? 'PAID' : 'UNPAID';
    buffer.writeln(_twoColumn('Payment Status:', paymentMode, cols));

    buffer.writeln(_divider(cols, '-'));
    buffer.writeln(_centerText('Thank you for shopping!', cols));
    buffer.writeln(_centerText('Visit Again', cols));
    buffer.writeln('\n\n'); // Feed space

    return buffer.toString();
  }

  String _centerText(String text, int cols) {
    if (text.length >= cols) return text.substring(0, cols);
    final leftPadding = (cols - text.length) ~/ 2;
    return '${' ' * leftPadding}$text';
  }

  String _divider(int cols, String char) {
    return char * cols;
  }

  String _twoColumn(String left, String right, int cols) {
    final available = cols - right.length;
    if (left.length >= available) {
      left = left.substring(0, available - 1);
    }
    final padding = cols - left.length - right.length;
    return '$left${' ' * (padding > 0 ? padding : 1)}$right';
  }

  String _threeColumn(String col1, String col2, String col3, int cols) {
    final c1Width = 16;
    final c2Width = 6;
    final c3Width = cols - c1Width - c2Width;

    final c1 = col1.length > c1Width
        ? col1.substring(0, c1Width)
        : col1.padRight(c1Width);
    final c2 = col2.padLeft(c2Width);
    final c3 = col3.padLeft(c3Width);

    return '$c1$c2$c3';
  }

  String _fourColumn(
      String col1, String col2, String col3, String col4, int cols) {
    final c1Width = 24;
    final c2Width = 6;
    final c3Width = 9;
    final c4Width = cols - c1Width - c2Width - c3Width;

    final c1 = col1.length > c1Width
        ? col1.substring(0, c1Width)
        : col1.padRight(c1Width);
    final c2 = col2.padLeft(c2Width);
    final c3 = col3.padLeft(c3Width);
    final c4 = col4.padLeft(c4Width);

    return '$c1$c2$c3$c4';
  }

  List<String> _wrapText(String text, int width) {
    if (text.length <= width) return [text];
    final List<String> lines = [];
    var remaining = text;

    while (remaining.isNotEmpty) {
      if (remaining.length <= width) {
        lines.add(remaining);
        break;
      }
      var breakPoint = remaining.lastIndexOf(' ', width);
      if (breakPoint <= 0) breakPoint = width;
      lines.add(remaining.substring(0, breakPoint).trimRight());
      remaining = remaining.substring(breakPoint).trimLeft();
    }
    return lines;
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
