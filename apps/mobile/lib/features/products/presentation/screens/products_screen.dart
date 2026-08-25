import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kirana_mobile/core/extensions/context_extensions.dart';
import 'package:kirana_mobile/core/extensions/num_extensions.dart';
import 'package:kirana_mobile/core/theme/colors.dart';
import 'package:kirana_mobile/core/theme/radius.dart';
import 'package:kirana_mobile/core/theme/spacing.dart';
import 'package:kirana_mobile/core/theme/typography.dart';
import 'package:kirana_mobile/core/widgets/app_button.dart';
import 'package:kirana_mobile/core/widgets/app_text_field.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kirana_mobile/features/categories/presentation/providers/category_provider.dart';
import 'package:kirana_mobile/features/barcodes/presentation/widgets/product_barcode_section.dart';
import '../widgets/product_image_picker.dart';
import 'package:kirana_mobile/features/inventory/presentation/widgets/stock_adjustment_sheet.dart';
import '../../domain/models/product_model.dart';
import '../providers/product_provider.dart';

const List<String> kAvailableUnits = [
  'PCS',
  'KG',
  'LITER',
  'GM',
  'ML',
  'PACK',
  'DOZEN',
  'BOX',
  'CAN',
  'BOTTLE',
];

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showProductDialog({ProductModel? product, String? prefilledBarcode}) {
    ProductsScreenFormDialog.show(
      context,
      product: product,
      prefilledBarcode: prefilledBarcode,
    );
  }

  void _confirmArchive(ProductModel product) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Archive Product'),
        content: Text('Are you sure you want to archive "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: KiranaColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final success = await ref
                  .read(productNotifierProvider.notifier)
                  .archiveProduct(product.id);

              if (mounted) {
                final state = ref.read(productNotifierProvider);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.successMessage ?? 'Product archived'),
                      backgroundColor: KiranaColors.success,
                    ),
                  );
                } else if (state.errorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.errorMessage!),
                      backgroundColor: KiranaColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final selectedCategory = ref.watch(productCategoryFilterProvider);
    final actionState = ref.watch(productNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Catalog'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Product',
            onPressed: () => _showProductDialog(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductDialog(),
        backgroundColor: KiranaColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Product',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(
              KiranaSpacing.md,
              KiranaSpacing.md,
              KiranaSpacing.md,
              KiranaSpacing.xs,
            ),
            child: AppTextField(
              hint: 'Search by product name, brand, description...',
              controller: _searchController,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(productSearchQueryProvider.notifier).state =
                            '';
                        setState(() {});
                      },
                    )
                  : null,
              onChanged: (val) {
                ref.read(productSearchQueryProvider.notifier).state = val;
                setState(() {});
              },
            ),
          ),

          // 2. Category Filter Chips (Horizontal)
          categoriesAsync.when(
            data: (categories) {
              if (categories.isEmpty) return const SizedBox.shrink();
              return SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: KiranaSpacing.md),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: KiranaSpacing.xs),
                      child: FilterChip(
                        label: const Text('All Categories'),
                        selected: selectedCategory == null,
                        onSelected: (_) {
                          ref
                              .read(productCategoryFilterProvider.notifier)
                              .state = null;
                        },
                      ),
                    ),
                    ...categories.map((cat) {
                      final isSelected = selectedCategory == cat.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: KiranaSpacing.xs),
                        child: FilterChip(
                          label: Text(cat.name),
                          selected: isSelected,
                          onSelected: (_) {
                            ref
                                .read(productCategoryFilterProvider.notifier)
                                .state = isSelected ? null : cat.id;
                          },
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // 3. Action Status Banner
          if (actionState.errorMessage != null)
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: KiranaSpacing.md,
                vertical: KiranaSpacing.xs,
              ),
              padding: const EdgeInsets.all(KiranaSpacing.sm),
              decoration: BoxDecoration(
                color: KiranaColors.errorContainer,
                borderRadius: KiranaRadius.borderMd,
                border: Border.all(color: KiranaColors.error),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      size: 18, color: KiranaColors.error),
                  const SizedBox(width: KiranaSpacing.xs),
                  Expanded(
                    child: Text(
                      actionState.errorMessage!,
                      style: const TextStyle(
                          color: KiranaColors.error, fontSize: 13),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        size: 16, color: KiranaColors.error),
                    onPressed: () => ref
                        .read(productNotifierProvider.notifier)
                        .clearMessages(),
                  ),
                ],
              ),
            ),

          // 4. Products List / Grid
          Expanded(
            child: productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return _buildEmptyView();
                }

                if (context.isWideScreen) {
                  return GridView.builder(
                    padding: const EdgeInsets.all(KiranaSpacing.md),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.8,
                      crossAxisSpacing: KiranaSpacing.md,
                      mainAxisSpacing: KiranaSpacing.md,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return _ProductCard(
                        product: product,
                        onEdit: () => _showProductDialog(product: product),
                        onArchive: () => _confirmArchive(product),
                      );
                    },
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(KiranaSpacing.md),
                  itemCount: products.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: KiranaSpacing.sm),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return _ProductCard(
                      product: product,
                      onEdit: () => _showProductDialog(product: product),
                      onArchive: () => _confirmArchive(product),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: KiranaColors.error),
                    const SizedBox(height: KiranaSpacing.md),
                    Text('Failed to load products',
                        style: KiranaTypography.titleMedium),
                    const SizedBox(height: KiranaSpacing.lg),
                    ElevatedButton(
                      onPressed: () => ref.refresh(productsStreamProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    final query = ref.watch(productSearchQueryProvider);
    final categoryFilter = ref.watch(productCategoryFilterProvider);
    final isFiltering = query.trim().isNotEmpty || categoryFilter != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KiranaSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(KiranaSpacing.xl),
              decoration: const BoxDecoration(
                color: KiranaColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFiltering ? Icons.search_off : Icons.inventory_2_outlined,
                size: 48,
                color: KiranaColors.primary,
              ),
            ),
            const SizedBox(height: KiranaSpacing.lg),
            Text(
              isFiltering
                  ? 'No matching products found'
                  : 'No products in catalog',
              style: KiranaTypography.titleMedium
                  .copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KiranaSpacing.xs),
            Text(
              isFiltering
                  ? 'Try searching with another name or clear active category filters.'
                  : 'Add your first product to manage prices, categories, and inventory stock.',
              style: KiranaTypography.bodyMedium
                  .copyWith(color: KiranaColors.neutral600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KiranaSpacing.xl),
            if (isFiltering)
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  ref.read(productSearchQueryProvider.notifier).state = '';
                  ref.read(productCategoryFilterProvider.notifier).state = null;
                  setState(() {});
                },
                icon: const Icon(Icons.clear),
                label: const Text('Clear Filters'),
              )
            else
              AppButton(
                label: '+ Add First Product',
                onPressed: () => _showProductDialog(),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  const _ProductCard({
    required this.product,
    required this.onEdit,
    required this.onArchive,
  });

  Widget _buildInitialAvatar(ProductModel product) {
    return Center(
      child: Text(
        product.name.isNotEmpty ? product.name[0].toUpperCase() : 'P',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: KiranaColors.secondary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLowStock = product.currentStock <= product.minStockAlert &&
        product.minStockAlert > 0;

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: KiranaRadius.borderMd,
        side: const BorderSide(color: KiranaColors.neutral200),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: KiranaRadius.borderMd,
        child: Padding(
          padding: const EdgeInsets.all(KiranaSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Product Avatar / Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: KiranaColors.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child:
                      product.imageUrl != null && product.imageUrl!.isNotEmpty
                          ? (product.imageUrl!.startsWith('http')
                              ? Image.network(
                                  product.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _buildInitialAvatar(product),
                                )
                              : _buildInitialAvatar(product))
                          : _buildInitialAvatar(product),
                ),
              ),
              const SizedBox(width: KiranaSpacing.md),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product.name,
                      style: KiranaTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),

                    // Brand & Category & Unit Row
                    Row(
                      children: [
                        if (product.brand != null &&
                            product.brand!.isNotEmpty) ...[
                          Text(
                            product.brand!,
                            style: KiranaTypography.bodySmall.copyWith(
                              color: KiranaColors.neutral700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Text(' • ',
                              style: TextStyle(color: KiranaColors.neutral400)),
                        ],
                        if (product.categoryName != null) ...[
                          Flexible(
                            child: Text(
                              product.categoryName!,
                              style: KiranaTypography.bodySmall.copyWith(
                                color: KiranaColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Text(' • ',
                              style: TextStyle(color: KiranaColors.neutral400)),
                        ],
                        Text(
                          product.unit,
                          style: KiranaTypography.bodySmall.copyWith(
                            color: KiranaColors.neutral600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Stock status
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isLowStock
                                ? KiranaColors.warningContainer
                                : KiranaColors.neutral100,
                            borderRadius: KiranaRadius.borderPill,
                          ),
                          child: Text(
                            isLowStock
                                ? 'Low Stock: ${product.currentStock.toStringAsFixed(0)} ${product.unit}'
                                : 'Stock: ${product.currentStock.toStringAsFixed(0)} ${product.unit}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isLowStock
                                  ? KiranaColors.warning
                                  : KiranaColors.neutral700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Price Display
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    product.sellingPricePaise.toRupeesString(),
                    style: KiranaTypography.priceTabular.copyWith(
                      color: KiranaColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (product.mrpPaise > product.sellingPricePaise) ...[
                    const SizedBox(height: 2),
                    Text(
                      'MRP ${product.mrpPaise.toRupeesString()}',
                      style: KiranaTypography.bodySmall.copyWith(
                        decoration: TextDecoration.lineThrough,
                        color: KiranaColors.neutral500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),

              // Actions Menu
              PopupMenuButton<String>(
                icon:
                    const Icon(Icons.more_vert, color: KiranaColors.neutral600),
                onSelected: (value) {
                  if (value == 'adjust_stock') {
                    StockAdjustmentSheet.show(context, product);
                  }
                  if (value == 'edit') onEdit();
                  if (value == 'archive') onArchive();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'adjust_stock',
                    child: Row(
                      children: [
                        Icon(Icons.edit_note, size: 18),
                        SizedBox(width: KiranaSpacing.sm),
                        Text('Adjust Stock'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: KiranaSpacing.sm),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'archive',
                    child: Row(
                      children: [
                        Icon(Icons.archive_outlined,
                            size: 18, color: KiranaColors.error),
                        SizedBox(width: KiranaSpacing.sm),
                        Text('Archive',
                            style: TextStyle(color: KiranaColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductsScreenFormDialog extends ConsumerStatefulWidget {
  final ProductModel? product;
  final String? prefilledBarcode;
  final String? prefilledCategoryId;

  const ProductsScreenFormDialog({
    super.key,
    this.product,
    this.prefilledBarcode,
    this.prefilledCategoryId,
  });

  static Future<void> show(
    BuildContext context, {
    ProductModel? product,
    String? prefilledBarcode,
    String? prefilledCategoryId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductsScreenFormDialog(
        product: product,
        prefilledBarcode: prefilledBarcode,
        prefilledCategoryId: prefilledCategoryId,
      ),
    );
  }

  @override
  ConsumerState<ProductsScreenFormDialog> createState() =>
      _ProductsScreenFormDialogState();
}

class _ProductsScreenFormDialogState
    extends ConsumerState<ProductsScreenFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _minStockController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedCategoryId;
  String _selectedUnit = 'PCS';
  String? _validationError;
  XFile? _pendingImage;
  bool _isImageRemoved = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      final p = widget.product!;
      _nameController.text = p.name;
      _brandController.text = p.brand ?? '';
      _sellingPriceController.text =
          (p.sellingPricePaise / 100).toStringAsFixed(2);
      _purchasePriceController.text = p.purchasePricePaise > 0
          ? (p.purchasePricePaise / 100).toStringAsFixed(2)
          : '';
      _minStockController.text = p.minStockAlert.toStringAsFixed(0);
      _descriptionController.text = p.description ?? '';
      _selectedCategoryId = p.categoryId;
      _selectedUnit = p.unit;
    } else {
      _minStockController.text = '5';
      if (widget.prefilledCategoryId != null) {
        _selectedCategoryId = widget.prefilledCategoryId;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _sellingPriceController.dispose();
    _purchasePriceController.dispose();
    _minStockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final name = _nameController.text.trim();
    final brand = _brandController.text.trim();
    final desc = _descriptionController.text.trim();
    final spText = _sellingPriceController.text.trim();
    final ppText = _purchasePriceController.text.trim();
    final minStockText = _minStockController.text.trim();

    if (name.isEmpty) {
      setState(() => _validationError = 'Product name is required.');
      return;
    }

    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      setState(() => _validationError = 'Please select a Category.');
      return;
    }

    final spDouble = double.tryParse(spText);
    if (spDouble == null || spDouble <= 0) {
      setState(() =>
          _validationError = 'Enter a valid Selling Price greater than ₹0.');
      return;
    }
    final sellingPricePaise = (spDouble * 100).round();

    int purchasePricePaise = 0;
    if (ppText.isNotEmpty) {
      final ppDouble = double.tryParse(ppText);
      if (ppDouble == null || ppDouble < 0) {
        setState(() => _validationError = 'Purchase price cannot be negative.');
        return;
      }
      purchasePricePaise = (ppDouble * 100).round();
    }

    double minStock = 5.0;
    if (minStockText.isNotEmpty) {
      final ms = double.tryParse(minStockText);
      if (ms == null || ms < 0) {
        setState(
            () => _validationError = 'Minimum stock alert cannot be negative.');
        return;
      }
      minStock = ms;
    }

    setState(() => _validationError = null);

    bool success = false;
    if (widget.product == null) {
      // Create
      success = await ref.read(productNotifierProvider.notifier).createProduct(
            name: name,
            categoryId: _selectedCategoryId!,
            brand: brand.isNotEmpty ? brand : null,
            unit: _selectedUnit,
            sellingPricePaise: sellingPricePaise,
            purchasePricePaise: purchasePricePaise,
            minStockAlert: minStock,
            description: desc.isNotEmpty ? desc : null,
            barcode: widget.prefilledBarcode,
          );
    } else {
      // Update
      success = await ref.read(productNotifierProvider.notifier).updateProduct(
            id: widget.product!.id,
            name: name,
            categoryId: _selectedCategoryId!,
            brand: brand.isNotEmpty ? brand : null,
            unit: _selectedUnit,
            sellingPricePaise: sellingPricePaise,
            purchasePricePaise: purchasePricePaise,
            minStockAlert: minStock,
            description: desc.isNotEmpty ? desc : null,
          );
    }

    if (success && mounted) {
      final notifier = ref.read(productNotifierProvider.notifier);
      final targetProductId = widget.product?.id ??
          ref
              .read(productsStreamProvider)
              .asData
              ?.value
              .firstWhere((p) => p.name == name)
              .id;

      if (targetProductId != null) {
        if (_isImageRemoved) {
          await notifier.deleteProductImage(targetProductId);
        } else if (_pendingImage != null) {
          final bytes = await _pendingImage!.readAsBytes();
          await notifier.uploadProductImage(
            productId: targetProductId,
            imageBytes: bytes,
            fileName: _pendingImage!.name,
          );
        }
      }

      if (!mounted) return;
      Navigator.pop(context);
      final state = ref.read(productNotifierProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.successMessage ?? 'Saved successfully'),
          backgroundColor: KiranaColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final actionState = ref.watch(productNotifierProvider);
    final isEditing = widget.product != null;
    final errorMessage = _validationError ?? actionState.errorMessage;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: KiranaSpacing.xl,
        right: KiranaSpacing.xl,
        top: KiranaSpacing.xl,
        bottom: MediaQuery.of(context).viewInsets.bottom + KiranaSpacing.xl,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Product' : 'Add New Product',
                    style: KiranaTypography.headlineMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: KiranaSpacing.sm),

              Center(
                child: ProductImagePicker(
                  currentImageUrl: widget.product?.imageUrl,
                  isLoading: actionState.isLoading,
                  onImageSelected: (file) {
                    setState(() {
                      _pendingImage = file;
                      _isImageRemoved = false;
                    });
                  },
                  onImageRemoved: () {
                    setState(() {
                      _pendingImage = null;
                      _isImageRemoved = true;
                    });
                  },
                ),
              ),
              const SizedBox(height: KiranaSpacing.md),

              if (errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(KiranaSpacing.sm),
                  decoration: BoxDecoration(
                    color: KiranaColors.errorContainer,
                    borderRadius: KiranaRadius.borderMd,
                    border: Border.all(color: KiranaColors.error),
                  ),
                  child: Text(
                    errorMessage,
                    style: const TextStyle(
                        fontSize: 13, color: KiranaColors.error),
                  ),
                ),
                const SizedBox(height: KiranaSpacing.md),
              ],

              if (widget.prefilledBarcode != null && !isEditing) ...[
                Container(
                  padding: const EdgeInsets.all(KiranaSpacing.sm),
                  decoration: BoxDecoration(
                    color: KiranaColors.primaryContainer,
                    borderRadius: KiranaRadius.borderMd,
                    border: Border.all(color: KiranaColors.primary),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.qr_code,
                          size: 18, color: KiranaColors.primary),
                      const SizedBox(width: KiranaSpacing.xs),
                      Text(
                        'Linking Scanned Barcode: ',
                        style: KiranaTypography.bodySmall.copyWith(
                          color: KiranaColors.neutral700,
                        ),
                      ),
                      Text(
                        widget.prefilledBarcode!,
                        style: KiranaTypography.priceTabular.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: KiranaColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: KiranaSpacing.md),
              ],

              // Product Name *
              AppTextField(
                label: 'Product Name *',
                hint: 'e.g. Aashirvaad Shudh Chakki Atta 5kg',
                controller: _nameController,
                prefixIcon: const Icon(Icons.shopping_bag_outlined),
              ),
              const SizedBox(height: KiranaSpacing.md),

              // Category Selector *
              categoriesAsync.when(
                data: (categories) {
                  // Ensure current selection is valid
                  final hasMatch =
                      categories.any((c) => c.id == _selectedCategoryId);
                  if (!hasMatch && categories.isNotEmpty && !isEditing) {
                    _selectedCategoryId = categories.first.id;
                  }

                  return DropdownButtonFormField<String>(
                    initialValue: _selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Category *',
                      prefixIcon: Icon(Icons.category_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: categories
                        .map((cat) => DropdownMenuItem(
                              value: cat.id,
                              child: Text(cat.name),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setState(() => _selectedCategoryId = val);
                    },
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Failed to load categories'),
              ),
              const SizedBox(height: KiranaSpacing.md),

              // Brand & Unit Row
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: AppTextField(
                      label: 'Brand (Optional)',
                      hint: 'e.g. ITC, Tata, Amul',
                      controller: _brandController,
                      prefixIcon: const Icon(Icons.branding_watermark_outlined),
                    ),
                  ),
                  const SizedBox(width: KiranaSpacing.md),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedUnit,
                      decoration: const InputDecoration(
                        labelText: 'Unit *',
                        border: OutlineInputBorder(),
                      ),
                      items: kAvailableUnits
                          .map((u) => DropdownMenuItem(
                                value: u,
                                child: Text(u),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedUnit = val);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: KiranaSpacing.md),

              // Selling Price & Purchase Price Row
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Selling Price (₹) *',
                      hint: 'e.g. 245.00',
                      controller: _sellingPriceController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: const Icon(Icons.currency_rupee),
                    ),
                  ),
                  const SizedBox(width: KiranaSpacing.md),
                  Expanded(
                    child: AppTextField(
                      label: 'Purchase Price (₹)',
                      hint: 'e.g. 210.00',
                      controller: _purchasePriceController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: const Icon(Icons.shopping_cart_outlined),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: KiranaSpacing.md),

              // Minimum Stock Alert
              AppTextField(
                label: 'Minimum Stock Alert',
                hint: 'Default: 5',
                controller: _minStockController,
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.warning_amber_outlined),
              ),
              const SizedBox(height: KiranaSpacing.md),

              // Description (Optional)
              AppTextField(
                label: 'Description (Optional)',
                hint: 'Product details, packaging size...',
                controller: _descriptionController,
                prefixIcon: const Icon(Icons.description_outlined),
              ),
              const SizedBox(height: KiranaSpacing.lg),

              if (isEditing) ...[
                ProductBarcodeSection(productId: widget.product!.id),
                const SizedBox(height: KiranaSpacing.lg),
              ],

              // Submit Button
              AppButton(
                label: isEditing ? 'Save Product Changes' : 'Create Product',
                isLoading: actionState.isLoading,
                onPressed: actionState.isLoading ? null : _handleSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
