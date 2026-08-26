import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../../products/domain/models/product_model.dart';
import '../../../products/presentation/providers/product_provider.dart';

class PurchaseProductSearchSheet extends ConsumerStatefulWidget {
  final ValueChanged<ProductModel> onProductSelected;

  const PurchaseProductSearchSheet({
    super.key,
    required this.onProductSelected,
  });

  @override
  ConsumerState<PurchaseProductSearchSheet> createState() =>
      _PurchaseProductSearchSheetState();
}

class _PurchaseProductSearchSheetState
    extends ConsumerState<PurchaseProductSearchSheet> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsStreamProvider);

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
              Text('Select Product for Purchase',
                  style: KiranaTypography.titleLarge),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: KiranaSpacing.xs),

          // Search Field
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search product by name or brand...',
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

          // Product List
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text('Error loading products: $err',
                    style: KiranaTypography.bodyMedium),
              ),
              data: (products) {
                final query = _searchController.text.trim().toLowerCase();
                final filteredProducts = query.isEmpty
                    ? products
                    : products.where((p) {
                        final nameMatch = p.name.toLowerCase().contains(query);
                        final brandMatch = p.brand != null &&
                            p.brand!.toLowerCase().contains(query);
                        return nameMatch || brandMatch;
                      }).toList();

                if (filteredProducts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inventory_2_outlined,
                            size: 40, color: KiranaColors.textMuted),
                        const SizedBox(height: KiranaSpacing.xs),
                        Text(
                          query.isNotEmpty
                              ? 'No product found for "$query"'
                              : 'No products in catalog',
                          style: KiranaTypography.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: filteredProducts.length,
                  separatorBuilder: (_, __) => const Divider(
                      height: 1, color: KiranaColors.outlineVariant),
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    final buyPriceRupees =
                        (product.purchasePricePaise / 100).toStringAsFixed(2);
                    final sellPriceRupees =
                        (product.sellingPricePaise / 100).toStringAsFixed(2);

                    return ListTile(
                      title: Text(product.name,
                          style: KiranaTypography.titleMedium),
                      subtitle: Text(
                        'Stock: ${product.currentStock} ${product.unit} • Buy Price: ₹$buyPriceRupees',
                        style: KiranaTypography.bodySmall,
                      ),
                      trailing: Text(
                        '₹$sellPriceRupees',
                        style: KiranaTypography.priceTabular.copyWith(
                          color: KiranaColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () {
                        widget.onProductSelected(product);
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
  }
}
