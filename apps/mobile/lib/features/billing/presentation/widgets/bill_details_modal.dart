import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/num_extensions.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../receipts/domain/services/share_receipt_service.dart';
import '../../../receipts/presentation/providers/printer_provider.dart';
import '../../../receipts/presentation/screens/completed_receipt_screen.dart';
import '../../../receipts/presentation/screens/pdf_receipt_preview_screen.dart';
import '../../domain/models/bill_model.dart';

class BillDetailsModal extends ConsumerWidget {
  final BillModel bill;

  const BillDetailsModal({super.key, required this.bill});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeShopName =
        ref.watch(authNotifierProvider).activeShopName ?? 'Kirana Store';

    return Container(
      padding: EdgeInsets.only(
        top: KiranaSpacing.md,
        left: KiranaSpacing.md,
        right: KiranaSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + KiranaSpacing.md,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bill #${bill.billNumber}',
                    style: KiranaTypography.titleLarge,
                  ),
                  Text(
                    DateFormatter.formatDateTime(bill.createdAt),
                    style: KiranaTypography.bodySmall.copyWith(
                      color: KiranaColors.textSecondary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Divider(height: KiranaSpacing.md),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shop & Customer Info Card
                  Container(
                    padding: const EdgeInsets.all(KiranaSpacing.sm),
                    decoration: BoxDecoration(
                      color: KiranaColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Shop:', style: KiranaTypography.bodySmall),
                            Text(activeShopName,
                                style: KiranaTypography.titleMedium),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Customer:',
                                style: KiranaTypography.bodySmall),
                            Text(
                              bill.customerName ?? 'Walk-in Customer',
                              style: KiranaTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        if (bill.customerPhone != null &&
                            bill.customerPhone!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Phone:', style: KiranaTypography.bodySmall),
                              Text(bill.customerPhone!,
                                  style: KiranaTypography.bodySmall),
                            ],
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Cashier ID:',
                                style: KiranaTypography.bodySmall),
                            Text(bill.cashierId,
                                style: KiranaTypography.bodySmall),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: KiranaSpacing.md),

                  // Line Items List
                  Text('Items Breakdown', style: KiranaTypography.titleMedium),
                  const SizedBox(height: KiranaSpacing.xs),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: bill.items.length,
                    separatorBuilder: (_, __) => const Divider(
                        height: 1, color: KiranaColors.outlineVariant),
                    itemBuilder: (context, idx) {
                      final item = bill.items[idx];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: KiranaSpacing.xs),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.productName,
                                      style: KiranaTypography.bodyMedium),
                                  Text(
                                    '${item.quantity} ${item.unit} @ ${item.unitPricePaise.toRupeesString()}',
                                    style: KiranaTypography.bodySmall.copyWith(
                                      color: KiranaColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              item.totalPaise.toRupeesString(),
                              style: KiranaTypography.priceTabular,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const Divider(height: KiranaSpacing.md),

                  // Totals Summary
                  _buildSummaryRow(
                      'Subtotal', bill.subtotalPaise.toRupeesString()),
                  if (bill.discountPaise > 0)
                    _buildSummaryRow(
                        'Discount', '-${bill.discountPaise.toRupeesString()}',
                        color: KiranaColors.success),
                  if (bill.taxTotalPaise > 0)
                    _buildSummaryRow(
                        'Tax', bill.taxTotalPaise.toRupeesString()),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Grand Total', style: KiranaTypography.titleLarge),
                      Text(
                        bill.totalPaise.toRupeesString(),
                        style: KiranaTypography.headlineMedium.copyWith(
                          color: KiranaColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: KiranaSpacing.md),
                ],
              ),
            ),
          ),

          // Action Toolbar Buttons
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'VIEW RECEIPT',
                      icon: Icons.receipt_long,
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CompletedReceiptScreen(bill: bill),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: KiranaSpacing.xs),
                  Expanded(
                    child: AppButton(
                      label: 'PRINT',
                      icon: Icons.print,
                      variant: AppButtonVariant.outlined,
                      onPressed: () async {
                        await ref
                            .read(printerNotifierProvider.notifier)
                            .printReceipt(bill);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Print job submitted.')),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: KiranaSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'GENERATE PDF',
                      icon: Icons.picture_as_pdf,
                      variant: AppButtonVariant.outlined,
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PdfReceiptPreviewScreen(bill: bill),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: KiranaSpacing.xs),
                  Expanded(
                    child: AppButton(
                      label: 'SHARE',
                      icon: Icons.share,
                      variant: AppButtonVariant.outlined,
                      onPressed: () async {
                        final shareService =
                            ref.read(shareReceiptServiceProvider);
                        await shareService.shareReceipt(bill: bill);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: KiranaTypography.bodySmall),
          Text(
            value,
            style: KiranaTypography.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
