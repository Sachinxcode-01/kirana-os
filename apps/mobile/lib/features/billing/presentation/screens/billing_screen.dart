import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/extensions/num_extensions.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../database/drift/database.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../credit/presentation/providers/credit_providers.dart';
import '../../../customers/presentation/providers/customer_providers.dart';
import '../../../products/presentation/providers/product_provider.dart';
import '../../../staff/domain/models/staff_member_model.dart';
import '../../domain/models/bill_model.dart';
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
      builder: (ctx) => const _ProductPickerSheet(),
    );
  }

  void _showCustomerPickerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: KiranaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => const _CustomerPickerSheet(),
    );
  }

  void _showDiscountSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: KiranaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => const _DiscountConfigurationSheet(),
    );
  }

  void _showExactQuantityDialog(
      BuildContext context, String itemId, double currentQty, String unit) {
    final controller = TextEditingController(
      text: currentQty % 1 == 0
          ? currentQty.toInt().toString()
          : currentQty.toString(),
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Enter Quantity ($unit)'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Quantity',
              suffixText: unit,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newQty = double.tryParse(controller.text.trim());
                if (newQty != null && newQty >= 1.0) {
                  ref
                      .read(billingNotifierProvider.notifier)
                      .updateQuantity(itemId, newQty);
                }
                Navigator.of(ctx).pop();
              },
              child: const Text('Update'),
            ),
          ],
        );
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
                    final success = await ref
                        .read(billingNotifierProvider.notifier)
                        .saveDraft();
                    if (context.mounted) {
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Draft saved locally')),
                        );
                      } else if (ref
                              .read(billingNotifierProvider)
                              .errorMessage !=
                          null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ref
                                .read(billingNotifierProvider)
                                .errorMessage!),
                            backgroundColor: KiranaColors.error,
                          ),
                        );
                      }
                    }
                  },
          ),
        ],
      ),
      body: billingState.isLoading && activeDraft == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 1. Customer Attachment Banner / Selector Card
                if (activeDraft != null)
                  Container(
                    margin: const EdgeInsets.fromLTRB(KiranaSpacing.md,
                        KiranaSpacing.sm, KiranaSpacing.md, KiranaSpacing.xs),
                    padding: const EdgeInsets.symmetric(
                        horizontal: KiranaSpacing.sm,
                        vertical: KiranaSpacing.xs),
                    decoration: BoxDecoration(
                      color: activeDraft.hasCustomer
                          ? KiranaColors.primaryContainer.withValues(alpha: 0.3)
                          : KiranaColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: activeDraft.hasCustomer
                            ? KiranaColors.primary.withValues(alpha: 0.3)
                            : KiranaColors.outlineVariant,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: activeDraft.hasCustomer
                              ? KiranaColors.primary
                              : KiranaColors.outlineVariant,
                          child: Icon(
                            activeDraft.hasCustomer
                                ? Icons.person
                                : Icons.person_outline,
                            size: 18,
                            color: activeDraft.hasCustomer
                                ? Colors.white
                                : KiranaColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: KiranaSpacing.sm),
                        Expanded(
                          child: activeDraft.hasCustomer
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      activeDraft.customerName ?? 'Customer',
                                      style:
                                          KiranaTypography.titleMedium.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (activeDraft.customerPhone != null)
                                      Text(
                                        activeDraft.customerPhone!,
                                        style:
                                            KiranaTypography.bodySmall.copyWith(
                                          color: KiranaColors.textSecondary,
                                        ),
                                      ),
                                  ],
                                )
                              : Text(
                                  'Walk-in Customer (No Customer Attached)',
                                  style: KiranaTypography.bodySmall.copyWith(
                                    color: KiranaColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                        ),
                        if (activeDraft.hasCustomer) ...[
                          TextButton(
                            onPressed: () => _showCustomerPickerSheet(context),
                            child: const Text('Change'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close,
                                size: 18, color: KiranaColors.error),
                            tooltip: 'Remove customer',
                            onPressed: () => ref
                                .read(billingNotifierProvider.notifier)
                                .removeCustomer(),
                          ),
                        ] else
                          TextButton.icon(
                            onPressed: () => _showCustomerPickerSheet(context),
                            icon: const Icon(Icons.person_add, size: 16),
                            label: const Text('Attach'),
                          ),
                      ],
                    ),
                  ),

                // 2. Top Search & Add Product Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: KiranaSpacing.md, vertical: KiranaSpacing.xs),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: OutlinedButton.icon(
                            onPressed: () => _showAddProductDialog(context),
                            icon: const Icon(Icons.search, size: 20),
                            label: const Text('Search catalog...'),
                            style: OutlinedButton.styleFrom(
                              alignment: Alignment.centerLeft,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: KiranaSpacing.sm,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: KiranaSpacing.xs),
                      SizedBox(
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: () => _showAddProductDialog(context),
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text('Add Item'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: KiranaColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: KiranaSpacing.xs),

                // 3. Cart Items List
                Expanded(
                  child: (activeDraft == null || activeDraft.items.isEmpty)
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(KiranaSpacing.xl),
                                decoration: BoxDecoration(
                                  color: KiranaColors.surfaceVariant.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.shopping_cart_outlined,
                                  size: 56,
                                  color: KiranaColors.neutral400,
                                ),
                              ),
                              const SizedBox(height: KiranaSpacing.md),
                              Text(
                                'No items in draft bill',
                                style: KiranaTypography.titleMedium.copyWith(
                                  color: KiranaColors.neutral800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: KiranaSpacing.xs),
                              const Text(
                                'Search catalog or scan barcode to add items.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: KiranaColors.neutral500,
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 250.ms).scale(begin: const Offset(0.95, 0.95))
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: KiranaSpacing.md,
                              vertical: KiranaSpacing.xs),
                          itemCount: activeDraft.items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: KiranaSpacing.xs),
                          itemBuilder: (context, index) {
                            final item = activeDraft.items[index];
                            return Card(
                              elevation: 0.5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                    color: KiranaColors.outlineVariant
                                        .withValues(alpha: 0.6)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(KiranaSpacing.sm),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Row 1: Product Name + Delete Button
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.productName,
                                            style: KiranaTypography.titleMedium
                                                .copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: KiranaColors.error,
                                            size: 20,
                                          ),
                                          constraints: const BoxConstraints(),
                                          padding: EdgeInsets.zero,
                                          tooltip: 'Remove item',
                                          onPressed: () => ref
                                              .read(billingNotifierProvider
                                                  .notifier)
                                              .removeItem(item.id),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: KiranaSpacing.xxs),

                                    // Row 2: Price Subtitle + Quantity Controls + Item Total
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Unit Price Subtitle
                                        Text(
                                          '${item.unitPricePaise.toRupeesString()} / ${item.unit}',
                                          style: KiranaTypography.bodySmall
                                              .copyWith(
                                            color: KiranaColors.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),

                                        // Quantity Controls
                                        Row(
                                          children: [
                                            InkWell(
                                              borderRadius: BorderRadius.circular(20),
                                              onTap: item.quantity > 1
                                                  ? () => ref
                                                      .read(
                                                          billingNotifierProvider
                                                              .notifier)
                                                      .updateQuantity(item.id,
                                                          item.quantity - 1)
                                                  : null,
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: item.quantity > 1
                                                      ? KiranaColors.surfaceVariant
                                                      : KiranaColors.surfaceVariant.withValues(alpha: 0.4),
                                                  border: Border.all(
                                                    color: KiranaColors.outlineVariant.withValues(alpha: 0.6),
                                                  ),
                                                ),
                                                child: Icon(
                                                  Icons.remove,
                                                  size: 16,
                                                  color: item.quantity > 1
                                                      ? KiranaColors.neutral800
                                                      : KiranaColors.neutral400,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: KiranaSpacing.xs),
                                            InkWell(
                                              onTap: () =>
                                                  _showExactQuantityDialog(
                                                      context,
                                                      item.id,
                                                      item.quantity,
                                                      item.unit),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal:
                                                            KiranaSpacing.sm,
                                                        vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: KiranaColors
                                                      .surfaceVariant,
                                                  border: Border.all(
                                                      color: KiranaColors
                                                          .outlineVariant),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  item.quantity % 1 == 0
                                                      ? item.quantity
                                                          .toInt()
                                                          .toString()
                                                      : item.quantity
                                                          .toStringAsFixed(2),
                                                  style: KiranaTypography
                                                      .labelLarge
                                                      .copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: KiranaSpacing.xs),
                                            InkWell(
                                              borderRadius: BorderRadius.circular(20),
                                              onTap: () => ref
                                                  .read(billingNotifierProvider
                                                      .notifier)
                                                  .updateQuantity(item.id,
                                                      item.quantity + 1),
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: KiranaColors.primaryContainer.withValues(alpha: 0.7),
                                                  border: Border.all(
                                                    color: KiranaColors.primary.withValues(alpha: 0.3),
                                                  ),
                                                ),
                                                child: const Icon(
                                                  Icons.add,
                                                  size: 16,
                                                  color: KiranaColors.primaryDark,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        // Total Price
                                        Text(
                                          item.totalPaise.toRupeesString(),
                                          style: KiranaTypography.priceTabular
                                              .copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: KiranaColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ).animate().fadeIn(duration: 200.ms, delay: Duration(milliseconds: 30 * (index < 6 ? index : 6))).slideX(begin: 0.04, end: 0);
                          },
                        ),
                ),

                // 4. Deterministic Totals & Discount Summary Footer
                if (activeDraft != null)
                  Container(
                    padding: const EdgeInsets.all(KiranaSpacing.md),
                    decoration: BoxDecoration(
                      color: KiranaColors.surface,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A000000),
                          offset: Offset(0, -3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Subtotal Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Subtotal',
                                  style: KiranaTypography.bodyMedium.copyWith(
                                      color: KiranaColors.textSecondary)),
                              Text(
                                activeDraft.subtotalPaise.toRupeesString(),
                                style: KiranaTypography.bodyMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Discount Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text('Discount',
                                      style: KiranaTypography.bodyMedium
                                          .copyWith(
                                              color:
                                                  KiranaColors.textSecondary)),
                                  const SizedBox(width: KiranaSpacing.xxs),
                                  InkWell(
                                    onTap: () => _showDiscountSheet(context),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4, vertical: 2),
                                      child: Text(
                                        activeDraft.discountType == 'none'
                                            ? '(Apply)'
                                            : '(${activeDraft.discountType == 'percentage' ? '${activeDraft.discountValue.toStringAsFixed(0)}%' : 'Fixed'})',
                                        style:
                                            KiranaTypography.bodySmall.copyWith(
                                          color: KiranaColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '- ${activeDraft.discountPaise.toRupeesString()}',
                                style: KiranaTypography.bodyMedium.copyWith(
                                  color: activeDraft.discountPaise > 0
                                      ? KiranaColors.success
                                      : KiranaColors.textSecondary,
                                  fontWeight: activeDraft.discountPaise > 0
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),

                          // Tax Row (if applicable)
                          if (activeDraft.taxTotalPaise > 0) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Tax Total',
                                    style: KiranaTypography.bodyMedium.copyWith(
                                        color: KiranaColors.textSecondary)),
                                Text(
                                  activeDraft.taxTotalPaise.toRupeesString(),
                                  style: KiranaTypography.bodyMedium,
                                ),
                              ],
                            ),
                          ],

                          const Divider(height: KiranaSpacing.md, thickness: 1),

                          // Grand Total Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Grand Total',
                                style: KiranaTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                activeDraft.totalPaise.toRupeesString(),
                                style: KiranaTypography.displayTotal.copyWith(
                                  color: KiranaColors.primary,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: KiranaSpacing.md),

                          // Responsive Action Buttons Row (50% / 50% flex width)
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.save_outlined,
                                        size: 18),
                                    label: const Text(
                                      'Save Draft',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () async {
                                      final success = await ref
                                          .read(
                                              billingNotifierProvider.notifier)
                                          .saveDraft();
                                      if (context.mounted) {
                                        if (success) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Draft saved locally')),
                                          );
                                        } else if (ref
                                                .read(billingNotifierProvider)
                                                .errorMessage !=
                                            null) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(ref
                                                  .read(billingNotifierProvider)
                                                  .errorMessage!),
                                              backgroundColor:
                                                  KiranaColors.error,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: KiranaSpacing.sm),
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.check_circle_outline,
                                        size: 18),
                                    label: const Text(
                                      'COMPLETE SALE',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: KiranaColors.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: activeDraft.items.isEmpty
                                        ? null
                                        : () {
                                            showModalBottomSheet(
                                              context: context,
                                              isScrollControlled: true,
                                              backgroundColor:
                                                  Colors.transparent,
                                              builder: (ctx) =>
                                                  _CheckoutReviewSheet(
                                                bill: activeDraft,
                                              ),
                                            );
                                          },
                                  ),
                                ),
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

