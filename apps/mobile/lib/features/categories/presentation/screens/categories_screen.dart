import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kirana_mobile/core/extensions/context_extensions.dart';
import 'package:kirana_mobile/core/theme/colors.dart';
import 'package:kirana_mobile/core/theme/radius.dart';
import 'package:kirana_mobile/core/theme/spacing.dart';
import 'package:kirana_mobile/core/theme/typography.dart';
import 'package:kirana_mobile/core/widgets/app_button.dart';
import 'package:kirana_mobile/core/widgets/app_text_field.dart';
import 'package:kirana_mobile/features/products/presentation/providers/product_provider.dart';
import 'package:kirana_mobile/features/products/presentation/screens/products_screen.dart';
import '../../domain/models/category_model.dart';
import '../providers/category_provider.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCategoryDialog({CategoryModel? category}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CategoryFormSheet(category: category),
    );
  }

  void _handleAddProductToCategory(CategoryModel category) {
    ProductsScreenFormDialog.show(
      context,
      prefilledCategoryId: category.id,
    );
  }

  void _handleViewCategoryProducts(CategoryModel category) {
    ref.read(productCategoryFilterProvider.notifier).state = category.id;
    context.go('/products');
  }

  void _confirmArchive(CategoryModel category) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Archive Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to archive "${category.name}"?'),
            if (category.productCount > 0) ...[
              const SizedBox(height: KiranaSpacing.md),
              Container(
                padding: const EdgeInsets.all(KiranaSpacing.sm),
                decoration: BoxDecoration(
                  color: KiranaColors.warningContainer,
                  borderRadius: KiranaRadius.borderMd,
                  border: Border.all(color: KiranaColors.warning),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber,
                        size: 20, color: KiranaColors.warning),
                    const SizedBox(width: KiranaSpacing.sm),
                    Expanded(
                      child: Text(
                        'This category has ${category.productCount} active products. You must reassign products first.',
                        style: const TextStyle(
                            fontSize: 12, color: KiranaColors.neutral900),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
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
                  .read(categoryNotifierProvider.notifier)
                  .archiveCategory(category.id);

              if (mounted) {
                final state = ref.read(categoryNotifierProvider);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text(state.successMessage ?? 'Category archived'),
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
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final actionState = ref.watch(categoryNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Category',
            onPressed: () => _showCategoryDialog(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryDialog(),
        backgroundColor: KiranaColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Category',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.all(KiranaSpacing.md),
            child: AppTextField(
              hint: 'Search categories...',
              controller: _searchController,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(categorySearchQueryProvider.notifier).state =
                            '';
                        setState(() {});
                      },
                    )
                  : null,
              onChanged: (val) {
                ref.read(categorySearchQueryProvider.notifier).state = val;
                setState(() {});
              },
            ),
          ),

          // Action Status Banner (if any)
          if (actionState.errorMessage != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: KiranaSpacing.md),
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
                        .read(categoryNotifierProvider.notifier)
                        .clearMessages(),
                  ),
                ],
              ),
            ),

          // Categories List/Grid
          Expanded(
            child: categoriesAsync.when(
              data: (categories) {
                if (categories.isEmpty) {
                  return _buildEmptyView();
                }

                if (context.isWideScreen) {
                  return GridView.builder(
                    padding: const EdgeInsets.all(KiranaSpacing.md),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 2.2,
                      crossAxisSpacing: KiranaSpacing.md,
                      mainAxisSpacing: KiranaSpacing.md,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      return _CategoryCard(
                        category: cat,
                        onAddProduct: () => _handleAddProductToCategory(cat),
                        onViewProducts: () => _handleViewCategoryProducts(cat),
                        onEdit: () => _showCategoryDialog(category: cat),
                        onArchive: () => _confirmArchive(cat),
                      );
                    },
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(KiranaSpacing.md),
                  itemCount: categories.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: KiranaSpacing.sm),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    return _CategoryCard(
                      category: cat,
                      onAddProduct: () => _handleAddProductToCategory(cat),
                      onViewProducts: () => _handleViewCategoryProducts(cat),
                      onEdit: () => _showCategoryDialog(category: cat),
                      onArchive: () => _confirmArchive(cat),
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
                    Text('Failed to load categories',
                        style: KiranaTypography.titleMedium),
                    const SizedBox(height: KiranaSpacing.lg),
                    ElevatedButton(
                      onPressed: () => ref.refresh(categoriesStreamProvider),
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
    final query = ref.watch(categorySearchQueryProvider);
    final isSearching = query.trim().isNotEmpty;

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
                isSearching ? Icons.search_off : Icons.category_outlined,
                size: 48,
                color: KiranaColors.primary,
              ),
            ),
            const SizedBox(height: KiranaSpacing.lg),
            Text(
              isSearching
                  ? 'No categories match "$query"'
                  : 'No product categories yet',
              style: KiranaTypography.titleMedium
                  .copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KiranaSpacing.xs),
            Text(
              isSearching
                  ? 'Try searching with a different name or clear the search query.'
                  : 'Create categories like Grains, Dairy, Oils, or Snacks to organize your catalog.',
              style: KiranaTypography.bodyMedium
                  .copyWith(color: KiranaColors.neutral600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KiranaSpacing.xl),
            if (isSearching)
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  ref.read(categorySearchQueryProvider.notifier).state = '';
                  setState(() {});
                },
                icon: const Icon(Icons.clear),
                label: const Text('Clear Search'),
              )
            else
              AppButton(
                label: '+ Create First Category',
                onPressed: () => _showCategoryDialog(),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onAddProduct;
  final VoidCallback onViewProducts;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  const _CategoryCard({
    required this.category,
    required this.onAddProduct,
    required this.onViewProducts,
    required this.onEdit,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: KiranaRadius.borderMd,
        side: const BorderSide(color: KiranaColors.neutral200),
      ),
      child: InkWell(
        onTap: onViewProducts,
        borderRadius: KiranaRadius.borderMd,
        child: Padding(
          padding: const EdgeInsets.all(KiranaSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Category Icon / Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: KiranaColors.primaryContainer,
                child: Text(
                  category.name.isNotEmpty
                      ? category.name[0].toUpperCase()
                      : 'C',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: KiranaColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: KiranaSpacing.md),

              // Name & Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      category.name,
                      style: KiranaTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (category.description != null &&
                        category.description!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        category.description!,
                        style: KiranaTypography.bodySmall.copyWith(
                          color: KiranaColors.neutral600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: onViewProducts,
                      borderRadius: KiranaRadius.borderPill,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: KiranaColors.neutral100,
                          borderRadius: KiranaRadius.borderPill,
                        ),
                        child: Text(
                          '${category.productCount} ${category.productCount == 1 ? 'item' : 'items'} • Tap to view',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: KiranaColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Action Menu
              PopupMenuButton<String>(
                icon:
                    const Icon(Icons.more_vert, color: KiranaColors.neutral600),
                onSelected: (value) {
                  if (value == 'add_product') onAddProduct();
                  if (value == 'view_products') onViewProducts();
                  if (value == 'edit') onEdit();
                  if (value == 'archive') onArchive();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'add_product',
                    child: Row(
                      children: [
                        Icon(Icons.add_circle_outline,
                            size: 18, color: KiranaColors.primary),
                        SizedBox(width: KiranaSpacing.sm),
                        Text('Add Product in Category',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: KiranaColors.primary)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'view_products',
                    child: Row(
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 18),
                        SizedBox(width: KiranaSpacing.sm),
                        Text('View Products'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: KiranaSpacing.sm),
                        Text('Edit Category'),
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
                        Text('Archive Category',
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

class _CategoryFormSheet extends ConsumerStatefulWidget {
  final CategoryModel? category;

  const _CategoryFormSheet({this.category});

  @override
  ConsumerState<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<_CategoryFormSheet> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String? _validationError;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _descController.text = widget.category!.description ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final name = _nameController.text.trim();
    final desc = _descController.text.trim();

    if (name.isEmpty) {
      setState(() => _validationError = 'Category name is required.');
      return;
    }

    setState(() => _validationError = null);

    bool success = false;
    if (widget.category == null) {
      // Create
      success =
          await ref.read(categoryNotifierProvider.notifier).createCategory(
                name: name,
                description: desc.isNotEmpty ? desc : null,
              );
    } else {
      // Update
      success =
          await ref.read(categoryNotifierProvider.notifier).updateCategory(
                id: widget.category!.id,
                name: name,
                description: desc.isNotEmpty ? desc : null,
              );
    }

    if (success && mounted) {
      Navigator.pop(context);
      final state = ref.read(categoryNotifierProvider);
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
    final actionState = ref.watch(categoryNotifierProvider);
    final isEditing = widget.category != null;
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Edit Category' : 'Create Category',
                  style: KiranaTypography.headlineMedium
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: KiranaSpacing.sm),
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
                  style:
                      const TextStyle(fontSize: 13, color: KiranaColors.error),
                ),
              ),
              const SizedBox(height: KiranaSpacing.md),
            ],
            AppTextField(
              label: 'Category Name *',
              hint: 'e.g. Atta, Rice & Grains',
              controller: _nameController,
              prefixIcon: const Icon(Icons.category_outlined),
            ),
            const SizedBox(height: KiranaSpacing.lg),
            AppTextField(
              label: 'Description (Optional)',
              hint: 'e.g. Flours, whole grains, basmati rice',
              controller: _descController,
              prefixIcon: const Icon(Icons.description_outlined),
            ),
            const SizedBox(height: KiranaSpacing.xl),
            AppButton(
              label: isEditing ? 'Save Changes' : 'Create Category',
              isLoading: actionState.isLoading,
              onPressed: actionState.isLoading ? null : _handleSubmit,
            ),
          ],
        ),
      ),
    );
  }
}
