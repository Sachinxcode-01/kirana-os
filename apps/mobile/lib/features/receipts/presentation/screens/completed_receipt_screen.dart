import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/extensions/num_extensions.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../billing/domain/models/bill_model.dart';
import '../../../billing/presentation/providers/billing_provider.dart';
import '../../../settings/domain/models/shop_settings_model.dart';
import '../../../settings/presentation/providers/shop_settings_provider.dart';
import '../../domain/services/receipt_formatter_service.dart';
import '../../domain/services/share_receipt_service.dart';
import '../providers/printer_provider.dart';
import '../sheets/printer_selection_sheet.dart';
import 'pdf_receipt_preview_screen.dart';

class CompletedReceiptScreen extends ConsumerStatefulWidget {
  final BillModel bill;

  const CompletedReceiptScreen({super.key, required this.bill});

  @override
  ConsumerState<CompletedReceiptScreen> createState() =>
      _CompletedReceiptScreenState();
}

class _CompletedReceiptScreenState
    extends ConsumerState<CompletedReceiptScreen> {
  bool _showThermalText = false;
  bool _isSharing = false;

  void _showPrinterSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: KiranaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => const PrinterSelectionSheet(),
    );
  }

  Future<void> _handleShare(
      BuildContext context, ShopSettingsModel? shopSettings) async {
    setState(() => _isSharing = true);
    final messenger = ScaffoldMessenger.of(context);
    final shareService = ref.read(shareReceiptServiceProvider);

    final shared = await shareService.shareReceipt(
      bill: widget.bill,
      shopSettings: shopSettings,
    );

    if (mounted) {
      setState(() => _isSharing = false);
      if (shared) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Receipt shared successfully.'),
            backgroundColor: KiranaColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final printerState = ref.watch(printerNotifierProvider);
    final printerNotifier = ref.read(printerNotifierProvider.notifier);
    final formatterService = ref.watch(receiptFormatterServiceProvider);
    final shopSettings = ref.watch(shopSettingsNotifierProvider).settings;

    final receiptText = formatterService.formatThermalReceipt(
      bill: widget.bill,
      shopSettings: shopSettings,
      paperWidth: printerState.paperWidth,
    );

    final shopName = shopSettings?.shopName ?? 'KIRANA POS STORE';
    final shopAddress = shopSettings?.address ?? 'Main Road, Market Area';
    final shopPhone = shopSettings?.phone ?? '';
    final gstin = shopSettings?.gstin;

    return Scaffold(
      appBar: AppBar(
        title: Text('Receipt #${widget.bill.billNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'PDF Preview',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PdfReceiptPreviewScreen(bill: widget.bill),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(
              _showThermalText ? Icons.receipt_long : Icons.code,
            ),
            tooltip: _showThermalText ? 'Visual Receipt' : 'Thermal Preview',
            onPressed: () {
              setState(() => _showThermalText = !_showThermalText);
            },
          ),
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Printer Settings',
            onPressed: () => _showPrinterSettings(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Printer Status / Error Banners
          if (printerState.errorMessage != null)
            Container(
              margin: const EdgeInsets.all(KiranaSpacing.md),
              padding: const EdgeInsets.all(KiranaSpacing.md),
              decoration: BoxDecoration(
                color: KiranaColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: KiranaColors.error),
              ),
              child: Row(
                children: [
                  const Icon(Icons.print_disabled, color: KiranaColors.error),
                  const SizedBox(width: KiranaSpacing.xs),
                  Expanded(
                    child: Text(
                      printerState.errorMessage!,
                      style: KiranaTypography.bodySmall,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showPrinterSettings(context),
                    child: const Text('Settings'),
                  ),
                ],
              ),
            ),

          // 2. Retail POS Receipt Card Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(KiranaSpacing.md),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 550),
                  padding: const EdgeInsets.all(KiranaSpacing.lg),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _showThermalText
                      ? SelectableText(
                          receiptText,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            height: 1.25,
                            color: Colors.black87,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header: Shop Branding
                            Center(
                              child: Column(
                                children: [
                                  Container(
                                    padding:
                                        const EdgeInsets.all(KiranaSpacing.sm),
                                    decoration: BoxDecoration(
                                      color: KiranaColors.primary
                                          .withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.storefront,
                                      size: 36,
                                      color: KiranaColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: KiranaSpacing.xs),
                                  Text(
                                    shopName.toUpperCase(),
                                    style: KiranaTypography.headlineMedium
                                        .copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: KiranaColors.primaryDark,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (shopAddress.isNotEmpty)
                                    Text(
                                      shopAddress,
                                      style: KiranaTypography.bodySmall,
                                      textAlign: TextAlign.center,
                                    ),
                                  if (shopPhone.isNotEmpty)
                                    Text(
                                      'Ph: $shopPhone',
                                      style: KiranaTypography.bodySmall,
                                    ),
                                  if (gstin != null && gstin.isNotEmpty)
                                    Text(
                                      'GSTIN: $gstin',
                                      style:
                                          KiranaTypography.bodySmall.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const Divider(height: KiranaSpacing.xl),

                            // Bill Metadata Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Bill No: ${widget.bill.billNumber}',
                                      style: KiranaTypography.titleMedium,
                                    ),
                                    Text(
                                      'Date: ${_formatDate(widget.bill.createdAt)}',
                                      style: KiranaTypography.bodySmall,
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: KiranaSpacing.sm,
                                    vertical: KiranaSpacing.xxs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: KiranaColors.success
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(16),
                                    border:
                                        Border.all(color: KiranaColors.success),
                                  ),
                                  child: Text(
                                    widget.bill.paymentStatus.toUpperCase(),
                                    style: KiranaTypography.labelSmall.copyWith(
                                      color: KiranaColors.success,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            if (widget.bill.hasCustomer) ...[
                              const SizedBox(height: KiranaSpacing.sm),
                              Container(
                                padding: const EdgeInsets.all(KiranaSpacing.sm),
                                decoration: BoxDecoration(
                                  color: KiranaColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.person_outline, size: 20),
                                    const SizedBox(width: KiranaSpacing.xs),
                                    Expanded(
                                      child: Text(
                                        'Customer: ${widget.bill.customerName}${widget.bill.customerPhone != null ? " (${widget.bill.customerPhone})" : ""}',
                                        style: KiranaTypography.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const Divider(height: KiranaSpacing.xl),

                            // Items Table Header
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text('Item',
                                      style: KiranaTypography.labelSmall),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text('Qty',
                                      textAlign: TextAlign.center,
                                      style: KiranaTypography.labelSmall),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text('Price',
                                      textAlign: TextAlign.right,
                                      style: KiranaTypography.labelSmall),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text('Total',
                                      textAlign: TextAlign.right,
                                      style: KiranaTypography.labelSmall),
                                ),
                              ],
                            ),
                            const SizedBox(height: KiranaSpacing.xs),

                            // Items List
                            ...widget.bill.items.map((item) {
                              final qtyStr = item.quantity % 1 == 0
                                  ? item.quantity.toInt().toString()
                                  : item.quantity.toStringAsFixed(2);
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: KiranaSpacing.xxs),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        item.productName,
                                        style: KiranaTypography.bodyMedium,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        '$qtyStr ${item.unit}',
                                        textAlign: TextAlign.center,
                                        style: KiranaTypography.bodySmall,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        item.unitPricePaise.toRupeesString(),
                                        textAlign: TextAlign.right,
                                        style: KiranaTypography.bodySmall,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        item.totalPaise.toRupeesString(),
                                        textAlign: TextAlign.right,
                                        style: KiranaTypography.bodyMedium
                                            .copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),

                            const Divider(height: KiranaSpacing.xl),

                            // Totals Summary Section
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Subtotal:'),
                                Text(
                                    widget.bill.subtotalPaise.toRupeesString()),
                              ],
                            ),
                            if (widget.bill.discountPaise > 0)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Discount:'),
                                  Text(
                                    '- ${widget.bill.discountPaise.toRupeesString()}',
                                    style: const TextStyle(
                                        color: KiranaColors.error),
                                  ),
                                ],
                              ),
                            if (widget.bill.taxTotalPaise > 0)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Tax:'),
                                  Text(widget.bill.taxTotalPaise
                                      .toRupeesString()),
                                ],
                              ),
                            const Divider(height: KiranaSpacing.md),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'GRAND TOTAL:',
                                  style: KiranaTypography.titleLarge,
                                ),
                                Text(
                                  widget.bill.totalPaise.toRupeesString(),
                                  style: KiranaTypography.displayTotal.copyWith(
                                    color: KiranaColors.primary,
                                    fontSize: 22,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: KiranaSpacing.lg),
                            Center(
                              child: Text(
                                'Thank you for shopping with us!',
                                style: KiranaTypography.bodySmall.copyWith(
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                ).animate().fade(duration: 250.ms).slideY(begin: 0.05, end: 0),
              ),
            ),
          ),

          // 3. Action Toolbar Buttons
          Container(
            padding: const EdgeInsets.all(KiranaSpacing.md),
            decoration: BoxDecoration(
              color: KiranaColors.surface,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 6,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'SHARE RECEIPT',
                    icon: Icons.share,
                    isLoading: _isSharing,
                    onPressed: () => _handleShare(context, shopSettings),
                  ),
                ),
                const SizedBox(width: KiranaSpacing.xs),
                IconButton.filledTonal(
                  icon: const Icon(Icons.print),
                  tooltip: 'Print Receipt',
                  onPressed: () async {
                    if (!printerState.isConnected) {
                      _showPrinterSettings(context);
                    } else {
                      await printerNotifier.printReceipt(widget.bill);
                    }
                  },
                ),
                const SizedBox(width: KiranaSpacing.xs),
                ElevatedButton(
                  onPressed: () {
                    ref
                        .read(billingNotifierProvider.notifier)
                        .initializeDraft();
                    context.go('/bills');
                  },
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
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
