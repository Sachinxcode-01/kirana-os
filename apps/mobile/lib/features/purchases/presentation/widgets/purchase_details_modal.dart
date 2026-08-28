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
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(KiranaSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Purchase Invoice #${purchase.invoiceNumber}',
                        style: KiranaTypography.headlineMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Date: ${DateFormatter.formatDate(purchase.invoiceDate)}',
                        style: KiranaTypography.bodySmall,
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: KiranaSpacing.md),

              // Supplier Summary Card
              Card(
                color: KiranaColors.surfaceVariant,
                shape: RoundedRectangleBorder(
                  borderRadius: KiranaRadius.borderMd,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(KiranaSpacing.md),
                  child: Row(
                    children: [
                      const Icon(Icons.business, color: KiranaColors.primary),
                      const SizedBox(width: KiranaSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Supplier',
                                style: KiranaTypography.labelSmall),
                            Text(
                              purchase.supplierNameSnapshot ?? 'General Vendor',
                              style: KiranaTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
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
                          'Stock Inwarded',
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
              const SizedBox(height: KiranaSpacing.md),

              Text('Inward Products',
                  style: KiranaTypography.titleMedium
                      .copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: KiranaSpacing.xs),

              Expanded(
                child: FutureBuilder(
                  future: local.getPurchaseItems(purchase.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final items = snapshot.data ?? [];
                    if (items.isEmpty) {
                      return const Center(child: Text('No item details found'));
                    }

                    return ListView.separated(
                      controller: scrollController,
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Item #${index + 1}',
                                      style:
                                          KiranaTypography.bodyMedium.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${item.quantity.toStringAsFixed(0)} units @ ${_formatRupees(item.purchasePricePaise.toInt())} / unit (Tax ${item.taxRate.toStringAsFixed(0)}%)',
                                      style: KiranaTypography.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
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

              const Divider(height: KiranaSpacing.md),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal', style: KiranaTypography.bodyMedium),
                  Text(_formatRupees(purchase.subtotalPaise),
                      style: KiranaTypography.bodyMedium),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tax Total', style: KiranaTypography.bodyMedium),
                  Text(_formatRupees(purchase.taxTotalPaise),
                      style: KiranaTypography.bodyMedium),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Grand Total',
                      style: KiranaTypography.titleLarge
                          .copyWith(fontWeight: FontWeight.bold)),
                  Text(
                    _formatRupees(purchase.totalPaise),
                    style: KiranaTypography.headlineMedium.copyWith(
                      color: KiranaColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
