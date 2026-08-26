import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/radius.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../providers/inventory_provider.dart';

class InventoryHistoryScreen extends ConsumerWidget {
  final String? productId;

  const InventoryHistoryScreen({super.key, this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(inventoryHistoryProvider(productId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adjustment & Stock History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(inventoryHistoryProvider(productId).notifier).refresh();
            },
          ),
        ],
      ),
      body: historyState.movements.isEmpty && historyState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : historyState.movements.isEmpty
              ? _buildEmptyState(context)
              : NotificationListener<ScrollNotification>(
                  onNotification: (scrollInfo) {
                    if (scrollInfo.metrics.pixels >=
                            scrollInfo.metrics.maxScrollExtent - 200 &&
                        !historyState.isLoading &&
                        historyState.hasMore) {
                      ref
                          .read(inventoryHistoryProvider(productId).notifier)
                          .loadNextPage();
                    }
                    return false;
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(KiranaSpacing.md),
                    itemCount: historyState.movements.length +
                        (historyState.hasMore ? 1 : 0),
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: KiranaSpacing.sm),
                    itemBuilder: (context, index) {
                      if (index == historyState.movements.length) {
                        return const Padding(
                          padding: EdgeInsets.all(KiranaSpacing.md),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final item = historyState.movements[index];
                      final isPositive = item.isPositive;
                      final type = item.type;
                      final prevQty = item.computedPreviousQuantity;

                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: KiranaRadius.borderMd,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(KiranaSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.productName ??
                                          'Product #${item.productId}',
                                      style:
                                          KiranaTypography.titleMedium.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: KiranaSpacing.sm,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isPositive
                                          ? KiranaColors.secondaryContainer
                                          : KiranaColors.errorContainer,
                                      borderRadius: KiranaRadius.borderSm,
                                    ),
                                    child: Text(
                                      type.label,
                                      style:
                                          KiranaTypography.labelSmall.copyWith(
                                        color: isPositive
                                            ? KiranaColors.secondary
                                            : KiranaColors.error,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: KiranaSpacing.xs),

                              // Stock Progression: Previous -> Delta -> New
                              Container(
                                padding: const EdgeInsets.all(KiranaSpacing.xs),
                                decoration: BoxDecoration(
                                  color: KiranaColors.surfaceVariant
                                      .withValues(alpha: 0.5),
                                  borderRadius: KiranaRadius.borderSm,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _HistoryQtyCol(
                                      label: 'Previous',
                                      value:
                                          '${prevQty % 1 == 0 ? prevQty.toInt() : prevQty.toStringAsFixed(2)}',
                                    ),
                                    Text(
                                      '${isPositive ? "+" : ""}${item.quantityDelta % 1 == 0 ? item.quantityDelta.toInt() : item.quantityDelta.toStringAsFixed(2)}',
                                      style:
                                          KiranaTypography.labelLarge.copyWith(
                                        color: isPositive
                                            ? KiranaColors.secondary
                                            : KiranaColors.error,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    _HistoryQtyCol(
                                      label: 'New Quantity',
                                      value:
                                          '${item.balanceAfter % 1 == 0 ? item.balanceAfter.toInt() : item.balanceAfter.toStringAsFixed(2)}',
                                      valueColor: KiranaColors.primary,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: KiranaSpacing.xs),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Reason: ${item.displayReason}',
                                      style:
                                          KiranaTypography.bodySmall.copyWith(
                                        color: KiranaColors.neutral700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _formatDate(item.createdAt),
                                    style: KiranaTypography.bodySmall.copyWith(
                                      color: KiranaColors.neutral500,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              if (item.note != null &&
                                  item.note!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Notes: ${item.note}',
                                  style: KiranaTypography.bodySmall.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: KiranaColors.textSecondary,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'User: ${item.performedByName ?? item.performedBy}',
                                    style: KiranaTypography.bodySmall.copyWith(
                                      color: KiranaColors.neutral500,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.lock_clock,
                                          size: 12,
                                          color: KiranaColors.neutral400),
                                      const SizedBox(width: 2),
                                      Text(
                                        'Immutable Record',
                                        style:
                                            KiranaTypography.bodySmall.copyWith(
                                          color: KiranaColors.neutral400,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.history_outlined,
            size: 64,
            color: KiranaColors.neutral400,
          ),
          const SizedBox(height: KiranaSpacing.md),
          Text(
            'No Adjustment History Found',
            style: KiranaTypography.titleLarge.copyWith(
              color: KiranaColors.textSecondary,
            ),
          ),
          const SizedBox(height: KiranaSpacing.xs),
          const Text(
            'Completed stock adjustments will appear here as immutable records.',
            style: KiranaTypography.bodyMedium,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, "0")}:${dt.minute.toString().padLeft(2, "0")}';
  }
}

class _HistoryQtyCol extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _HistoryQtyCol({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: KiranaTypography.bodySmall.copyWith(
            fontSize: 10,
            color: KiranaColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: KiranaTypography.labelLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor ?? KiranaColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
