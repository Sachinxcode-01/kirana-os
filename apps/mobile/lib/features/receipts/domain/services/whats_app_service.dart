import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/extensions/num_extensions.dart';
import '../../../billing/domain/models/bill_model.dart';
import '../../../settings/domain/models/shop_settings_model.dart';

final whatsAppServiceProvider = Provider<WhatsAppService>((ref) {
  return WhatsAppService();
});

class WhatsAppService {
  /// Normalize phone number to international Indian format (e.g. '9876543210' -> '919876543210')
  static String normalizePhone(String rawPhone) {
    var digits = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) {
      digits = '91$digits';
    } else if (digits.length == 12 && digits.startsWith('91')) {
      // Already has country code
    } else if (digits.length > 10 && digits.startsWith('0')) {
      digits = '91${digits.substring(1)}';
    }
    return digits;
  }

  /// Create standard WhatsApp Web / Mobile Click-to-Chat URI
  static String createWhatsAppUrl({
    required String phone,
    required String message,
  }) {
    final cleanPhone = normalizePhone(phone);
    final encodedMsg = Uri.encodeComponent(message);
    return 'https://wa.me/$cleanPhone?text=$encodedMsg';
  }

  /// Build a dynamic UPI Payment URI
  static String createUpiPaymentUri({
    required String upiId,
    required String payeeName,
    required int amountPaise,
    String? note,
  }) {
    final double rupees = amountPaise / 100.0;
    final cleanUpi = upiId.trim();
    final cleanName = Uri.encodeComponent(payeeName.trim());
    final cleanNote = Uri.encodeComponent(note ?? 'Kirana Store Payment');
    final amountStr = rupees.toStringAsFixed(2);

    return 'upi://pay?pa=$cleanUpi&pn=$cleanName&am=$amountStr&cu=INR&tn=$cleanNote';
  }

  /// Format structured WhatsApp digital receipt message
  String formatReceiptMessage({
    required BillModel bill,
    ShopSettingsModel? shopSettings,
    String? paymentModeLabel,
    int? pointsEarned,
    int? totalLoyaltyBalance,
  }) {
    final buffer = StringBuffer();
    final shopName = shopSettings?.shopName ?? 'KIRANA STORE';
    final shopPhone = shopSettings?.phone ?? '';
    final gstin = shopSettings?.gstin ?? '';

    // Header
    buffer.writeln('🧾 *TAX INVOICE / RECEIPT*');
    buffer.writeln('*$shopName*');
    if (shopPhone.isNotEmpty) buffer.writeln('📞 Contact: $shopPhone');
    if (gstin.isNotEmpty) buffer.writeln('🏛️ GSTIN: $gstin');
    buffer.writeln('--------------------------------');

    // Bill metadata
    buffer.writeln('Invoice No: *#${bill.billNumber}*');
    buffer.writeln('Date: ${_formatDate(bill.createdAt)}');
    if (bill.hasCustomer) {
      buffer.writeln('Customer: ${bill.customerName}');
    }
    buffer.writeln('--------------------------------');

    // Items list
    buffer.writeln('*ITEMS ORDERED:*');
    for (int i = 0; i < bill.items.length; i++) {
      final item = bill.items[i];
      final qtyStr = item.quantity % 1 == 0
          ? item.quantity.toInt().toString()
          : item.quantity.toStringAsFixed(2);
      buffer.writeln(
        '${i + 1}. *${item.productName}*\n'
        '   $qtyStr ${item.unit} × ${item.unitPricePaise.toRupeesString()} = *${item.totalPaise.toRupeesString()}*',
      );
    }
    buffer.writeln('--------------------------------');

    // Bill totals
    buffer.writeln('Subtotal: ${bill.subtotalPaise.toRupeesString()}');
    if (bill.discountPaise > 0) {
      buffer.writeln('Discount: -${bill.discountPaise.toRupeesString()}');
    }
    if (bill.taxTotalPaise > 0) {
      buffer.writeln('GST Tax: ${bill.taxTotalPaise.toRupeesString()}');
    }
    buffer.writeln('💰 *GRAND TOTAL: ${bill.totalPaise.toRupeesString()}*');
    final mode = paymentModeLabel ??
        (bill.paymentStatus == 'paid' ? 'PAID' : 'UNPAID / UDHAAR');
    buffer.writeln('Payment Mode: *$mode*');

    // Loyalty Rewards
    if (pointsEarned != null && pointsEarned > 0) {
      buffer.writeln('--------------------------------');
      buffer.writeln('🎁 *Loyalty Rewards:*');
      buffer.writeln('• Points Earned Today: *+$pointsEarned pts*');
      if (totalLoyaltyBalance != null) {
        buffer.writeln('• Total Points Balance: *$totalLoyaltyBalance pts*');
      }
    }

    // Footer
    buffer.writeln('--------------------------------');
    buffer.writeln('🙏 _Thank you for shopping with us!_');

    return buffer.toString();
  }

  /// Format friendly Khata / Udhaar payment reminder message with UPI link
  String formatKhataReminderMessage({
    required String customerName,
    required int currentDebtPaise,
    ShopSettingsModel? shopSettings,
    String? upiId,
  }) {
    final buffer = StringBuffer();
    final shopName = shopSettings?.shopName ?? 'Kirana Store';
    final shopPhone = shopSettings?.phone ?? '';
    final effectiveUpi = upiId ?? shopSettings?.phone; // fallback to merchant phone if UPI is phone@upi

    buffer.writeln('Namaste *$customerName* ji, 🙏');
    buffer.writeln();
    buffer.writeln('This is a gentle payment reminder from *$shopName*.');
    buffer.writeln();
    buffer.writeln('📊 *Outstanding Khata Balance: ${currentDebtPaise.toRupeesString()}*');
    buffer.writeln();

    if (effectiveUpi != null && effectiveUpi.isNotEmpty) {
      final upiLink = createUpiPaymentUri(
        upiId: effectiveUpi,
        payeeName: shopName,
        amountPaise: currentDebtPaise,
        note: 'Khata payment to $shopName',
      );
      buffer.writeln('💳 *Pay instantly via UPI:*');
      buffer.writeln(upiLink);
      buffer.writeln();
    }

    if (shopPhone.isNotEmpty) {
      buffer.writeln('For any queries or balance clarification, please contact us at $shopPhone.');
    }
    buffer.writeln();
    buffer.writeln('Thank you for your continued trust!');

    return buffer.toString();
  }

  /// Share message directly via system share dialog
  Future<bool> shareMessage(String message, {String? subject}) async {
    try {
      final res = await Share.share(
        message,
        subject: subject ?? 'KiranaOS Notification',
      );
      return res.status == ShareResultStatus.success;
    } catch (_) {
      return false;
    }
  }

  static String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $hh:$mm';
  }
}