class _ProductPickerSheet extends ConsumerStatefulWidget {
  const _ProductPickerSheet();

  @override
  ConsumerState<_ProductPickerSheet> createState() =>
      __ProductPickerSheetState();
}

class __ProductPickerSheetState extends ConsumerState<_ProductPickerSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsStreamProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(KiranaSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Select Product', style: KiranaTypography.titleLarge),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: KiranaSpacing.xs),
              TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (val) =>
                    setState(() => _searchQuery = val.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search product name or barcode...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: KiranaSpacing.sm),
              Expanded(
                child: productsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                  data: (products) {
                    final filteredProducts = _searchQuery.isEmpty
                        ? products
                        : products.where((p) {
                            final nameMatch =
                                p.name.toLowerCase().contains(_searchQuery);
                            final barcodeMatch = p.barcode != null &&
                                p.barcode!.toLowerCase().contains(_searchQuery);
                            return nameMatch || barcodeMatch;
                          }).toList();

                    if (filteredProducts.isEmpty) {
                      return Center(
                        child: Text(
                          _searchQuery.isEmpty
                              ? 'No products available in catalog.'
                              : 'No products match "$_searchQuery".',
                          style: KiranaTypography.bodyMedium
                              .copyWith(color: KiranaColors.textSecondary),
                        ),
                      );
                    }
                    return ListView.separated(
                      controller: scrollController,
                      itemCount: filteredProducts.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final product = filteredProducts[i];
                        final hasStock = product.currentStock > 0;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: KiranaSpacing.xs, vertical: 2),
                          title: Text(
                            product.name,
                            style: KiranaTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Row(
                            children: [
                              Text(
                                '${product.sellingPricePaise.toRupeesString()} / ${product.unit}',
                                style: KiranaTypography.bodyMedium,
                              ),
                              const SizedBox(width: KiranaSpacing.xs),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: hasStock
                                      ? KiranaColors.successContainer
                                      : KiranaColors.errorContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  hasStock
                                      ? 'Stock: ${product.currentStock % 1 == 0 ? product.currentStock.toInt() : product.currentStock.toStringAsFixed(1)} ${product.unit}'
                                      : 'Out of stock',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: hasStock
                                        ? KiranaColors.success
                                        : KiranaColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.add_circle,
                              color: KiranaColors.primary, size: 28),
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

class _CustomerPickerSheet extends ConsumerStatefulWidget {
  const _CustomerPickerSheet();

  @override
  ConsumerState<_CustomerPickerSheet> createState() =>
      __CustomerPickerSheetState();
}

class __CustomerPickerSheetState extends ConsumerState<_CustomerPickerSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
    final shopId = ref.watch(activeShopIdProvider);

    return StreamBuilder<List<CustomerData>>(
      stream: db.customersDao.watchCustomers(shopId, _searchQuery),
      builder: (context, snapshot) {
        final customers = snapshot.data ?? [];
        final activeDraft = ref.watch(billingNotifierProvider).activeDraft;
        final hasCustomer = activeDraft?.hasCustomer ?? false;

        return Container(
          padding: const EdgeInsets.all(KiranaSpacing.md),
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Select Customer', style: KiranaTypography.titleLarge),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: KiranaSpacing.xs),
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                decoration: InputDecoration(
                  hintText: 'Search by name or phone number...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: KiranaSpacing.sm),

              // Walk-in Customer option
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: !hasCustomer
                      ? KiranaColors.primary
                      : KiranaColors.surfaceVariant,
                  child: Icon(
                    Icons.person_off_outlined,
                    color: !hasCustomer
                        ? Colors.white
                        : KiranaColors.textSecondary,
                  ),
                ),
                title: Text(
                  'Walk-in Customer',
                  style: TextStyle(
                    fontWeight:
                        !hasCustomer ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: const Text('No customer attached (Cash/Digital)'),
                trailing: !hasCustomer
                    ? const Icon(Icons.check_circle,
                        color: KiranaColors.primary)
                    : null,
                onTap: () {
                  ref.read(billingNotifierProvider.notifier).removeCustomer();
                  Navigator.of(context).pop();
                },
              ),
              const Divider(),

              if (customers.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'No saved customers found in shop.'
                          : 'No customers match "$_searchQuery".',
                      style: KiranaTypography.bodyMedium
                          .copyWith(color: KiranaColors.textSecondary),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: customers.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, index) {
                      final cust = customers[index];
                      final isSelected = activeDraft?.customerId == cust.id;
                      final debtPaise = cust.currentDebtPaise.toInt();

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected
                              ? KiranaColors.primary
                              : KiranaColors.primaryContainer,
                          child: Icon(
                            Icons.person,
                            color: isSelected
                                ? Colors.white
                                : KiranaColors.primary,
                          ),
                        ),
                        title: Text(
                          cust.name,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          cust.phone +
                              (debtPaise > 0
                                  ? ' • Debt: ₹${(debtPaise / 100.0).toStringAsFixed(2)}'
                                  : ''),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle,
                                color: KiranaColors.primary)
                            : null,
                        onTap: () {
                          ref
                              .read(billingNotifierProvider.notifier)
                              .attachCustomer(
                                customerId: cust.id,
                                customerName: cust.name,
                                customerPhone: cust.phone,
                              );
                          Navigator.of(context).pop();
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

class _DiscountConfigurationSheet extends ConsumerStatefulWidget {
  const _DiscountConfigurationSheet();

  @override
  ConsumerState<_DiscountConfigurationSheet> createState() =>
      __DiscountConfigurationSheetState();
}

class __DiscountConfigurationSheetState
    extends ConsumerState<_DiscountConfigurationSheet> {
  String _discountType = 'percentage';
  final _valController = TextEditingController(text: '0');
  String? _validationError;

  @override
  void initState() {
    super.initState();
    final activeDraft = ref.read(billingNotifierProvider).activeDraft;
    if (activeDraft != null && activeDraft.discountType != 'none') {
      _discountType = activeDraft.discountType;
      if (_discountType == 'fixed') {
        _valController.text =
            (activeDraft.discountValue / 100.0).toStringAsFixed(2);
      } else {
        _valController.text = activeDraft.discountValue.toStringAsFixed(0);
      }
    }
  }

  @override
  void dispose() {
    _valController.dispose();
    super.dispose();
  }

  void _onPresetSelected(double value) {
    setState(() {
      _valController.text =
          value % 1 == 0 ? value.toInt().toString() : value.toString();
      _validationError = null;
    });
  }

  void _validateInput(String text, int subtotalPaise) {
    final raw = double.tryParse(text.trim());
    if (raw == null && text.trim().isNotEmpty) {
      setState(() => _validationError = 'Enter a valid number.');
      return;
    }
    if (raw != null && raw < 0) {
      setState(() => _validationError = 'Discount cannot be negative.');
      return;
    }

    if (_discountType == 'percentage') {
      if (raw != null && raw > 100.0) {
        setState(
            () => _validationError = 'Percentage discount cannot exceed 100%.');
        return;
      }
    } else if (_discountType == 'fixed') {
      final paise = ((raw ?? 0.0) * 100).round();
      if (paise > subtotalPaise) {
        setState(() => _validationError = 'Discount cannot exceed subtotal.');
        return;
      }
    }

    setState(() => _validationError = null);
  }

  @override
  Widget build(BuildContext context) {
    final activeDraft = ref.watch(billingNotifierProvider).activeDraft;
    final subtotalPaise = activeDraft?.subtotalPaise ?? 0;

    double parsedRaw = double.tryParse(_valController.text.trim()) ?? 0.0;
    int calculatedDiscountPaise = 0;
    if (_discountType == 'percentage') {
      final pct = parsedRaw.clamp(0.0, 100.0);
      calculatedDiscountPaise =
          ((subtotalPaise * (pct / 100.0))).round().clamp(0, subtotalPaise);
    } else if (_discountType == 'fixed') {
      calculatedDiscountPaise =
          ((parsedRaw * 100).round()).clamp(0, subtotalPaise);
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + KiranaSpacing.md,
        left: KiranaSpacing.md,
        right: KiranaSpacing.md,
        top: KiranaSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Apply Bill Discount', style: KiranaTypography.titleLarge),
              if (activeDraft != null && activeDraft.discountType != 'none')
                TextButton.icon(
                  onPressed: () {
                    ref.read(billingNotifierProvider.notifier).applyDiscount(
                          discountType: 'none',
                          discountValue: 0.0,
                        );
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.clear,
                      size: 18, color: KiranaColors.error),
                  label: const Text(
                    'Clear Discount',
                    style: TextStyle(color: KiranaColors.error),
                  ),
                ),
            ],
          ),
          const SizedBox(height: KiranaSpacing.md),

          // Discount Type Selector Segment
          Row(
            children: [
              ChoiceChip(
                label: const Text('Flat (₹)'),
                selected: _discountType == 'fixed',
                onSelected: (val) {
                  if (val) {
                    setState(() {
                      _discountType = 'fixed';
                      _valController.text = '0';
                      _validationError = null;
                    });
                  }
                },
              ),
              const SizedBox(width: KiranaSpacing.xs),
              ChoiceChip(
                label: const Text('Percent (%)'),
                selected: _discountType == 'percentage',
                onSelected: (val) {
                  if (val) {
                    setState(() {
                      _discountType = 'percentage';
                      _valController.text = '0';
                      _validationError = null;
                    });
                  }
                },
              ),
              const SizedBox(width: KiranaSpacing.xs),
              ChoiceChip(
                label: const Text('None'),
                selected: _discountType == 'none',
                onSelected: (val) {
                  if (val) {
                    setState(() {
                      _discountType = 'none';
                      _valController.text = '0';
                      _validationError = null;
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: KiranaSpacing.md),

          if (_discountType != 'none') ...[
            // Quick Presets
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _discountType == 'percentage'
                    ? [5, 10, 15, 20, 25, 50].map((pct) {
                        return Padding(
                          padding:
                              const EdgeInsets.only(right: KiranaSpacing.xs),
                          child: ActionChip(
                            label: Text('$pct%'),
                            onPressed: () => _onPresetSelected(pct.toDouble()),
                          ),
                        );
                      }).toList()
                    : [10, 20, 50, 100, 200, 500].map((amt) {
                        return Padding(
                          padding:
                              const EdgeInsets.only(right: KiranaSpacing.xs),
                          child: ActionChip(
                            label: Text('₹$amt'),
                            onPressed: () => _onPresetSelected(amt.toDouble()),
                          ),
                        );
                      }).toList(),
              ),
            ),
            const SizedBox(height: KiranaSpacing.md),

            // Value Input Field
            TextField(
              controller: _valController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              onChanged: (val) => _validateInput(val, subtotalPaise),
              decoration: InputDecoration(
                labelText: _discountType == 'percentage'
                    ? 'Discount Percentage (%)'
                    : 'Discount Amount (₹)',
                errorText: _validationError,
                prefixIcon: Icon(
                  _discountType == 'percentage'
                      ? Icons.percent
                      : Icons.currency_rupee,
                ),
              ),
            ),
            const SizedBox(height: KiranaSpacing.md),

            // Real-time Summary Card
            Container(
              padding: const EdgeInsets.all(KiranaSpacing.sm),
              decoration: BoxDecoration(
                color: KiranaColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: KiranaColors.outlineVariant),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Calculated Discount:',
                    style: KiranaTypography.bodyMedium
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '- ${calculatedDiscountPaise.toRupeesString()}',
                    style: KiranaTypography.titleMedium.copyWith(
                      color: calculatedDiscountPaise > 0
                          ? KiranaColors.success
                          : KiranaColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: KiranaSpacing.lg),

          // Dialog Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: KiranaSpacing.sm),
              ElevatedButton(
                onPressed: _validationError != null
                    ? null
                    : () {
                        if (_discountType == 'none') {
                          ref
                              .read(billingNotifierProvider.notifier)
                              .applyDiscount(
                                discountType: 'none',
                                discountValue: 0.0,
                              );
                          Navigator.of(context).pop();
                          return;
                        }

                        final rawVal =
                            double.tryParse(_valController.text.trim()) ?? 0.0;
                        final discountValue = _discountType == 'fixed'
                            ? (rawVal * 100)
                                .roundToDouble() // convert rupees to paise
                            : rawVal;

                        final success = ref
                            .read(billingNotifierProvider.notifier)
                            .applyDiscount(
                              discountType: _discountType,
                              discountValue: discountValue,
                            );

                        if (success) {
                          Navigator.of(context).pop();
                        } else {
                          final err =
                              ref.read(billingNotifierProvider).errorMessage;
                          if (err != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(err),
                                backgroundColor: KiranaColors.error,
                              ),
                            );
                          }
                        }
                      },
                child: const Text('Apply Discount'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CheckoutReviewSheet extends ConsumerStatefulWidget {
  final BillModel bill;

  const _CheckoutReviewSheet({required this.bill});

  @override
  ConsumerState<_CheckoutReviewSheet> createState() =>
      __CheckoutReviewSheetState();
}

class __CheckoutReviewSheetState extends ConsumerState<_CheckoutReviewSheet> {
  String _selectedPaymentMode = 'cash';
  bool _isProcessing = false;
  String? _checkoutError;

  Future<void> _handleConfirmCheckout() async {
    if (_isProcessing) return;

    if (_selectedPaymentMode == 'credit') {
      if (!widget.bill.hasCustomer) {
        setState(() {
          _checkoutError = 'Select a customer for a credit sale.';
        });
        return;
      }
    }

    setState(() {
      _isProcessing = true;
      _checkoutError = null;
    });

    final success = await ref
        .read(billingNotifierProvider.notifier)
        .completeCheckout(paymentMode: _selectedPaymentMode);

    if (!mounted) return;

    if (success) {
      final completedBill =
          ref.read(billingNotifierProvider).activeDraft ?? widget.bill;

      if (_selectedPaymentMode == 'credit' && completedBill.hasCustomer) {
        await ref.read(creditRepositoryProvider).recordCreditSale(
              customerId: completedBill.customerId!,
              amountPaise: completedBill.totalPaise,
              billId: completedBill.id,
              notes: 'POS Checkout Udhaar Sale #${completedBill.billNumber}',
            );
        ref.invalidate(customerDetailProvider(completedBill.customerId!));
        ref.invalidate(customerSalesHistoryProvider(completedBill.customerId!));
        ref.invalidate(customerLedgerStreamProvider(completedBill.customerId!));
        ref.invalidate(shopCreditSummaryProvider);
        ref.invalidate(indebtedCustomersStreamProvider);
      }

      if (!mounted) return;
      Navigator.of(context).pop();

      // Reset draft for new sale
      ref.read(billingNotifierProvider.notifier).resetDraft();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _CheckoutSuccessModal(
          billNumber: completedBill.billNumber,
          totalPaise: completedBill.totalPaise,
        ),
      );
    } else {
      final err = ref.read(billingNotifierProvider).errorMessage ??
          'Checkout transaction failed. Please try again.';
      setState(() {
        _isProcessing = false;
        _checkoutError = err;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bill = widget.bill;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + KiranaSpacing.md,
        left: KiranaSpacing.md,
        right: KiranaSpacing.md,
        top: KiranaSpacing.md,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Review Sale Checkout',
                    style: KiranaTypography.titleLarge),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed:
                      _isProcessing ? null : () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: KiranaSpacing.sm),

            // Error Banner (e.g. Price changed or Stock unavailable)
            if (_checkoutError != null) ...[
              Container(
                padding: const EdgeInsets.all(KiranaSpacing.sm),
                decoration: BoxDecoration(
                  color: KiranaColors.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: KiranaColors.error),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: KiranaColors.error, size: 20),
                    const SizedBox(width: KiranaSpacing.xs),
                    Expanded(
                      child: Text(
                        _checkoutError!,
                        style: const TextStyle(
                          color: KiranaColors.error,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: KiranaSpacing.md),
            ],

            // Customer Summary Box (Interactive Selector / Change / Remove)
            Builder(builder: (context) {
              final activeBill =
                  ref.watch(billingNotifierProvider).activeDraft ?? widget.bill;
              final hasCust = activeBill.hasCustomer;

              return Container(
                padding: const EdgeInsets.all(KiranaSpacing.sm),
                decoration: BoxDecoration(
                  color: KiranaColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: KiranaColors.outlineVariant),
                ),
                child: Row(
                  children: [
                    Icon(
                      hasCust ? Icons.person : Icons.person_outline,
                      color: hasCust
                          ? KiranaColors.primary
                          : KiranaColors.textSecondary,
                    ),
                    const SizedBox(width: KiranaSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasCust
                                ? activeBill.customerName!
                                : 'Walk-in Customer (No Customer Attached)',
                            style: KiranaTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (hasCust && activeBill.customerPhone != null)
                            Text(
                              activeBill.customerPhone!,
                              style: KiranaTypography.bodySmall.copyWith(
                                color: KiranaColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (hasCust) ...[
                      TextButton(
                        onPressed: _isProcessing
                            ? null
                            : () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => const _CustomerPickerSheet(),
                                );
                              },
                        child: const Text('Change'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            size: 18, color: KiranaColors.error),
                        tooltip: 'Remove customer',
                        onPressed: _isProcessing
                            ? null
                            : () {
                                ref
                                    .read(billingNotifierProvider.notifier)
                                    .removeCustomer();
                              },
                      ),
                    ] else
                      TextButton.icon(
                        icon: const Icon(Icons.person_add, size: 16),
                        label: const Text('Select Customer'),
                        onPressed: _isProcessing
                            ? null
                            : () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => const _CustomerPickerSheet(),
                                );
                              },
                      ),
                  ],
                ),
              );
            }),
            const SizedBox(height: KiranaSpacing.md),

            // Item Summary
            Text('Items Summary (${bill.items.length})',
                style: KiranaTypography.titleMedium),
            const SizedBox(height: KiranaSpacing.xs),
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: bill.items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final item = bill.items[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item.productName} × ${item.quantity.toStringAsFixed(0)} ${item.unit}',
                            style: KiranaTypography.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          item.totalPaise.toRupeesString(),
                          style: KiranaTypography.bodyMedium
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(height: KiranaSpacing.md),

            // Totals Breakdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal', style: KiranaTypography.bodyMedium),
                Text(bill.subtotalPaise.toRupeesString(),
                    style: KiranaTypography.bodyMedium),
              ],
            ),
            if (bill.discountPaise > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Discount', style: KiranaTypography.bodyMedium),
                  Text(
                    '- ${bill.discountPaise.toRupeesString()}',
                    style: KiranaTypography.bodyMedium
                        .copyWith(color: KiranaColors.success),
                  ),
                ],
              ),
            if (bill.taxTotalPaise > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tax Total', style: KiranaTypography.bodyMedium),
                  Text(bill.taxTotalPaise.toRupeesString(),
                      style: KiranaTypography.bodyMedium),
                ],
              ),
            const SizedBox(height: KiranaSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Grand Total',
                    style: KiranaTypography.titleLarge
                        .copyWith(fontWeight: FontWeight.bold)),
                Text(
                  bill.totalPaise.toRupeesString(),
                  style: KiranaTypography.displayTotal
                      .copyWith(color: KiranaColors.primary),
                ),
              ],
            ),
            const SizedBox(height: KiranaSpacing.md),

            // Payment Mode Selector
            Text('Payment Method', style: KiranaTypography.titleMedium),
            const SizedBox(height: KiranaSpacing.xs),
            Wrap(
              spacing: KiranaSpacing.xs,
              runSpacing: KiranaSpacing.xs,
              children: [
                ChoiceChip(
                  label: const Text('💵 CASH'),
                  selected: _selectedPaymentMode == 'cash',
                  onSelected: _isProcessing
                      ? null
                      : (val) {
                          if (val) {
                            setState(() {
                              _selectedPaymentMode = 'cash';
                              _checkoutError = null;
                            });
                          }
                        },
                ),
                ChoiceChip(
                  label: const Text('📱 UPI'),
                  selected: _selectedPaymentMode == 'upi_qr',
                  onSelected: _isProcessing
                      ? null
                      : (val) {
                          if (val) {
                            setState(() {
                              _selectedPaymentMode = 'upi_qr';
                              _checkoutError = null;
                            });
                          }
                        },
                ),
                ChoiceChip(
                  label: const Text('💳 CARD'),
                  selected: _selectedPaymentMode == 'card',
                  onSelected: _isProcessing
                      ? null
                      : (val) {
                          if (val) {
                            setState(() {
                              _selectedPaymentMode = 'card';
                              _checkoutError = null;
                            });
                          }
                        },
                ),
                ChoiceChip(
                  label: const Text('📝 UDHAAR'),
                  selected: _selectedPaymentMode == 'credit',
                  onSelected: _isProcessing
                      ? null
                      : (val) {
                          if (val) {
                            setState(() {
                              _selectedPaymentMode = 'credit';
                              _checkoutError = null;
                            });
                          }
                        },
                ),
              ],
            ),
            const SizedBox(height: KiranaSpacing.md),

            // Credit Sale Customer Due Validation Card (Phase 14.5)
            if (_selectedPaymentMode == 'credit')
              Builder(builder: (context) {
                final activeBill =
                    ref.watch(billingNotifierProvider).activeDraft ??
                        widget.bill;
                final hasCust = activeBill.hasCustomer;

                if (!hasCust) {
                  return Container(
                    padding: const EdgeInsets.all(KiranaSpacing.sm),
                    decoration: BoxDecoration(
                      color: KiranaColors.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: KiranaColors.error),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: KiranaColors.error, size: 20),
                        const SizedBox(width: KiranaSpacing.xs),
                        const Expanded(
                          child: Text(
                            'Select a customer for a credit sale.',
                            style: TextStyle(
                              color: KiranaColors.error,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.person_add, size: 16),
                          label: const Text('Select'),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => const _CustomerPickerSheet(),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }

                final customerAsync =
                    ref.watch(customerDetailProvider(activeBill.customerId!));

                return customerAsync.when(
                  loading: () => const SizedBox(
                    height: 60,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (cust) {
                    final currentDebt = cust?.currentDebtPaise.toInt() ?? 0;
                    final thisSale = bill.totalPaise;
                    final newTotalDue = currentDebt + thisSale;

                    return Container(
                      padding: const EdgeInsets.all(KiranaSpacing.sm),
                      decoration: BoxDecoration(
                        color: KiranaColors.secondaryContainer
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color:
                                KiranaColors.secondary.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Credit Sale Customer Breakdown',
                                style: KiranaTypography.labelLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: KiranaColors.secondary,
                                ),
                              ),
                              Text(
                                cust?.name ?? '',
                                style: KiranaTypography.bodySmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: KiranaSpacing.xs),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Current Due:',
                                  style: TextStyle(fontSize: 12)),
                              Text((currentDebt).toRupeesString(),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('This Udhaar Sale:',
                                  style: TextStyle(fontSize: 12)),
                              Text('+ ${(thisSale).toRupeesString()}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: KiranaColors.secondary)),
                            ],
                          ),
                          const Divider(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('New Total Due:',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold)),
                              Text(
                                (newTotalDue).toRupeesString(),
                                style: KiranaTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: KiranaColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
            const SizedBox(height: KiranaSpacing.lg),

            // Action Buttons
            Builder(builder: (context) {
              final activeBill =
                  ref.watch(billingNotifierProvider).activeDraft ?? widget.bill;
              final isCreditNoCustomer =
                  _selectedPaymentMode == 'credit' && !activeBill.hasCustomer;

              return AppButton(
                label: _isProcessing
                    ? 'PROCESSING...'
                    : (_selectedPaymentMode == 'credit'
                        ? 'COMPLETE CREDIT SALE'
                        : 'CONFIRM & COMPLETE SALE'),
                icon: Icons.check_circle_rounded,
                isLoading: _isProcessing,
                onPressed: (_isProcessing || isCreditNoCustomer)
                    ? null
                    : _handleConfirmCheckout,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _CheckoutSuccessModal extends StatelessWidget {
  final String billNumber;
  final int totalPaise;

  const _CheckoutSuccessModal({
    required this.billNumber,
    required this.totalPaise,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Padding(
        padding: const EdgeInsets.symmetric(vertical: KiranaSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: KiranaColors.successContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  color: KiranaColors.success, size: 48),
            ),
            const SizedBox(height: KiranaSpacing.md),
            Text('Sale Completed!',
                style: KiranaTypography.headlineMedium
                    .copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: KiranaSpacing.xs),
            Text(
              'Bill #$billNumber',
              style: KiranaTypography.titleMedium
                  .copyWith(color: KiranaColors.textSecondary),
            ),
            const SizedBox(height: KiranaSpacing.xs),
            Text(
              totalPaise.toRupeesString(),
              style: KiranaTypography.displayTotal
                  .copyWith(color: KiranaColors.primary),
            ),
            const SizedBox(height: KiranaSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: const Text('View Receipt'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.push('/completed-receipt',
                          extra: {'billNumber': billNumber});
                    },
                  ),
                ),
                const SizedBox(width: KiranaSpacing.sm),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KiranaColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('New Sale'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
