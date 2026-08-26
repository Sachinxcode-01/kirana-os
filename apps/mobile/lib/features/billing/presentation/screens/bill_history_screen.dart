import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/num_extensions.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/models/bill_history_filter.dart';
import '../../domain/models/bill_model.dart';
import '../providers/bill_history_provider.dart';
import '../widgets/bill_details_modal.dart';

class BillHistoryScreen extends ConsumerStatefulWidget {
  const BillHistoryScreen({super.key});

  @override
  ConsumerState<BillHistoryScreen> createState() => _BillHistoryScreenState();
}

class _BillHistoryScreenState extends ConsumerState<BillHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(billHistoryNotifierProvider.notifier).loadNextPage();
    }
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final historyNotifier = ref.read(billHistoryNotifierProvider.notifier);
    final historyState = ref.read(billHistoryNotifierProvider);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: historyState.filter.dateRange,
    );

    if (picked != null) {
      historyNotifier.setDateRange(picked);
    }
  }

  void _showBillDetails(BuildContext context, BillModel bill) {
    ref.read(billHistoryNotifierProvider.notifier).selectBill(bill);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: KiranaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => BillDetailsModal(bill: bill),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(billHistoryNotifierProvider);
    final notifier = ref.read(billHistoryNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Bills',
            onPressed: () => notifier.loadBills(refresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Offline Banner Indicator
          if (state.isOffline)
            Container(
              width: double.infinity,
              color: KiranaColors.warning.withValues(alpha: 0.15),
              padding: const EdgeInsets.symmetric(
                horizontal: KiranaSpacing.md,
                vertical: KiranaSpacing.xs,
              ),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off,
                      size: 16, color: KiranaColors.warning),
                  const SizedBox(width: KiranaSpacing.xs),
                  Text(
                    'Offline · Showing saved bills',
                    style: KiranaTypography.bodySmall.copyWith(
                      color: KiranaColors.warning,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          // 2. Search Bar
          Padding(
            padding: const EdgeInsets.all(KiranaSpacing.md),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => notifier.setSearch(val),
              decoration: InputDecoration(
                hintText: 'Search by bill #, customer name or phone...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          notifier.setSearch('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: KiranaSpacing.md,
                  vertical: KiranaSpacing.xs,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // 3. Composable Filter Chips Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: KiranaSpacing.md),
            child: Row(
              children: [
                // Date Range Filter Chip
                FilterChip(
                  label: Text(
                    state.filter.dateRange == null
                        ? 'Date Range'
                        : '${DateFormatter.formatDate(state.filter.dateRange!.start)} - ${DateFormatter.formatDate(state.filter.dateRange!.end)}',
                  ),
                  selected: state.filter.dateRange != null,
                  onSelected: (_) => state.filter.dateRange != null
                      ? notifier.setDateRange(null)
                      : _pickDateRange(context),
                  avatar: Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: state.filter.dateRange != null
                        ? KiranaColors.primary
                        : KiranaColors.textSecondary,
                  ),
                ),
                const SizedBox(width: KiranaSpacing.xs),

                // Payment Method Filter Popup
                PopupMenuButton<PaymentFilter>(
                  initialValue: state.filter.paymentFilter,
                  onSelected: (val) => notifier.setPaymentFilter(val),
                  itemBuilder: (ctx) => PaymentFilter.values.map((p) {
                    return PopupMenuItem(
                      value: p,
                      child: Text('Payment: ${p.label}'),
                    );
                  }).toList(),
                  child: Chip(
                    avatar: const Icon(Icons.payment, size: 16),
                    label: Text('Payment: ${state.filter.paymentFilter.label}'),
                    backgroundColor:
                        state.filter.paymentFilter != PaymentFilter.all
                            ? KiranaColors.primaryContainer
                            : null,
                  ),
                ),
                const SizedBox(width: KiranaSpacing.xs),

                // Status Filter Popup
                PopupMenuButton<BillStatusFilter>(
                  initialValue: state.filter.statusFilter,
                  onSelected: (val) => notifier.setStatusFilter(val),
                  itemBuilder: (ctx) => BillStatusFilter.values.map((s) {
                    return PopupMenuItem(
                      value: s,
                      child: Text('Status: ${s.label}'),
                    );
                  }).toList(),
                  child: Chip(
                    avatar: const Icon(Icons.info_outline, size: 16),
                    label: Text('Status: ${state.filter.statusFilter.label}'),
                    backgroundColor:
                        state.filter.statusFilter != BillStatusFilter.all
                            ? KiranaColors.primaryContainer
                            : null,
                  ),
                ),
                const SizedBox(width: KiranaSpacing.xs),

                // Reset Filters Chip
                if (state.filter.hasActiveFilters)
                  ActionChip(
                    avatar: const Icon(Icons.filter_alt_off, size: 16),
                    label: const Text('Reset Filters'),
                    onPressed: () {
                      _searchController.clear();
                      notifier.resetFilters();
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: KiranaSpacing.xs),

          // 4. Bills List View
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.errorMessage != null && state.bills.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: KiranaColors.error),
                            const SizedBox(height: KiranaSpacing.xs),
                            Text(state.errorMessage!,
                                style: KiranaTypography.bodyMedium),
                            ElevatedButton(
                              onPressed: () =>
                                  notifier.loadBills(refresh: true),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : state.bills.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.receipt_long_outlined,
                                    size: 48, color: KiranaColors.textMuted),
                                const SizedBox(height: KiranaSpacing.xs),
                                Text(
                                  state.filter.hasActiveFilters
                                      ? 'No bills match the selected filters.'
                                      : 'No historical bills found.',
                                  style: KiranaTypography.bodyMedium,
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => notifier.loadBills(refresh: true),
                            child: ListView.separated(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(KiranaSpacing.md),
                              itemCount: state.bills.length +
                                  (state.isLoadingMore ? 1 : 0),
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: KiranaSpacing.xs),
                              itemBuilder: (context, index) {
                                if (index >= state.bills.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(KiranaSpacing.md),
                                    child: Center(
                                        child: CircularProgressIndicator()),
                                  );
                                }

                                final bill = state.bills[index];
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  child: Card(
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
                                            '#${bill.billNumber}',
                                            style: KiranaTypography.titleMedium,
                                          ),
                                          const SizedBox(
                                              width: KiranaSpacing.xs),
                                          _buildStatusBadge(bill.status),
                                        ],
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 2),
                                          Text(
                                            'Customer: ${bill.customerName ?? "Walk-in"} • ${DateFormatter.formatDateTime(bill.createdAt)}',
                                            style: KiranaTypography.bodySmall,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Cashier: ${bill.cashierId}',
                                            style: KiranaTypography.labelSmall
                                                .copyWith(
                                              color: KiranaColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            bill.totalPaise.toRupeesString(),
                                            style: KiranaTypography.priceTabular
                                                .copyWith(
                                              color: KiranaColors.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            bill.paymentStatus.toUpperCase(),
                                            style: KiranaTypography.labelSmall
                                                .copyWith(
                                              color: KiranaColors.success,
                                            ),
                                          ),
                                        ],
                                      ),
                                      onTap: () =>
                                          _showBillDetails(context, bill),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final isCancelled = status.toLowerCase() == 'cancelled';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isCancelled
            ? KiranaColors.error.withValues(alpha: 0.15)
            : KiranaColors.success.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style: KiranaTypography.labelSmall.copyWith(
          color: isCancelled ? KiranaColors.error : KiranaColors.success,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
