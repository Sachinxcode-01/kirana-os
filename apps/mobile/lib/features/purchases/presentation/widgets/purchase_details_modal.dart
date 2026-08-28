import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/radius.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../suppliers/presentation/providers/supplier_provider.dart';
import '../../domain/models/purchase_model.dart';

class PurchaseDetailsModal extends ConsumerWidget {
  final PurchaseModel purchase;

  const PurchaseDetailsModal({super.key, required this.purchase});

  static String _formatRupees(int paise) {
    final double rupees = paise / 100.0;
    return '₹${rupees.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final local = ref.watch(supplierLocalDataSourceProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: KiranaColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header: Invoice title + close button
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    KiranaSpacing.lg, KiranaSpacing.xs, KiranaSpacing.md, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Invoice #${purchase.invoiceNumber}',
                            style: KiranaTypography.titleLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Date: ${DateFormatter.formatDate(purchase.invoiceDate)}',
                            style: KiranaTypography.bodySmall.copyWith(
                              color: KiranaColors.textSecondary,
                            ),
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
              ),

              const SizedBox(height: KiranaSpacing.sm),

              // Supplier Summary Card
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: KiranaSpacing.lg),
                child: Card(
                  elevation: 0,
                  color: KiranaColors.primaryContainer.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: KiranaRadius.borderMd,
                    side: BorderSide(
                        color: KiranaColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: KiranaSpacing.md,
                        vertical: KiranaSpacing.sm),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: KiranaColors.primary,
                          child: const Icon(Icons.business,
                              color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: KiranaSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Supplier',
                                style: KiranaTypography.labelSmall.copyWith(
                                  color: KiranaColors.textSecondary,
                                ),
                              ),
                              Text(
                                purchase.supplierNameSnapshot ??
                                    'General Vendor',
                                style: KiranaTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: KiranaColors.successContainer,
                            borderRadius: KiranaRadius.borderSm,
                          ),
                          child: const Text(
                            '✓ Inwarded',
                            style: TextStyle(
                              color: KiranaColors.success,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: KiranaSpacing.md),

              // Section Title: Inward Products
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: KiranaSpacing.lg),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined,
                        size: 18, color: KiranaColors.primary),
                    const SizedBox(width: KiranaSpacing.xs),
                    Text(
                      'Inward Products',
                      style: KiranaTypography.titleMedium
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: KiranaSpacing.xs),

              // Items List
              Expanded(
                child: FutureBuilder(
                  future: local.getPurchaseItems(purchase.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final items = snapshot.data ?? [];
                    if (items.isEmpty) {
                      return const Center(
                        child: Text('No item details found'),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: KiranaSpacing.lg),
                      itemCount: items.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 8, endIndent: 8),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Item number badge
                              Container(
                                width: 28,
                                height: 28,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: KiranaColors.primary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: KiranaColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: KiranaSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productId.length > 8
                                          ? 'Product #${index + 1}'
                                          : item.productId,
                                      style:
                                          KiranaTypography.bodyMedium.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${item.quantity.toStringAsFixed(0)} units × ${_formatRupees(item.purchasePricePaise.toInt())}  •  Tax ${item.taxRate.toStringAsFixed(0)}%',
                                      style:
                                          KiranaTypography.bodySmall.copyWith(
                                        color: KiranaColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: KiranaSpacing.xs),
                              Text(
                                _formatRupees(item.totalPaise.toInt()),
                                style: KiranaTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: KiranaColors.primary,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Totals Footer
              Container(
                padding: const EdgeInsets.fromLTRB(KiranaSpacing.lg,
                    KiranaSpacing.sm, KiranaSpacing.lg, KiranaSpacing.md),
                decoration: BoxDecoration(
                  color: KiranaColors.surfaceVariant.withValues(alpha: 0.5),
                  border: Border(
                    top: BorderSide(
                        color: KiranaColors.outlineVariant, width: 1),
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      // Subtotal row
                      _TotalRow(
                        label: 'Subtotal',
                        value: _formatRupees(purchase.subtotalPaise),
                        isNormal: true,
                      ),
                      const SizedBox(height: 4),
                      // Tax row
                      _TotalRow(
                        label: 'Tax Total',
                        value: _formatRupees(purchase.taxTotalPaise),
                        isNormal: true,
                      ),
                      const Divider(height: KiranaSpacing.md, thickness: 1),
                      // Grand Total row
                      _TotalRow(
                        label: 'Grand Total',
                        value: _formatRupees(purchase.totalPaise),
                        isGrandTotal: true,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isGrandTotal;
  final bool isNormal;

  const _TotalRow({
    required this.label,
    required this.value,
    this.isGrandTotal = false,
    this.isNormal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isGrandTotal
              ? KiranaTypography.titleMedium
                  .copyWith(fontWeight: FontWeight.bold)
              : KiranaTypography.bodyMedium
                  .copyWith(color: KiranaColors.textSecondary),
        ),
        Text(
          value,
          style: isGrandTotal
              ? KiranaTypography.titleLarge.copyWith(
                  color: KiranaColors.primary,
                  fontWeight: FontWeight.bold,
                )
              : KiranaTypography.bodyMedium,
        ),
      ],
    );
  }
}
