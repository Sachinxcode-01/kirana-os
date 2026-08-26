import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../domain/models/supplier_model.dart';
import '../providers/supplier_provider.dart';

class SupplierSelectorSheet extends ConsumerStatefulWidget {
  final ValueChanged<SupplierModel?> onSupplierSelected;
  final SupplierModel? currentSupplier;

  const SupplierSelectorSheet({
    super.key,
    required this.onSupplierSelected,
    this.currentSupplier,
  });

  @override
  ConsumerState<SupplierSelectorSheet> createState() =>
      _SupplierSelectorSheetState();
}

class _SupplierSelectorSheetState extends ConsumerState<SupplierSelectorSheet> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(suppliersListNotifierProvider);
    final suppliers = listState.suppliers.where((s) => !s.isArchived).toList();

    final query = _searchController.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? suppliers
        : suppliers.where((s) {
            final nameMatch = s.name.toLowerCase().contains(query);
            final phoneMatch = s.phone.contains(query);
            final gstinMatch =
                s.gstin != null && s.gstin!.toLowerCase().contains(query);
            return nameMatch || phoneMatch || gstinMatch;
          }).toList();

    return Container(
      padding: EdgeInsets.only(
        top: KiranaSpacing.md,
        left: KiranaSpacing.md,
        right: KiranaSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + KiranaSpacing.md,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Select Supplier for Purchase',
                  style: KiranaTypography.titleLarge),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: KiranaSpacing.xs),

          // Search input
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search supplier by name, phone, GSTIN...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
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
          const SizedBox(height: KiranaSpacing.sm),

          // Clear selection option
          ListTile(
            leading: const Icon(Icons.person_off_outlined),
            title: const Text('No Supplier / General Procurement'),
            selected: widget.currentSupplier == null,
            onTap: () {
              widget.onSupplierSelected(null);
              Navigator.of(context).pop();
            },
          ),
          const Divider(height: 1),

          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      query.isNotEmpty
                          ? 'No active supplier found for "$query"'
                          : 'No active suppliers available',
                      style: KiranaTypography.bodyMedium,
                    ),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(
                        height: 1, color: KiranaColors.outlineVariant),
                    itemBuilder: (context, index) {
                      final supplier = filtered[index];
                      final isSelected =
                          widget.currentSupplier?.id == supplier.id;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              KiranaColors.primary.withValues(alpha: 0.1),
                          child: Text(
                            supplier.name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                                color: KiranaColors.primary,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(supplier.name,
                            style: KiranaTypography.titleMedium),
                        subtitle: Text(
                          'Phone: ${supplier.phone}${supplier.gstin != null ? " • GSTIN: ${supplier.gstin}" : ""}',
                          style: KiranaTypography.bodySmall,
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle,
                                color: KiranaColors.primary)
                            : null,
                        onTap: () {
                          widget.onSupplierSelected(supplier);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
