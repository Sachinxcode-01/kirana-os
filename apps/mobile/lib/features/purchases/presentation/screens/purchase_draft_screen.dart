import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/num_extensions.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/purchase_provider.dart';
import '../widgets/purchase_product_search_sheet.dart';

class PurchaseDraftScreen extends ConsumerStatefulWidget {
  final String? purchaseId;

  const PurchaseDraftScreen({super.key, this.purchaseId});

  @override
  ConsumerState<PurchaseDraftScreen> createState() =>
      _PurchaseDraftScreenState();
}

class _PurchaseDraftScreenState extends ConsumerState<PurchaseDraftScreen> {
  late TextEditingController _supplierRefController;

  @override
  void initState() {
    super.initState();
    _supplierRefController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final draftNotifier = ref.read(purchaseDraftNotifierProvider.notifier);
      final pId = widget.purchaseId;
      if (pId == null || pId.isEmpty) {
        draftNotifier.initNewDraft();
      } else {
        final listState = ref.read(purchasesListNotifierProvider);
        final existing = listState.purchases.cast<dynamic>().firstWhere(
              (p) => p.id == pId,
              orElse: () => null,
            );
        if (existing != null) {
          draftNotifier.loadDraft(existing);
          _supplierRefController.text = existing.supplierReference ?? '';
        } else {
          draftNotifier.initNewDraft();
        }
      }
    });
  }

  @override
  void dispose() {
    _supplierRefController.dispose();
    super.dispose();
  }

  void _showProductSearchSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: KiranaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => PurchaseProductSearchSheet(
        onProductSelected: (product) {
          ref
              .read(purchaseDraftNotifierProvider.notifier)
              .addProductItem(product);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(purchaseDraftNotifierProvider);
    final notifier = ref.read(purchaseDraftNotifierProvider.notifier);
    final draft = state.draft;

    if (draft == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Purchase Draft')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(draft.isCompleted
            ? 'Purchase #${draft.purchaseNumber}'
            : 'New Purchase Inward'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: KiranaSpacing.md),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: draft.isCompleted
                  ? KiranaColors.success.withValues(alpha: 0.15)
                  : KiranaColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              draft.status.toUpperCase(),
              style: KiranaTypography.labelSmall.copyWith(
                color: draft.isCompleted
                    ? KiranaColors.success
                    : KiranaColors.warning,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner / Messages
          if (state.errorMessage != null)
            Container(
              width: double.infinity,
              color: KiranaColors.errorContainer,
              padding: const EdgeInsets.all(KiranaSpacing.sm),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: KiranaColors.error, size: 18),
                  const SizedBox(width: KiranaSpacing.xs),
                  Expanded(
                    child: Text(
                      state.errorMessage!,
                      style: KiranaTypography.bodySmall
                          .copyWith(color: KiranaColors.error),
                    ),
                  ),
                ],
              ),
            ),

          if (state.successMessage != null)
            Container(
              width: double.infinity,
              color: KiranaColors.successContainer,
              padding: const EdgeInsets.all(KiranaSpacing.sm),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      color: KiranaColors.success, size: 18),
                  const SizedBox(width: KiranaSpacing.xs),
                  Expanded(
                    child: Text(
                      state.successMessage!,
                      style: KiranaTypography.bodySmall
                          .copyWith(color: KiranaColors.success),
                    ),
                  ),
                ],
              ),
            ),

          // Header Card (Purchase #, Supplier Reference)
          Padding(
            padding: const EdgeInsets.all(KiranaSpacing.md),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(KiranaSpacing.sm),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Purchase Number:',
                            style: KiranaTypography.bodySmall),
                        Text(draft.purchaseNumber,
                            style: KiranaTypography.titleMedium),
                      ],
                    ),
                    const SizedBox(height: KiranaSpacing.xs),
                    TextField(
                      controller: _supplierRefController,
                      enabled: draft.isDraft,
                      onChanged: (val) => notifier.setSupplierReference(val),
                      decoration: const InputDecoration(
                        labelText: 'Supplier Invoice / Reference (Optional)',
                        hintText: 'e.g. INV-SUPP-9842',
                        prefixIcon: Icon(Icons.receipt),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Add Product Action Button
          if (draft.isDraft)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: KiranaSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showProductSearchSheet(context),
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('Add Product to Purchase'),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: KiranaSpacing.xs),

          // Items Table / List
          Expanded(
            child: draft.items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shopping_bag_outlined,
                            size: 48, color: KiranaColors.textMuted),
                        const SizedBox(height: KiranaSpacing.xs),
                        Text('No products added to this purchase yet.',
                            style: KiranaTypography.bodyMedium),
                        if (draft.isDraft)
                          TextButton(
                            onPressed: () => _showProductSearchSheet(context),
                            child: const Text('Tap here to add products'),
                          ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(KiranaSpacing.md),
                    itemCount: draft.items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: KiranaSpacing.xs),
                    itemBuilder: (context, index) {
                      final item = draft.items[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(KiranaSpacing.sm),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.productName,
                                      style: KiranaTypography.titleMedium,
                                    ),
                                  ),
                                  if (draft.isDraft)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: KiranaColors.error, size: 20),
                                      onPressed: () =>
                                          notifier.removeItem(item.id),
                                    ),
                                ],
                              ),
                              const SizedBox(height: KiranaSpacing.xs),
                              Row(
                                children: [
                                  Text('Qty:',
                                      style: KiranaTypography.bodySmall),
                                  const SizedBox(width: 4),
                                  if (draft.isDraft) ...[
                                    IconButton(
                                      icon: const Icon(
                                          Icons.remove_circle_outline,
                                          size: 20),
                                      onPressed: () =>
                                          notifier.updateItemQuantity(
                                              item.id, item.quantity - 1),
                                    ),
                                    Text('${item.quantity} ${item.unit}',
                                        style: KiranaTypography.titleMedium),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline,
                                          size: 20),
                                      onPressed: () =>
                                          notifier.updateItemQuantity(
                                              item.id, item.quantity + 1),
                                    ),
                                  ] else
                                    Text('${item.quantity} ${item.unit}',
                                        style: KiranaTypography.titleMedium),
                                  const Spacer(),
                                  Text('Buy Price: ',
                                      style: KiranaTypography.bodySmall),
                                  Text(
                                    item.purchasePricePaise.toRupeesString(),
                                    style: KiranaTypography.bodyMedium
                                        .copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const Divider(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Item Total:',
                                      style: KiranaTypography.bodySmall),
                                  Text(
                                    item.totalPaise.toRupeesString(),
                                    style:
                                        KiranaTypography.priceTabular.copyWith(
                                      color: KiranaColors.primary,
                                    ),
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

          // Summary & Action Bar
          Container(
            padding: const EdgeInsets.all(KiranaSpacing.md),
            decoration: BoxDecoration(
              color: KiranaColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Items: ${draft.items.length}',
                        style: KiranaTypography.bodySmall),
                    Text(
                      'Grand Total: ${draft.totalPaise.toRupeesString()}',
                      style: KiranaTypography.headlineMedium.copyWith(
                        color: KiranaColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: KiranaSpacing.sm),
                if (draft.isDraft)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: state.isSaving
                              ? null
                              : () => notifier.saveDraft(),
                          child: const Text('Save Draft'),
                        ),
                      ),
                      const SizedBox(width: KiranaSpacing.sm),
                      Expanded(
                        flex: 2,
                        child: AppButton(
                          label: 'CONFIRM STOCK-IN',
                          icon: Icons.check_circle,
                          isLoading: state.isConfirming,
                          onPressed: draft.items.isEmpty || state.isConfirming
                              ? null
                              : () async {
                                  final ok = await notifier.confirmStockIn();
                                  if (ok && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Stock increased and purchase completed!'),
                                      ),
                                    );
                                  }
                                },
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
