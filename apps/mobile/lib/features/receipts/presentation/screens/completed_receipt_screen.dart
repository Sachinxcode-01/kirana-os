import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/extensions/num_extensions.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../billing/domain/models/bill_model.dart';
import '../../../billing/presentation/providers/billing_provider.dart';
import '../../../settings/presentation/providers/shop_settings_provider.dart';
import '../../domain/models/printer_device_model.dart';
import '../providers/printer_provider.dart';
import '../sheets/printer_selection_sheet.dart';

class CompletedReceiptScreen extends ConsumerWidget {
  final BillModel bill;

  const CompletedReceiptScreen({super.key, required this.bill});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final printerState = ref.watch(printerNotifierProvider);
    final printerNotifier = ref.read(printerNotifierProvider.notifier);
    final formatterService = ref.watch(receiptFormatterServiceProvider);
    final shopSettings = ref.watch(shopSettingsNotifierProvider).settings;

    final receiptText = formatterService.formatThermalReceipt(
      bill: bill,
      shopSettings: shopSettings,
      paperWidth: printerState.paperWidth,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Bill #${bill.billNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Printer Settings',
            onPressed: () => _showPrinterSettings(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Independent Print Error Banner & Retry Actions
          if (printerState.errorMessage != null)
            Container(
              margin: const EdgeInsets.all(KiranaSpacing.md),
              padding: const EdgeInsets.all(KiranaSpacing.md),
              decoration: BoxDecoration(
                color: KiranaColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: KiranaColors.error),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.print_disabled,
                          color: KiranaColors.error),
                      const SizedBox(width: KiranaSpacing.xs),
                      Text('Printer Unavailable',
                          style: KiranaTypography.titleMedium
                              .copyWith(color: KiranaColors.error)),
                    ],
                  ),
                  const SizedBox(height: KiranaSpacing.xxs),
                  Text(
                    printerState.errorMessage!,
                    style: KiranaTypography.bodySmall,
                  ),
                  const SizedBox(height: KiranaSpacing.xs),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _showPrinterSettings(context),
                        icon: const Icon(Icons.settings, size: 16),
                        label: const Text('Select Printer'),
                      ),
                      const SizedBox(width: KiranaSpacing.xs),
                      ElevatedButton.icon(
                        onPressed: printerState.isPrinting
                            ? null
                            : () => printerNotifier.printReceipt(bill),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Retry Print'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          if (printerState.successMessage != null)
            Container(
              margin: const EdgeInsets.all(KiranaSpacing.md),
              padding: const EdgeInsets.all(KiranaSpacing.sm),
              decoration: BoxDecoration(
                color: KiranaColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: KiranaColors.success),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      color: KiranaColors.success),
                  const SizedBox(width: KiranaSpacing.xs),
                  Expanded(
                    child: Text(
                      printerState.successMessage!,
                      style: KiranaTypography.bodySmall
                          .copyWith(color: KiranaColors.success),
                    ),
                  ),
                ],
              ),
            ),

          // 2. Receipt Thermal Print Preview Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: KiranaSpacing.md),
              padding: const EdgeInsets.all(KiranaSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Thermal Preview (${printerState.paperWidth.label})',
                          style: KiranaTypography.labelSmall.copyWith(
                            color: KiranaColors.textSecondary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: KiranaSpacing.xs, vertical: 2),
                          decoration: BoxDecoration(
                            color: KiranaColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'SALE COMPLETED (${bill.totalPaise.toRupeesString()})',
                            style: KiranaTypography.bodySmall.copyWith(
                              color: KiranaColors.success,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: KiranaSpacing.md),
                    SelectableText(
                      receiptText,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        height: 1.2,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Action Toolbar Buttons
          Padding(
            padding: const EdgeInsets.all(KiranaSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'PRINT RECEIPT',
                    icon: Icons.print,
                    isLoading: printerState.isPrinting,
                    onPressed: () async {
                      if (!printerState.isConnected) {
                        _showPrinterSettings(context);
                      } else {
                        await printerNotifier.printReceipt(bill);
                      }
                    },
                  ),
                ),
                const SizedBox(width: KiranaSpacing.xs),
                IconButton.filledTonal(
                  icon: const Icon(Icons.picture_as_pdf),
                  tooltip: 'Share PDF',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Receipt PDF generated locally.'),
                      ),
                    );
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
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
