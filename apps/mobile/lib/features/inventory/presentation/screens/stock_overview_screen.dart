import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/num_extensions.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../products/domain/models/product_model.dart';
import '../../domain/models/stock_overview_model.dart';
import '../providers/stock_overview_provider.dart';
import '../widgets/stock_details_modal.dart';

class StockOverviewScreen extends ConsumerStatefulWidget {
  const StockOverviewScreen({super.key});

  @override
  ConsumerState<StockOverviewScreen> createState() =>
      _StockOverviewScreenState();
}

class _StockOverviewScreenState extends ConsumerState<StockOverviewScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      ref.read(stockOverviewNotifierProvider.notifier).setSearchQuery(query);
    });
  }

  void _openStockDetails(ProductModel product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: KiranaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => StockDetailsModal(product: product),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stockState = ref.watch(stockOverviewNotifierProvider);
    final stockNotifier = ref.read(stockOverviewNotifierProvider.notifier);
    final products = stockState.products;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Overview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => stockNotifier.loadStock(refresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // Offline Sync Banner
          if (stockState.isOffline)
            Container(
              width: double.infinity,
              color: KiranaColors.warningContainer,
              padding: const EdgeInsets.symmetric(
                horizontal: KiranaSpacing.md,
                vertical: KiranaSpacing.xs,
              ),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off_outlined,
                      color: KiranaColors.warning, size: 18),
                  const SizedBox(width: KiranaSpacing.xs),
                  Expanded(
                    child: Text(
                      stockState.lastSyncedAt != null
                          ? 'Offline · Last synced ${DateFormatter.formatDate(stockState.lastSyncedAt!)}'
                          : 'Offline · Showing cached inventory',
                      style: KiranaTypography.bodySmall.copyWith(
                        color: KiranaColors.warning,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(KiranaSpacing.md),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search stock by product name, SKU, or barcode...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: KiranaSpacing.md,
                  vertical: KiranaSpacing.xs,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          // Stock Metric Overview Summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: KiranaSpacing.md),
            child: Row(
              children: [
                _SummaryCard(
                  title: 'Total Items',
                  value: '${stockState.totalCount}',
                  color: KiranaColors.primary,
                ),
                const SizedBox(width: KiranaSpacing.xs),
                _SummaryCard(
                  title: 'In Stock',
                  value: '${stockState.inStockCount}',
                  color: KiranaColors.success,
                ),
                const SizedBox(width: KiranaSpacing.xs),
                _SummaryCard(
                  title: 'Low Stock',
                  value: '${stockState.lowStockCount}',
                  color: KiranaColors.warning,
                ),
                const SizedBox(width: KiranaSpacing.xs),
                _SummaryCard(
                  title: 'Out of Stock',
                  value: '${stockState.outOfStockCount}',
                  color: KiranaColors.error,
                ),
              ],
            ),
          ),
          const SizedBox(height: KiranaSpacing.sm),

          // Filter Chips Bar (ALL, IN STOCK, LOW STOCK, OUT OF STOCK)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: KiranaSpacing.md),
            child: Row(
              children: [
                FilterChip(
                  selected: stockState.filter.statusFilter == null,
                  label: const Text('ALL'),
                  onSelected: (_) => stockNotifier.setStatusFilter(null),
                ),
                const SizedBox(width: KiranaSpacing.xs),
                ...StockStatus.values.map((status) {
                  final isSelected = stockState.filter.statusFilter == status;
                  return Padding(
                    padding: const EdgeInsets.only(right: KiranaSpacing.xs),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(status.label),
                      onSelected: (_) => stockNotifier.setStatusFilter(status),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: KiranaSpacing.xs),

          // Stock List
          Expanded(
            child: stockState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : stockState.errorMessage != null && products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: KiranaColors.error),
                            const SizedBox(height: KiranaSpacing.xs),
                            Text(stockState.errorMessage!,
                                style: KiranaTypography.bodyMedium),
                            ElevatedButton(
                              onPressed: () =>
                                  stockNotifier.loadStock(refresh: true),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : products.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.inventory_2_outlined,
                                    size: 48, color: KiranaColors.textMuted),
                                const SizedBox(height: KiranaSpacing.xs),
                                Text(
                                  stockState.filter.hasActiveFilters
                                      ? 'No stock records match search/filters.'
                                      : 'No products registered in inventory.',
                                  style: KiranaTypography.bodyMedium,
                                ),
                              ],
                            ),
                          )
                        : NotificationListener<ScrollNotification>(
                            onNotification: (scrollInfo) {
                              if (scrollInfo.metrics.pixels >=
                                      scrollInfo.metrics.maxScrollExtent -
                                          200 &&
                                  stockState.hasMore &&
                                  !stockState.isLoadingMore) {
                                stockNotifier.loadMore();
                              }
                              return false;
                            },
                            child: RefreshIndicator(
                              onRefresh: () async {
                                await stockNotifier.loadStock(refresh: true);
                              },
                              child: ListView.separated(
                                padding: const EdgeInsets.all(KiranaSpacing.md),
                                itemCount: products.length +
                                    (stockState.hasMore ? 1 : 0),
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: KiranaSpacing.xs),
                                itemBuilder: (context, index) {
                                  if (index == products.length) {
                                    return const Center(
                                      child: Padding(
                                        padding:
                                            EdgeInsets.all(KiranaSpacing.md),
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }

                                  final p = products[index];
                                  final status = p.stockStatus;

                                  Color statusColor;
                                  switch (status) {
                                    case StockStatus.inStock:
                                      statusColor = KiranaColors.success;
                                    case StockStatus.lowStock:
                                      statusColor = KiranaColors.warning;
                                    case StockStatus.outOfStock:
                                      statusColor = KiranaColors.error;
                                  }

                                  return Card(
                                    elevation: 1,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: KiranaSpacing.md,
                                        vertical: KiranaSpacing.xs,
                                      ),
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              p.name,
                                              style:
                                                  KiranaTypography.titleMedium,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: statusColor.withValues(
                                                  alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              status.label,
                                              style: KiranaTypography.labelSmall
                                                  .copyWith(
                                                color: statusColor,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      subtitle: Text(
                                        '${p.currentStock} ${p.unit} • Min Alert: ${p.minStockAlert} ${p.unit}${p.hsnCode != null ? " • HSN: ${p.hsnCode}" : ""}',
                                        style: KiranaTypography.bodySmall,
                                      ),
                                      trailing: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            p.sellingPricePaise
                                                .toRupeesString(),
                                            style: KiranaTypography.priceTabular
                                                .copyWith(
                                              color: KiranaColors.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const Icon(Icons.chevron_right,
                                              size: 16),
                                        ],
                                      ),
                                      onTap: () => _openStockDetails(p),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: KiranaTypography.titleMedium.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: KiranaTypography.labelSmall.copyWith(
                fontSize: 10,
                color: KiranaColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
