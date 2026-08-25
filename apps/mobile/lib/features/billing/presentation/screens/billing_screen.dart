import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/extensions/num_extensions.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../products/presentation/providers/product_provider.dart';
import '../../../staff/domain/models/staff_member_model.dart';
import '../providers/billing_provider.dart';

class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(billingNotifierProvider.notifier).initializeDraft();
    });
  }

  void _showAddProductDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: KiranaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return const _ProductPickerSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final userRole =
        StaffRoleExtension.fromString(authState.user?.role ?? 'cashier');

    // 1. Permission Restriction for INVENTORY_STAFF
    if (userRole == StaffRole.inventoryStaff) {
      return Scaffold(
        appBar: AppBar(title: const Text('POS Terminal')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(KiranaSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: KiranaColors.error,
                ),
                const SizedBox(height: KiranaSpacing.md),
                Text(
                  'Access Restricted',
                  style: KiranaTypography.titleLarge.copyWith(
                    color: KiranaColors.error,
                  ),
                ),
                const SizedBox(height: KiranaSpacing.xs),
                const Text(
                  'Inventory staff members are not authorized to access billing or create draft bills.',
                  textAlign: TextAlign.center,
                  style: KiranaTypography.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final billingState = ref.watch(billingNotifierProvider);
    final activeDraft = billingState.activeDraft;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              activeDraft != null
                  ? 'Bill ${activeDraft.billNumber}'
                  : 'POS Terminal',
              style: KiranaTypography.titleMedium,
            ),
            if (activeDraft != null)
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: KiranaSpacing.xxs, vertical: 2),
                    decoration: BoxDecoration(
                      color: KiranaColors.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      billingState.isOffline ? 'OFFLINE DRAFT' : 'DRAFT',
                      style: KiranaTypography.bodySmall.copyWith(
                        color: KiranaColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Barcode Scanner',
            onPressed: () => context.push('/barcode'),
          ),
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Save Draft',
            onPressed: billingState.isLoading || activeDraft == null
                ? null
                : () async {
                    await ref
                        .read(billingNotifierProvider.notifier)
                        .saveDraft();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Draft saved locally')),
                      );
                    }
                  },
          ),
        ],
      ),
      body: billingState.isLoading && activeDraft == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Top Search & Quick Add Bar
                Padding(
                  padding: const EdgeInsets.all(KiranaSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showAddProductDialog(context),
                          icon: const Icon(Icons.search),
                          label: const Text('Search catalog...'),
                          style: OutlinedButton.styleFrom(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(
                              horizontal: KiranaSpacing.md,
                              vertical: KiranaSpacing.sm,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: KiranaSpacing.xs),
                      ElevatedButton.icon(
                        onPressed: () => _showAddProductDialog(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Product'),
                      ),
                    ],
                  ),
                ),

                // Cart Items List
                Expanded(
                  child: (activeDraft == null || activeDraft.items.isEmpty)
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.shopping_cart_outlined,
                                size: 64,
                                color: KiranaColors.textSecondary,
                              ),
                              const SizedBox(height: KiranaSpacing.md),
                              Text(
                                'No items in draft bill',
                                style: KiranaTypography.titleMedium.copyWith(
                                  color: KiranaColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: KiranaSpacing.xs),
                              const Text(
                                'Search catalog or scan barcode to add items.',
                                style: KiranaTypography.bodySmall,
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: KiranaSpacing.md),
                          itemCount: activeDraft.items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: KiranaSpacing.xs),
                          itemBuilder: (context, index) {
                            final item = activeDraft.items[index];
                            return Card(
                              elevation: 1,
                              child: Padding(
                                padding: const EdgeInsets.all(KiranaSpacing.md),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.productName,
                                            style: KiranaTypography.titleMedium,
                                          ),
                                          const SizedBox(
                                              height: KiranaSpacing.xxs),
                                          Text(
                                            '${item.unitPricePaise.toRupeesString()} / ${item.unit}',
                                            style: KiranaTypography.bodySmall,
                                          ),
                                          if (item.taxRate > 0)
                                            Text(
                                              'Tax (${item.taxRate.toStringAsFixed(1)}%): ${item.taxAmountPaise.toRupeesString()}',
                                              style: KiranaTypography.bodySmall
                                                  .copyWith(
                                                color:
                                                    KiranaColors.textSecondary,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    // Quantity Controls
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                              Icons.remove_circle_outline),
                                          onPressed: () => ref
                                              .read(billingNotifierProvider
                                                  .notifier)
                                              .updateQuantity(
                                                  item.id, item.quantity - 1),
                                        ),
                                        Text(
                                          item.quantity % 1 == 0
                                              ? item.quantity.toInt().toString()
                                              : item.quantity
                                                  .toStringAsFixed(2),
                                          style: KiranaTypography.labelLarge,
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.add_circle_outline),
                                          onPressed: () => ref
                                              .read(billingNotifierProvider
                                                  .notifier)
                                              .updateQuantity(
                                                  item.id, item.quantity + 1),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: KiranaSpacing.xs),
                                    Text(
                                      item.totalPaise.toRupeesString(),
                                      style: KiranaTypography.priceTabular,
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: KiranaColors.error,
                                      ),
                                      onPressed: () => ref
                                          .read(
                                              billingNotifierProvider.notifier)
                                          .removeItem(item.id),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Deterministic Totals Summary Footer
                if (activeDraft != null)
                  Container(
                    padding: const EdgeInsets.all(KiranaSpacing.md),
                    decoration: const BoxDecoration(
                      color: KiranaColors.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x14000000),
                          offset: Offset(0, -2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Subtotal',
                                  style: KiranaTypography.bodySmall),
                              Text(
                                activeDraft.subtotalPaise.toRupeesString(),
                                style: KiranaTypography.bodyMedium,
                              ),
                            ],
                          ),
                          if (activeDraft.taxTotalPaise > 0)
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: KiranaSpacing.xxs),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Tax Total',
                                      style: KiranaTypography.bodySmall),
                                  Text(
                                    activeDraft.taxTotalPaise.toRupeesString(),
                                    style: KiranaTypography.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          const Divider(height: KiranaSpacing.md),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Grand Total',
                                        style: KiranaTypography.labelSmall),
                                    Text(
                                      activeDraft.totalPaise.toRupeesString(),
                                      style: KiranaTypography.displayTotal
                                          .copyWith(
                                        color: KiranaColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: KiranaSpacing.md),
                              AppButton(
                                label: 'SAVE DRAFT',
                                icon: Icons.save_outlined,
                                onPressed: () async {
                                  await ref
                                      .read(billingNotifierProvider.notifier)
                                      .saveDraft();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Draft saved locally')),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _ProductPickerSheet extends ConsumerWidget {
  const _ProductPickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsStreamProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(KiranaSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select Product', style: KiranaTypography.titleLarge),
              const SizedBox(height: KiranaSpacing.sm),
              Expanded(
                child: productsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                  data: (products) {
                    if (products.isEmpty) {
                      return const Center(
                          child: Text('No products available.'));
                    }
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: products.length,
                      itemBuilder: (ctx, i) {
                        final product = products[i];
                        return ListTile(
                          title: Text(product.name),
                          subtitle: Text(
                              '${product.sellingPricePaise.toRupeesString()} per ${product.unit}'),
                          trailing: const Icon(Icons.add_circle_outline),
                          onTap: () {
                            ref
                                .read(billingNotifierProvider.notifier)
                                .addProduct(product);
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
