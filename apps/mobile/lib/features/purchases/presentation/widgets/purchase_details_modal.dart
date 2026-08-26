import 'package:flutter/material.dart';
import '../../../../core/extensions/num_extensions.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../domain/models/purchase_model.dart';

class PurchaseDetailsModal extends StatelessWidget {
  final PurchaseModel purchase;

  const PurchaseDetailsModal({super.key, required this.purchase});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: KiranaSpacing.md,
        left: KiranaSpacing.md,
        right: KiranaSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + KiranaSpacing.md,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Modal Top Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: KiranaColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: KiranaSpacing.sm),

          // Header Title & Close Button
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Purchase #${purchase.purchaseNumber}',
                      style: KiranaTypography.headlineMedium,
                    ),
                    Text(
                      'Date: ${_formatDate(purchase.createdAt)}',
                      style: KiranaTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: KiranaSpacing.xs),

          // Status & Stock Added Badges Row
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: purchase.isCompleted
                      ? KiranaColors.success.withValues(alpha: 0.15)
                      : KiranaColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  purchase.status.toUpperCase(),
                  style: KiranaTypography.labelSmall.copyWith(
                    color: purchase.isCompleted
                        ? KiranaColors.success
                        : KiranaColors.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: KiranaSpacing.xs),
              if (purchase.isCompleted) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: KiranaColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: KiranaColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.inventory_2_outlined,
                          size: 14, color: KiranaColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Stock Added',
                        style: KiranaTypography.labelSmall.copyWith(
                          color: KiranaColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: KiranaSpacing.md),

          // Supplier Information Card
          Card(
            color: KiranaColors.surfaceVariant.withValues(alpha: 0.5),
            child: Padding(
              padding: const EdgeInsets.all(KiranaSpacing.sm),
              child: Row(
                children: [
                  const Icon(Icons.business, color: KiranaColors.primary),
                  const SizedBox(width: KiranaSpacing.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          purchase.supplierName ?? 'General Procurement',
                          style: KiranaTypography.titleMedium,
                        ),
                        if (purchase.supplierReference != null &&
                            purchase.supplierReference!.isNotEmpty)
                          Text(
                            'Ref / Invoice #: ${purchase.supplierReference}',
                            style: KiranaTypography.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: KiranaSpacing.md),

          // Line Items Breakdown Header
          Text('Purchased Products (${purchase.items.length})',
              style: KiranaTypography.titleMedium),
          const SizedBox(height: KiranaSpacing.xs),

          // Line Items Table List
          Expanded(
            child: purchase.items.isEmpty
                ? const Center(
                    child: Text('No line items recorded for this purchase.'))
                : ListView.separated(
                    itemCount: purchase.items.length,
                    separatorBuilder: (_, __) => const Divider(
                        height: 1, color: KiranaColors.outlineVariant),
                    itemBuilder: (context, index) {
                      final item = purchase.items[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: KiranaSpacing.xs,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.productName,
                                      style: KiranaTypography.titleMedium),
                                  Text(
                                    '${item.quantity} ${item.unit} @ ${item.purchasePricePaise.toRupeesString()}/${item.unit}',
                                    style: KiranaTypography.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              item.totalPaise.toRupeesString(),
                              style: KiranaTypography.priceTabular.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          const Divider(height: 16),

          // Financial Grand Total Card
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Grand Total:', style: KiranaTypography.titleMedium),
              Text(
                purchase.totalPaise.toRupeesString(),
                style: KiranaTypography.headlineMedium.copyWith(
                  color: KiranaColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: KiranaSpacing.sm),

          // Read-Only Protection Notice for Completed Purchases
          if (purchase.isCompleted)
            Container(
              padding: const EdgeInsets.all(KiranaSpacing.xs),
              decoration: BoxDecoration(
                color: KiranaColors.neutral200,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline,
                      size: 16, color: KiranaColors.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Completed purchase records are read-only to preserve inventory audit trails.',
                      style: KiranaTypography.bodySmall
                          .copyWith(color: KiranaColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final month = monthNames[local.month - 1];
    final year = local.year;
    final hour =
        local.hour > 12 ? local.hour - 12 : (local.hour == 0 ? 12 : local.hour);
    final minute = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour >= 12 ? 'PM' : 'AM';

    return '$day $month $year, ${hour.toString().padLeft(2, '0')}:$minute $ampm';
  }
}
