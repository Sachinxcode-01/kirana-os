import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../domain/models/supplier_model.dart';
import '../providers/supplier_provider.dart';
import '../widgets/add_edit_supplier_dialog.dart';
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
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
        final includeArchived = _tabController.index == 1;
        ref
            .read(suppliersListNotifierProvider.notifier)
            .setIncludeArchived(includeArchived);
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

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(suppliersListNotifierProvider);
    final allSuppliers = listState.suppliers;
    final isArchivedTab = _tabController.index == 1;

    final suppliers = isArchivedTab
        ? allSuppliers.where((s) => s.isArchived).toList()
        : allSuppliers.where((s) => !s.isArchived).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Supplier Directory'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active Suppliers'),
            Tab(text: 'Archived'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(suppliersListNotifierProvider.notifier).loadSuppliers();
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined),
            tooltip: 'Add Supplier',
            onPressed: () => _openAddSupplierDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
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

          // Suppliers List
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
                                    .read(
                                        suppliersListNotifierProvider.notifier)
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
                                      : isArchivedTab
                                          ? 'No archived suppliers'
                                          : 'No active suppliers registered yet',
                                  style: KiranaTypography.bodyMedium,
                                ),
                                const SizedBox(height: KiranaSpacing.sm),
                                if (!isArchivedTab)
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
                                  .read(suppliersListNotifierProvider.notifier)
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
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(s.name,
                                              style:
                                                  KiranaTypography.titleMedium),
                                        ),
                                        if (s.isArchived)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: KiranaColors.neutral300,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'ARCHIVED',
                                              style: KiranaTypography.labelSmall
                                                  .copyWith(fontSize: 10),
                                            ),
                                          ),
                                      ],
                                    ),
                                    subtitle: Text(
                                      'Phone: ${s.phone}${s.contactPerson != null ? " • ${s.contactPerson}" : ""}${s.gstin != null ? " • GST: ${s.gstin}" : ""}',
                                      style: KiranaTypography.bodySmall,
                                    ),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () =>
                                        _openSupplierDetails(context, s),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
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
