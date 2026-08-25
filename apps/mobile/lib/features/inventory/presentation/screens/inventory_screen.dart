import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/radius.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../products/presentation/providers/product_provider.dart';
import '../providers/inventory_provider.dart';
import '../widgets/stock_adjustment_sheet.dart';
import 'inventory_history_screen.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lowStockAsync = ref.watch(lowStockProductsProvider);
    final allProductsAsync = ref.watch(productListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory & Stock Alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Inventory History',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const InventoryHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(lowStockProductsProvider);
          ref.invalidate(productListProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(KiranaSpacing.md),
          children: [
            lowStockAsync.when(
              data: (lowStockItems) {
                if (lowStockItems.isEmpty) {
                  return Card(
                    color: KiranaColors.secondaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(KiranaSpacing.md),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: KiranaColors.secondary),
                          const SizedBox(width: KiranaSpacing.md),
                          Expanded(
                            child: Text(
                              'All products have sufficient stock.',
                              style: KiranaTypography.bodyMedium.copyWith(
                                color: KiranaColors.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Card(
                  color: KiranaColors.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(KiranaSpacing.md),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: KiranaColors.error),
                        const SizedBox(width: KiranaSpacing.md),
                        Expanded(
                          child: Text(
                            '${lowStockItems.length} products are running below minimum safety stock.',
                            style: KiranaTypography.bodyMedium.copyWith(
                              color: KiranaColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (err, _) => Text(
                'Could not load stock alerts: $err',
                style: KiranaTypography.bodySmall
                    .copyWith(color: KiranaColors.error),
              ),
            ),
            const SizedBox(height: KiranaSpacing.lg),

            // Quick Stats Card Row
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Total Catalog',
                    value: allProductsAsync.when(
                      data: (list) => '${list.length}',
                      loading: () => '...',
                      error: (_, __) => '0',
                    ),
                    icon: Icons.inventory_2_outlined,
                    color: KiranaColors.primary,
                  ),
                ),
                const SizedBox(width: KiranaSpacing.md),
                Expanded(
                  child: _StatCard(
                    title: 'Low Stock',
                    value: lowStockAsync.when(
                      data: (list) => '${list.length}',
                      loading: () => '...',
                      error: (_, __) => '0',
                    ),
                    icon: Icons.warning_amber_rounded,
                    color: KiranaColors.warning,
                  ),
                ),
              ],
            ),

            const SizedBox(height: KiranaSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Critical Low Stock Items',
                    style: KiranaTypography.titleLarge),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const InventoryHistoryScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.receipt_long, size: 16),
                  label: const Text('View Logs'),
                ),
              ],
            ),
            const SizedBox(height: KiranaSpacing.sm),

            lowStockAsync.when(
              data: (lowStockItems) {
                if (lowStockItems.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: KiranaSpacing.xl),
                    child: Center(
                      child: Text('No low stock alerts recorded!'),
                    ),
                  );
                }

                return Column(
                  children: lowStockItems.map((product) {
                    final isOutOfStock = product.currentStock <= 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: KiranaSpacing.sm),
                      shape: RoundedRectangleBorder(
                        borderRadius: KiranaRadius.borderMd,
                      ),
                      child: ListTile(
                        title: Text(
                          product.name,
                          style: KiranaTypography.titleMedium
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Current: ${product.currentStock % 1 == 0 ? product.currentStock.toInt() : product.currentStock} ${product.unit} (Min: ${product.minStockAlert % 1 == 0 ? product.minStockAlert.toInt() : product.minStockAlert} ${product.unit})',
                          style: KiranaTypography.bodySmall.copyWith(
                            color: isOutOfStock
                                ? KiranaColors.error
                                : KiranaColors.warning,
                          ),
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: KiranaColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(64, 36),
                          ),
                          onPressed: () async {
                            final adjusted = await StockAdjustmentSheet.show(
                                context, product);
                            if (adjusted == true) {
                              ref.invalidate(lowStockProductsProvider);
                              ref.invalidate(productListProvider);
                            }
                          },
                          child: const Text('Adjust'),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(KiranaSpacing.xl),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(KiranaSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: KiranaRadius.borderMd,
        border: Border.all(color: KiranaColors.neutral200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: KiranaSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: KiranaTypography.bodySmall
                    .copyWith(color: KiranaColors.textSecondary),
              ),
              Text(
                value,
                style: KiranaTypography.headlineMedium
                    .copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
