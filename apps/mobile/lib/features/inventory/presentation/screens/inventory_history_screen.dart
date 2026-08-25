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
        title: const Text('Inventory History'),
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
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Delta: ${isPositive ? "+" : ""}${item.quantityDelta % 1 == 0 ? item.quantityDelta.toInt() : item.quantityDelta}',
                                    style: KiranaTypography.bodyMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isPositive
                                          ? KiranaColors.secondary
                                          : KiranaColors.error,
                                    ),
                                  ),
                                  Text(
                                    'Balance After: ${item.balanceAfter % 1 == 0 ? item.balanceAfter.toInt() : item.balanceAfter}',
                                    style: KiranaTypography.bodySmall.copyWith(
                                      color: KiranaColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: KiranaSpacing.xs),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Reason: ${item.reason}',
                                    style: KiranaTypography.bodySmall.copyWith(
                                      color: KiranaColors.neutral600,
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
                                const SizedBox(height: KiranaSpacing.xs),
                                Text(
                                  'Note: ${item.note}',
                                  style: KiranaTypography.bodySmall.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: KiranaColors.textSecondary,
                                  ),
                                ),
                              ],
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
            'No Inventory History Found',
            style: KiranaTypography.titleLarge.copyWith(
              color: KiranaColors.textSecondary,
            ),
          ),
          const SizedBox(height: KiranaSpacing.xs),
          const Text(
            'Stock adjustments and inward transactions will appear here.',
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
