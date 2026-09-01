import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kirana_mobile/app/app_providers.dart';
import 'package:kirana_mobile/core/network/connectivity_status.dart';
import 'package:kirana_mobile/core/theme/colors.dart';
import 'package:kirana_mobile/core/theme/radius.dart';
import 'package:kirana_mobile/core/theme/spacing.dart';
import 'package:kirana_mobile/core/theme/typography.dart';
import 'package:kirana_mobile/core/widgets/animated_list_item.dart';
import 'package:kirana_mobile/core/widgets/app_text_field.dart';
import 'package:kirana_mobile/core/widgets/empty_state.dart';
import 'package:kirana_mobile/core/widgets/error_view.dart';
import 'package:kirana_mobile/core/widgets/state_transition_switcher.dart';
import 'package:kirana_mobile/features/categories/presentation/providers/category_provider.dart';
import 'package:kirana_mobile/features/products/domain/models/product_model.dart';
import 'package:kirana_mobile/features/products/presentation/providers/product_provider.dart';
import '../../domain/models/stock_status.dart';
import '../providers/inventory_provider.dart';
import '../widgets/inventory_settings_dialog.dart';
import '../widgets/stock_adjustment_sheet.dart';
import 'inventory_history_screen.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connectivityAsync = ref.watch(connectivityStatusStreamProvider);
    final isOffline =
        connectivityAsync.asData?.value == ConnectivityStatus.offline;

    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final selectedCategory = ref.watch(inventoryCategoryFilterProvider);
    final selectedStatusFilter = ref.watch(inventoryStatusFilterProvider);
    final filteredProductsAsync =
        ref.watch(inventoryFilteredProductsStreamProvider);
    final allProductsAsync = ref.watch(productsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Configuration'),
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
          ref.invalidate(inventoryFilteredProductsStreamProvider);
          ref.invalidate(productsStreamProvider);
          ref.invalidate(lowStockProductsProvider);
        },
        child: Column(
          children: [
            // 1. Offline Banner Indicator
            if (isOffline)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: KiranaSpacing.md,
                  vertical: KiranaSpacing.xs,
                ),
                color: KiranaColors.warningContainer,
                child: Row(
                  children: [
                    const Icon(
                      Icons.wifi_off,
                      size: 16,
                      color: KiranaColors.warning,
                    ),
                    const SizedBox(width: KiranaSpacing.xs),
                    Expanded(
                      child: Text(
                        'OFFLINE MODE — Displaying cached inventory data from local database.',
                        style: KiranaTypography.bodySmall.copyWith(
                          color: KiranaColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(KiranaSpacing.md),
                children: [
                  // 2. Search Bar
                  AppTextField(
                    hint: 'Search product by name, brand, regional name...',
                    controller: _searchController,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(inventorySearchQueryProvider.notifier)
                                  .state = '';
                              setState(() {});
                            },
                          )
                        : null,
                    onChanged: (val) {
                      ref.read(inventorySearchQueryProvider.notifier).state =
                          val;
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: KiranaSpacing.md),

                  // 3. Stock Overview Quick Metrics
                  allProductsAsync.when(
                    data: (products) {
                      final totalCount = products.length;
                      final inStockCount = products.where((p) {
                        final status = StockStatus.fromQuantities(
                            p.currentStock, p.minStockAlert);
                        return status == StockStatus.inStock;
                      }).length;
                      final lowStockCount = products.where((p) {
                        final status = StockStatus.fromQuantities(
                            p.currentStock, p.minStockAlert);
                        return status == StockStatus.lowStock;
                      }).length;
                      final outOfStockCount = products.where((p) {
                        final status = StockStatus.fromQuantities(
                            p.currentStock, p.minStockAlert);
                        return status == StockStatus.outOfStock;
                      }).length;

                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _MetricCard(
                                  title: 'Total Catalog',
                                  value: '$totalCount',
                                  color: KiranaColors.primary,
                                  icon: Icons.inventory_2_outlined,
                                ),
                              ),
                              const SizedBox(width: KiranaSpacing.sm),
                              Expanded(
                                child: _MetricCard(
                                  title: 'In Stock',
                                  value: '$inStockCount',
                                  color: KiranaColors.secondary,
                                  icon: Icons.check_circle_outline,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: KiranaSpacing.sm),
                          Row(
                            children: [
                              Expanded(
                                child: _MetricCard(
                                  title: 'Low Stock',
                                  value: '$lowStockCount',
                                  color: KiranaColors.warning,
                                  icon: Icons.warning_amber_rounded,
                                ),
                              ),
                              const SizedBox(width: KiranaSpacing.sm),
                              Expanded(
                                child: _MetricCard(
                                  title: 'Out of Stock',
                                  value: '$outOfStockCount',
                                  color: KiranaColors.error,
                                  icon: Icons.error_outline,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: KiranaSpacing.lg),

                  // 4. Category Filter Chips (Horizontal)
                  categoriesAsync.when(
                    data: (categories) {
                      if (categories.isEmpty) return const SizedBox.shrink();
                      return SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                  right: KiranaSpacing.xs),
                              child: ChoiceChip(
                                label: const Text('All Categories'),
                                selected: selectedCategory == null,
                                onSelected: (_) {
                                  ref
                                      .read(inventoryCategoryFilterProvider
                                          .notifier)
                                      .state = null;
                                },
                              ),
                            ),
                            ...categories.map((cat) {
                              final isSelected = selectedCategory == cat.id;
                              return Padding(
                                padding: const EdgeInsets.only(
                                    right: KiranaSpacing.xs),
                                child: ChoiceChip(
                                  label: Text(cat.name),
                                  selected: isSelected,
                                  onSelected: (_) {
                                    ref
                                        .read(inventoryCategoryFilterProvider
                                            .notifier)
                                        .state = isSelected ? null : cat.id;
                                  },
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: KiranaSpacing.sm),

                  // 5. Stock Status Filter Chips (ALL, IN STOCK, LOW STOCK, OUT OF STOCK)
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: StockStatusFilter.values.map((statusFilter) {
                        final isSelected = selectedStatusFilter == statusFilter;
                        return Padding(
                          padding:
                              const EdgeInsets.only(right: KiranaSpacing.xs),
                          child: FilterChip(
                            label: Text(statusFilter.label),
                            selected: isSelected,
                            selectedColor: KiranaColors.primaryContainer,
                            onSelected: (_) {
                              ref
                                  .read(inventoryStatusFilterProvider.notifier)
                                  .state = statusFilter;
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: KiranaSpacing.lg),

                  // 6. Filtered Inventory List with StateTransitionSwitcher
                  StateTransitionSwitcher(
                    child: filteredProductsAsync.when(
                      data: (products) {
                        if (products.isEmpty) {
                          return Padding(
                            key: const ValueKey('empty_state'),
                            padding: const EdgeInsets.symmetric(
                                vertical: KiranaSpacing.xl),
                            child: EmptyState(
                              icon: Icons.inventory_outlined,
                              title: 'No inventory items match active filters',
                              description:
                                  'Try adjusting your search query, category, or stock status filter.',
                              actionLabel: 'Reset Filters',
                              onAction: () {
                                _searchController.clear();
                                ref
                                    .read(inventorySearchQueryProvider.notifier)
                                    .state = '';
                                ref
                                    .read(inventoryCategoryFilterProvider
                                        .notifier)
                                    .state = null;
                                ref
                                    .read(
                                        inventoryStatusFilterProvider.notifier)
                                    .state = StockStatusFilter.all;
                                setState(() {});
                              },
                            ),
                          );
                        }

                        return Column(
                          key: const ValueKey('inventory_list'),
                          children: products.asMap().entries.map((entry) {
                            final index = entry.key;
                            final product = entry.value;
                            return AnimatedListItem(
                              key: ValueKey(product.id),
                              index: index,
                              child: _InventoryProductCard(
                                key: ValueKey(product.id),
                                product: product,
                                onSettingsTap: () async {
                                  final updated =
                                      await InventorySettingsDialog.show(
                                          context, product);
                                  if (updated == true) {
                                    ref.invalidate(
                                        inventoryFilteredProductsStreamProvider);
                                    ref.invalidate(productsStreamProvider);
                                    ref.invalidate(lowStockProductsProvider);
                                  }
                                },
                                onAdjustTap: () async {
                                  final adjusted =
                                      await StockAdjustmentSheet.show(
                                          context, product);
                                  if (adjusted == true) {
                                    ref.invalidate(
                                        inventoryFilteredProductsStreamProvider);
                                    ref.invalidate(productsStreamProvider);
                                    ref.invalidate(lowStockProductsProvider);
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        );
                      },
                      loading: () => const Center(
                        key: ValueKey('loading'),
                        child: Padding(
                          padding: EdgeInsets.all(KiranaSpacing.xl),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (err, _) => ErrorView(
                        key: const ValueKey('error'),
                        customMessage: 'Error loading inventory: $err',
                        onRetry: () {
                          ref.invalidate(
                              inventoryFilteredProductsStreamProvider);
                          ref.invalidate(productsStreamProvider);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(KiranaSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: KiranaRadius.borderMd,
        border: Border.all(color: KiranaColors.neutral200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: KiranaSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: KiranaTypography.bodySmall.copyWith(
                      color: KiranaColors.textSecondary, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: KiranaTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: KiranaColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onSettingsTap;
  final VoidCallback onAdjustTap;

  const _InventoryProductCard({
    super.key,
    required this.product,
    required this.onSettingsTap,
    required this.onAdjustTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = StockStatus.fromQuantities(
      product.currentStock,
      product.minStockAlert,
    );

    final formattedQuantity = StockUnitFormatter.formatWithUnit(
      product.currentStock,
      product.unit,
    );

    final formattedMin =
        StockUnitFormatter.formatQuantity(product.minStockAlert);
    final formattedMax = product.maxStockAlert != null
        ? StockUnitFormatter.formatQuantity(product.maxStockAlert!)
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: KiranaSpacing.sm),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: KiranaRadius.borderMd,
        side: const BorderSide(color: KiranaColors.neutral200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(KiranaSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Status Icon Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: status.containerColor,
                shape: BoxShape.circle,
              ),
              child: Icon(status.icon, color: status.badgeColor, size: 24),
            ),
            const SizedBox(width: KiranaSpacing.md),

            // Product & Stock Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: KiranaTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),

                  // Stock Quantity & Unit
                  Row(
                    children: [
                      Text(
                        'Stock: ',
                        style: KiranaTypography.bodySmall.copyWith(
                          color: KiranaColors.textSecondary,
                        ),
                      ),
                      Text(
                        formattedQuantity,
                        style: KiranaTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: status.badgeColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),

                  // Min & Max stock indicators
                  Text(
                    formattedMax != null
                        ? 'Min: $formattedMin ${product.unit.toLowerCase()} | Max: $formattedMax ${product.unit.toLowerCase()}'
                        : 'Min Safety: $formattedMin ${product.unit.toLowerCase()}',
                    style: KiranaTypography.bodySmall.copyWith(
                      color: KiranaColors.neutral600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            // Stock Status Badge & Actions
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Status Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: status.containerColor,
                    borderRadius: KiranaRadius.borderPill,
                    border: Border.all(
                      color: status.badgeColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    status.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: status.badgeColor,
                    ),
                  ),
                ),
                const SizedBox(height: KiranaSpacing.xs),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.settings_outlined, size: 20),
                      tooltip: 'Inventory Settings',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(6),
                      onPressed: onSettingsTap,
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KiranaColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(60, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      onPressed: onAdjustTap,
                      child:
                          const Text('Adjust', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
