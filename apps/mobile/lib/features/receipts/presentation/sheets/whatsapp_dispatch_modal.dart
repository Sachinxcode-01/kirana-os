import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/radius.dart';
import '../../../../core/theme/spacing.dart';
import '../../../billing/domain/models/bill_model.dart';
import '../../../settings/domain/models/shop_settings_model.dart';
import '../../domain/services/whats_app_service.dart';

/// Modal bottom sheet allowing cashier to instantly dispatch digital receipts
/// via WhatsApp to customer mobile or any walk-in contact number.
class WhatsAppDispatchModal extends ConsumerStatefulWidget {
  final BillModel bill;
  final ShopSettingsModel? shopSettings;

  const WhatsAppDispatchModal({
    super.key,
    required this.bill,
    this.shopSettings,
  });

  static Future<void> show(
    BuildContext context, {
    required BillModel bill,
    ShopSettingsModel? shopSettings,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => WhatsAppDispatchModal(
        bill: bill,
        shopSettings: shopSettings,
      ),
    );
  }

  @override
  ConsumerState<WhatsAppDispatchModal> createState() =>
      _WhatsAppDispatchModalState();
}

class _WhatsAppDispatchModalState extends ConsumerState<WhatsAppDispatchModal> {
  late TextEditingController _phoneController;
  bool _isSending = false;
  late String _formattedMessage;

  @override
  void initState() {
    super.initState();
    final initialPhone = widget.bill.customerPhone ?? '';
    _phoneController = TextEditingController(text: initialPhone);
    _generateReceiptText();
  }

  void _generateReceiptText() {
    final whatsAppService = ref.read(whatsAppServiceProvider);
    _formattedMessage = whatsAppService.formatReceiptMessage(
      bill: widget.bill,
      shopSettings: widget.shopSettings,
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSendWhatsApp() async {
    final rawPhone = _phoneController.text.trim();
    if (rawPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a 10-digit mobile number.'),
          backgroundColor: KiranaColors.error,
        ),
      );
      return;
    }

    final cleanDigits = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (cleanDigits.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 10-digit mobile number.'),
          backgroundColor: KiranaColors.error,
        ),
      );
      return;
    }

    setState(() => _isSending = true);
    HapticFeedback.mediumImpact();

    try {
      final whatsAppService = ref.read(whatsAppServiceProvider);
      final success = await whatsAppService.shareMessage(
        _formattedMessage,
        subject: 'Receipt #${widget.bill.billNumber}',
      );

      if (mounted) {
        setState(() => _isSending = false);
        Navigator.of(context).pop();
        if (success) {
          HapticFeedback.heavyImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invoice dispatched via WhatsApp.'),
              backgroundColor: KiranaColors.success,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _formattedMessage));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Receipt invoice text copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: KiranaColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        KiranaSpacing.xl,
        KiranaSpacing.md,
        KiranaSpacing.xl,
        MediaQuery.of(context).viewInsets.bottom + KiranaSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: KiranaColors.neutral300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: KiranaSpacing.md),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.chat,
                      color: Color(0xFF25D366),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: KiranaSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'WhatsApp Digital Invoice',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: KiranaColors.neutral900,
                        ),
                      ),
                      Text(
                        'Bill #${widget.bill.billNumber}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: KiranaColors.neutral500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: KiranaColors.neutral600),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Divider(height: KiranaSpacing.lg),

          // Phone Number Input with +91 Prefix
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            decoration: InputDecoration(
              labelText: 'Customer WhatsApp Mobile',
              hintText: '98765 43210',
              prefixIcon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                child: const Text(
                  '+91',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: KiranaColors.neutral700,
                  ),
                ),
              ),
              suffixIcon: _phoneController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() => _phoneController.clear()),
                    )
                  : null,
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: KiranaRadius.borderLg,
              ),
            ),
            onChanged: (val) => setState(() {}),
          ),
          const SizedBox(height: KiranaSpacing.md),

          // Collapsible Text Preview Card
          Container(
            padding: const EdgeInsets.all(KiranaSpacing.md),
            constraints: const BoxConstraints(maxHeight: 180),
            decoration: BoxDecoration(
              color: KiranaColors.surfaceVariant,
              borderRadius: KiranaRadius.borderLg,
              border: Border.all(color: KiranaColors.outlineVariant),
            ),
            child: SingleChildScrollView(
              child: Text(
                _formattedMessage,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  height: 1.35,
                  color: KiranaColors.neutral800,
                ),
              ),
            ),
          ).animate().fadeIn(duration: 200.ms),
          const SizedBox(height: KiranaSpacing.lg),

          // Actions Row
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _copyToClipboard,
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy Text'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(width: KiranaSpacing.sm),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: const RoundedRectangleBorder(
                      borderRadius: KiranaRadius.borderLg,
                    ),
                  ),
                  icon: _isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.send, size: 18),
                  label: Text(_isSending ? 'SENDING...' : 'SEND VIA WHATSAPP'),
                  onPressed: _isSending ? null : _handleSendWhatsApp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
