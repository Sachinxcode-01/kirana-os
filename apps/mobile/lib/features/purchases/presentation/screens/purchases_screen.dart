import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/num_extensions.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../suppliers/domain/models/supplier_model.dart';
import '../../../suppliers/presentation/providers/supplier_provider.dart';
import '../../domain/models/purchase_history_filter.dart';
import '../../domain/models/purchase_model.dart';
import '../providers/purchase_history_provider.dart';
import '../providers/purchase_provider.dart';
import '../widgets/purchase_details_modal.dart';
import 'purchase_draft_screen.dart';

class PurchasesScreen extends ConsumerStatefulWidget {
  const PurchasesScreen({super.key});

  @override
  ConsumerState<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends ConsumerState<PurchasesScreen> {
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
      ref.read(purchaseHistoryNotifierProvider.notifier).setSearchQuery(query);
    });
  }

  void _openPurchaseDraft([PurchaseModel? draft]) {
    if (draft == null) {
      ref.read(purchaseDraftNotifierProvider.notifier).initNewDraft();
    } else {
      ref.read(purchaseDraftNotifierProvider.notifier).loadDraft(draft);
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PurchaseDraftScreen(purchaseId: draft?.id),
      ),
    );
  }

  void _openPurchaseDetails(PurchaseModel purchase) {
    if (purchase.isDraft) {
      _openPurchaseDraft(purchase);
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: KiranaColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => PurchaseDetailsModal(purchase: purchase),
      );
    }
  }

  Future<void> _pickDateRange() async {
    final historyState = ref.read(purchaseHistoryNotifierProvider);
    final initialRange = historyState.filter.dateRange ??
        DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 7)),
          end: DateTime.now(),
        );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: initialRange,
    );

    if (picked != null) {
      ref.read(purchaseHistoryNotifierProvider.notifier).setDateRange(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(purchaseHistoryNotifierProvider);
    final historyNotifier = ref.read(purchaseHistoryNotifierProvider.notifier);
    final suppliersList = ref.watch(suppliersListNotifierProvider).suppliers;
    final purchases = historyState.purchases;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase History & Inward Goods'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => historyNotifier.loadPurchases(refresh: true),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New Purchase',
            onPressed: () => _openPurchaseDraft(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Offline Banner
          if (historyState.isOffline)
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
                      'Offline · Showing saved purchases',
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
                hintText: 'Search by purchase #, supplier, or invoice...',
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

          // Composable Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: KiranaSpacing.md),
            child: Row(
              children: [
                // Status Filter Chips
                ...PurchaseStatusFilter.values.map((status) {
                  final isSelected = historyState.filter.statusFilter == status;
                  return Padding(
                    padding: const EdgeInsets.only(right: KiranaSpacing.xs),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(status.label),
                      onSelected: (_) =>
                          historyNotifier.setStatusFilter(status),
                    ),
                  );
                }),

                const SizedBox(width: KiranaSpacing.xs),
                // Date Range Filter Chip
                FilterChip(
                  selected: historyState.filter.dateRange != null,
                  avatar: const Icon(Icons.date_range, size: 16),
                  label: Text(
                    historyState.filter.dateRange == null
                        ? 'Date Range'
                        : '${DateFormatter.formatDate(historyState.filter.dateRange!.start)} - ${DateFormatter.formatDate(historyState.filter.dateRange!.end)}',
                  ),
                  onSelected: (_) => _pickDateRange(),
                  onDeleted: historyState.filter.dateRange != null
                      ? () => historyNotifier.setDateRange(null)
                      : null,
                ),

                const SizedBox(width: KiranaSpacing.xs),
                // Supplier Filter Dropdown Chip
                PopupMenuButton<String?>(
                  initialValue: historyState.filter.supplierId,
                  onSelected: (suppId) =>
                      historyNotifier.setSupplierFilter(suppId),
                  itemBuilder: (context) => [
                    const PopupMenuItem<String?>(
                      value: null,
                      child: Text('All Suppliers'),
                    ),
                    ...suppliersList.map(
                      (s) => PopupMenuItem<String?>(
                        value: s.id,
                        child: Text(s.name),
                      ),
                    ),
                  ],
                  child: Chip(
                    avatar: const Icon(Icons.business, size: 16),
                    label: Text(
                      historyState.filter.supplierId == null
                          ? 'Supplier'
                          : suppliersList
                              .firstWhere(
                                (s) => s.id == historyState.filter.supplierId,
                                orElse: () => SupplierModel(
                                  id: '',
                                  shopId: '',
                                  name: 'Selected Supplier',
                                  phone: '',
                                  createdAt: DateTime.now(),
                                  updatedAt: DateTime.now(),
                                ),
                              )
                              .name,
                    ),
                    deleteIcon: historyState.filter.supplierId != null
                        ? const Icon(Icons.cancel, size: 16)
                        : null,
                    onDeleted: historyState.filter.supplierId != null
                        ? () => historyNotifier.setSupplierFilter(null)
                        : null,
                  ),
                ),

                if (historyState.filter.hasActiveFilters) ...[
                  const SizedBox(width: KiranaSpacing.xs),
                  TextButton.icon(
                    onPressed: () => historyNotifier.clearFilters(),
                    icon: const Icon(Icons.filter_alt_off, size: 16),
                    label: const Text('Clear All'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: KiranaSpacing.xs),

          // Purchase List
          Expanded(
            child: historyState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : historyState.errorMessage != null && purchases.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: KiranaColors.error),
                            const SizedBox(height: KiranaSpacing.xs),
                            Text(historyState.errorMessage!,
                                style: KiranaTypography.bodyMedium),
                            ElevatedButton(
                              onPressed: () =>
                                  historyNotifier.loadPurchases(refresh: true),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : purchases.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.local_shipping_outlined,
                                    size: 48, color: KiranaColors.textMuted),
                                const SizedBox(height: KiranaSpacing.xs),
                                Text(
                                  historyState.filter.hasActiveFilters
                                      ? 'No purchase records match your search/filters.'
                                      : 'No purchase records found.',
                                  style: KiranaTypography.bodyMedium,
                                ),
                                const SizedBox(height: KiranaSpacing.sm),
                                ElevatedButton.icon(
                                  onPressed: () => _openPurchaseDraft(),
                                  icon: const Icon(Icons.add),
                                  label:
                                      const Text('Create New Purchase Inward'),
                                ),
                              ],
                            ),
                          )
                        : NotificationListener<ScrollNotification>(
                            onNotification: (scrollInfo) {
                              if (scrollInfo.metrics.pixels >=
                                      scrollInfo.metrics.maxScrollExtent -
                                          200 &&
                                  historyState.hasMore &&
                                  !historyState.isLoadingMore) {
                                historyNotifier.loadMore();
                              }
                              return false;
                            },
                            child: RefreshIndicator(
                              onRefresh: () async {
                                await historyNotifier.loadPurchases(
                                    refresh: true);
                              },
                              child: ListView.separated(
                                padding: const EdgeInsets.all(KiranaSpacing.md),
                                itemCount: purchases.length +
                                    (historyState.hasMore ? 1 : 0),
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: KiranaSpacing.xs),
                                itemBuilder: (context, index) {
                                  if (index == purchases.length) {
                                    return const Center(
                                      child: Padding(
                                        padding:
                                            EdgeInsets.all(KiranaSpacing.md),
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }

                                  final p = purchases[index];
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
                                          Text(
                                            '#${p.purchaseNumber}',
                                            style: KiranaTypography.titleMedium,
                                          ),
                                          const SizedBox(
                                              width: KiranaSpacing.xs),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: p.isCompleted
                                                  ? KiranaColors.success
                                                      .withValues(alpha: 0.15)
                                                  : KiranaColors.warning
                                                      .withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              p.status.toUpperCase(),
                                              style: KiranaTypography.labelSmall
                                                  .copyWith(
                                                color: p.isCompleted
                                                    ? KiranaColors.success
                                                    : KiranaColors.warning,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      subtitle: Text(
                                        '${p.supplierName ?? "General Procurement"}${p.supplierReference != null ? " (${p.supplierReference})" : ""} • ${p.items.length} items • ${DateFormatter.formatDate(p.createdAt)}',
                                        style: KiranaTypography.bodySmall,
                                      ),
                                      trailing: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            p.totalPaise.toRupeesString(),
                                            style: KiranaTypography.priceTabular
                                                .copyWith(
                                              color: KiranaColors.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Icon(
                                            p.isCompleted
                                                ? Icons.inventory_2_outlined
                                                : Icons.edit_note,
                                            size: 16,
                                            color: p.isCompleted
                                                ? KiranaColors.success
                                                : KiranaColors.secondary,
                                          ),
                                        ],
                                      ),
                                      onTap: () => _openPurchaseDetails(p),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openPurchaseDraft(),
        icon: const Icon(Icons.add),
        label: const Text('New Purchase'),
      ),
    );
  }
}
