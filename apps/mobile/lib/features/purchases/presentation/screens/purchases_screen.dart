import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/num_extensions.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/models/purchase_model.dart';
import '../providers/purchase_provider.dart';
import 'purchase_draft_screen.dart';

class PurchasesScreen extends ConsumerWidget {
  const PurchasesScreen({super.key});

  void _openPurchaseDraft(BuildContext context, WidgetRef ref,
      [PurchaseModel? draft]) {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listState = ref.watch(purchasesListNotifierProvider);
    final purchases = listState.purchases;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchases & Inward Goods'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(purchasesListNotifierProvider.notifier).loadPurchases();
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New Purchase',
            onPressed: () => _openPurchaseDraft(context, ref),
          ),
        ],
      ),
      body: listState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : listState.errorMessage != null && purchases.isEmpty
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
                              .read(purchasesListNotifierProvider.notifier)
                              .loadPurchases();
                        },
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
                          Text('No purchase records found.',
                              style: KiranaTypography.bodyMedium),
                          const SizedBox(height: KiranaSpacing.sm),
                          ElevatedButton.icon(
                            onPressed: () => _openPurchaseDraft(context, ref),
                            icon: const Icon(Icons.add),
                            label: const Text('Create New Purchase Inward'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        await ref
                            .read(purchasesListNotifierProvider.notifier)
                            .loadPurchases();
                      },
                      child: ListView.separated(
                        padding: const EdgeInsets.all(KiranaSpacing.md),
                        itemCount: purchases.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: KiranaSpacing.xs),
                        itemBuilder: (context, index) {
                          final p = purchases[index];
                          return Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: KiranaSpacing.md,
                                vertical: KiranaSpacing.xs,
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    '#${p.purchaseNumber}',
                                    style: KiranaTypography.titleMedium,
                                  ),
                                  const SizedBox(width: KiranaSpacing.xs),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: p.isCompleted
                                          ? KiranaColors.success
                                              .withValues(alpha: 0.15)
                                          : KiranaColors.warning
                                              .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      p.status.toUpperCase(),
                                      style:
                                          KiranaTypography.labelSmall.copyWith(
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
                                '${p.supplierReference ?? "No Supplier Ref"} • ${p.items.length} items • ${DateFormatter.formatDate(p.createdAt)}',
                                style: KiranaTypography.bodySmall,
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    p.totalPaise.toRupeesString(),
                                    style:
                                        KiranaTypography.priceTabular.copyWith(
                                      color: KiranaColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Icon(
                                    p.isCompleted
                                        ? Icons.check_circle
                                        : Icons.edit_note,
                                    size: 16,
                                    color: p.isCompleted
                                        ? KiranaColors.success
                                        : KiranaColors.secondary,
                                  ),
                                ],
                              ),
                              onTap: () => _openPurchaseDraft(context, ref, p),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openPurchaseDraft(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Purchase'),
      ),
    );
  }
}
