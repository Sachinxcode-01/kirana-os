import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../billing/domain/models/bill_model.dart';
import '../../../settings/domain/models/shop_settings_model.dart';
import 'receipt_formatter_service.dart';

class ShareReceiptService {
  final ReceiptFormatterService _formatterService;

  ShareReceiptService([ReceiptFormatterService? formatterService])
      : _formatterService = formatterService ?? ReceiptFormatterService();

  Future<bool> shareReceipt({
    required BillModel bill,
    ShopSettingsModel? shopSettings,
    String? shopName,
    String? shopPhone,
    String? shopAddress,
    String? paymentModeLabel,
  }) async {
    try {
      final text = _formatterService.formatShareableText(
        bill: bill,
        shopSettings: shopSettings,
        shopName: shopName,
        shopPhone: shopPhone,
        shopAddress: shopAddress,
        paymentModeLabel: paymentModeLabel,
      );

      final result = await Share.share(
        text,
        subject: 'Bill Receipt #${bill.billNumber}',
      );

      return result.status == ShareResultStatus.success;
    } catch (_) {
      // Graceful fallback for cancelled or non-supported platforms
      return false;
    }
  }
}

final shareReceiptServiceProvider = Provider<ShareReceiptService>((ref) {
  final formatter = ref.watch(receiptFormatterServiceProvider);
  return ShareReceiptService(formatter);
});
