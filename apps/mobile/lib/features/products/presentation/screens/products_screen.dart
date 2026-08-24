import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kirana_mobile/core/extensions/num_extensions.dart';
import 'package:kirana_mobile/core/theme/colors.dart';
import 'package:kirana_mobile/core/theme/spacing.dart';
import 'package:kirana_mobile/core/theme/typography.dart';
import 'package:kirana_mobile/core/widgets/app_text_field.dart';

class ProductItem {
  final String id;
  final String name;
  final String barcode;
  final int sellingPricePaise;
  final int mrpPaise;
  final double currentStock;

  const ProductItem({
    required this.id,
    required this.name,
    required this.barcode,
    required this.sellingPricePaise,
    required this.mrpPaise,
    required this.currentStock,
  });
}

final productsListProvider = Provider<List<ProductItem>>((ref) {
  return const [
    ProductItem(
      id: 'p_1',
      name: 'Aashirvaad Superior MP Atta 5kg',
      barcode: '8901030383742',
      sellingPricePaise: 24500,
      mrpPaise: 27500,
      currentStock: 18.0,
    ),
    ProductItem(
      id: 'p_2',
      name: 'Tata Salt Vacuum Evaporated 1kg',
      barcode: '8901030383743',
      sellingPricePaise: 2800,
      mrpPaise: 3000,
      currentStock: 45.0,
    ),
    ProductItem(
      id: 'p_3',
      name: 'Fortune Sunlite Sunflower Oil 1L',
      barcode: '8901030383744',
      sellingPricePaise: 13500,
      mrpPaise: 16000,
      currentStock: 12.0,
    ),
    ProductItem(
      id: 'p_4',
      name: 'Maggi 2-Minute Masala Noodles 70g',
      barcode: '8901491101837',
      sellingPricePaise: 1400,
      mrpPaise: 1400,
      currentStock: 80.0,
    ),
  ];
});

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Catalog'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(KiranaSpacing.md),
            child: AppTextField(
              hint: 'Search by product name or barcode...',
              controller: _searchController,
              prefixIcon: const Icon(Icons.search),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: KiranaSpacing.md),
              itemCount: products.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: KiranaSpacing.sm),
              itemBuilder: (context, index) {
                final p = products[index];
                return Card(
                  child: ListTile(
                    title: Text(p.name, style: KiranaTypography.titleMedium),
                    subtitle: Text(
                      'Barcode: ${p.barcode} • Stock: ${p.currentStock.toInt()} pcs',
                      style: KiranaTypography.bodySmall,
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          p.sellingPricePaise.toRupeesString(),
                          style: KiranaTypography.priceTabular.copyWith(
                            color: KiranaColors.primary,
                          ),
                        ),
                        if (p.mrpPaise > p.sellingPricePaise)
                          Text(
                            'MRP ${p.mrpPaise.toRupeesString()}',
                            style: KiranaTypography.bodySmall.copyWith(
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
