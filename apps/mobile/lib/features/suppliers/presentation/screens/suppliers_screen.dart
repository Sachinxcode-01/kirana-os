import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../purchases/domain/models/purchase_model.dart';
import '../../../purchases/presentation/screens/record_purchase_screen.dart';
import '../../../purchases/presentation/widgets/purchase_details_modal.dart';
import '../../domain/models/supplier_model.dart';
import '../providers/supplier_provider.dart';
import '../widgets/add_edit_supplier_dialog.dart';

import '../widgets/record_supplier_payment_dialog.dart';
import '../widgets/supplier_details_modal.dart';

class SuppliersScreen extends ConsumerStatefulWidget {
  const SuppliersScreen({super.key});

  @override
  ConsumerState<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends ConsumerState<SuppliersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
        if (_tabController.index != 2) {
          final includeArchived = _tabController.index == 1;
          ref
              .read(suppliersListNotifierProvider.notifier)
              .setIncludeArchived(includeArchived);
        }
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      ref.read(suppliersListNotifierProvider.notifier).setSearchQuery(query);
    });
  }

  void _openAddSupplierDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const AddEditSupplierDialog(),
    );
  }

  void _openSupplierDetails(BuildContext context, SupplierModel supplier) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: KiranaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SupplierDetailsModal(supplier: supplier),
    );
  }

  static String _formatRupees(int paise) {
    final double rupees = paise / 100.0;
    return '₹${rupees.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(suppliersListNotifierProvider);
    final allSuppliers = listState.suppliers;
    final tabIndex = _tabController.index;

    final suppliers = tabIndex == 1
        ? allSuppliers.where((s) => s.isArchived).toList()
        : allSuppliers.where((s) => !s.isArchived).toList();

    final localDataSource = ref.watch(supplierLocalDataSourceProvider);
    final shopId = ref.watch(activeShopIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Supplier & Stock Purchases'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active Suppliers'),
            Tab(text: 'Archived'),
            Tab(text: 'Purchase Invoices'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(suppliersListNotifierProvider.notifier).loadSuppliers();
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: KiranaColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => const RecordPurchaseScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add_shopping_cart, size: 18),
            label: const Text('+ Stock In'),
          ),
          const SizedBox(width: KiranaSpacing.xs),
        ],
      ),
      body: Column(
        children: [
          if (tabIndex != 2) ...[
            // Debounced Search Bar
            Padding(
              padding: const EdgeInsets.all(KiranaSpacing.md),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search supplier by name, phone, or GSTIN...',
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

            // Suppliers List Tab 0 & 1
            Expanded(
              child: listState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : listState.errorMessage != null && suppliers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 48, color: KiranaColors.error),
                              const SizedBox(height: KiranaSpacing.xs),
                              Text(listState.errorMessage!,
                                  style: KiranaTypography.bodyMedium),
                              ElevatedButton(
                                onPressed: () {
                                  ref
                                      .read(suppliersListNotifierProvider
                                          .notifier)
                                      .loadSuppliers();
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : suppliers.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.people_outline,
                                      size: 48, color: KiranaColors.textMuted),
                                  const SizedBox(height: KiranaSpacing.xs),
                                  Text(
                                    _searchController.text.isNotEmpty
                                        ? 'No suppliers found for "${_searchController.text}"'
                                        : tabIndex == 1
                                            ? 'No archived suppliers'
                                            : 'No active suppliers registered yet',
                                    style: KiranaTypography.bodyMedium,
                                  ),
                                  const SizedBox(height: KiranaSpacing.sm),
                                  if (tabIndex == 0)
                                    ElevatedButton.icon(
                                      onPressed: () =>
                                          _openAddSupplierDialog(context),
                                      icon: const Icon(Icons.add),
                                      label: const Text('Add New Supplier'),
                                    ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () async {
                                await ref
                                    .read(
                                        suppliersListNotifierProvider.notifier)
                                    .loadSuppliers();
                              },
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: KiranaSpacing.md,
                                  vertical: KiranaSpacing.xs,
                                ),
                                itemCount: suppliers.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: KiranaSpacing.xs),
                                itemBuilder: (context, index) {
                                  final s = suppliers[index];
                                  final debtPaise = s.currentBalancePaise;

                                  return Card(
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: s.isArchived
                                            ? KiranaColors.neutral300
                                            : KiranaColors.primary
                                                .withValues(alpha: 0.1),
                                        child: Text(
                                          s.name.substring(0, 1).toUpperCase(),
                                          style: TextStyle(
                                            color: s.isArchived
                                                ? KiranaColors.neutral700
                                                : KiranaColors.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      title: Text(s.name,
                                          style: KiranaTypography.titleMedium
                                              .copyWith(
                                                  fontWeight: FontWeight.bold)),
                                      subtitle: Text(
                                        'Phone: ${s.phone}${s.contactPerson != null ? " • ${s.contactPerson}" : ""}${s.gstin != null ? " • GST: ${s.gstin}" : ""}',
                                        style: KiranaTypography.bodySmall,
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                debtPaise > 0
                                                    ? 'Owed ${_formatRupees(debtPaise)}'
                                                    : 'Clear',
                                                style: KiranaTypography
                                                    .titleMedium
                                                    .copyWith(
                                                  color: debtPaise > 0
                                                      ? KiranaColors.primary
                                                      : KiranaColors.success,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const Text('Payable Balance',
                                                  style: TextStyle(
                                                      fontSize: 10,
                                                      color: KiranaColors
                                                          .neutral600)),
                                            ],
                                          ),
                                          const SizedBox(
                                              width: KiranaSpacing.xs),
                                          if (debtPaise > 0)
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    KiranaColors.primary,
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 6),
                                                minimumSize: Size.zero,
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                              ),
                                              onPressed: () =>
                                                  RecordSupplierPaymentDialog
                                                      .show(context, s),
                                              child: const Text('Pay',
                                                  style:
                                                      TextStyle(fontSize: 12)),
                                            ),
                                        ],
                                      ),
                                      onTap: () =>
                                          _openSupplierDetails(context, s),
                                    ),
                                  );
                                },
                              ),
                            ),
            ),
          ] else ...[
            // Tab 2: Purchase Invoices List
            Expanded(
              child: StreamBuilder(
                stream: localDataSource.watchPurchases(shopId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final purchasesData = snapshot.data ?? [];
                  if (purchasesData.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.receipt_long_outlined,
                              size: 48, color: KiranaColors.neutral400),
                          const SizedBox(height: KiranaSpacing.sm),
                          Text('No purchase invoices recorded yet',
                              style: KiranaTypography.titleMedium),
                          const SizedBox(height: KiranaSpacing.xs),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (ctx) =>
                                      const RecordPurchaseScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add_shopping_cart),
                            label: const Text('Record Stock Purchase'),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(KiranaSpacing.md),
                    itemCount: purchasesData.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: KiranaSpacing.xs),
                    itemBuilder: (context, index) {
                      final pData = purchasesData[index];
                      final pModel = PurchaseModel(
                        id: pData.id,
                        shopId: pData.shopId,
                        supplierId: pData.supplierId,
                        supplierNameSnapshot: pData.supplierNameSnapshot,
                        invoiceNumber: pData.invoiceNumber,
                        invoiceDate: pData.invoiceDate,
                        subtotalPaise: pData.subtotalPaise.toInt(),
                        taxTotalPaise: pData.taxTotalPaise.toInt(),
                        totalPaise: pData.totalPaise.toInt(),
                        status: pData.status,
                        createdAt: pData.createdAt,
                      );

                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: KiranaColors.primaryContainer,
                            child: Icon(Icons.inventory,
                                color: KiranaColors.primary, size: 20),
                          ),
                          title: Text(
                            'Invoice #${pData.invoiceNumber}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${DateFormatter.formatDate(pData.invoiceDate)} • ${pData.supplierNameSnapshot ?? "General Vendor"}',
                            style: KiranaTypography.bodySmall,
                          ),
                          trailing: Text(
                            _formatRupees(pData.totalPaise.toInt()),
                            style: KiranaTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: KiranaColors.primary,
                            ),
                          ),
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(16)),
                              ),
                              builder: (ctx) =>
                                  PurchaseDetailsModal(purchase: pModel),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddSupplierDialog(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Supplier'),
      ),
    );
  }
}
