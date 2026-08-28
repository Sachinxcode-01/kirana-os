import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/radius.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../../../database/drift/database.dart';
import '../../../products/presentation/providers/product_provider.dart';
import '../../../suppliers/domain/models/supplier_model.dart';
import '../../../suppliers/presentation/providers/supplier_provider.dart';

class RecordPurchaseItemDraft {
  final ProductData product;
  double quantity;
  int purchasePricePaise;
  double taxRate;

  RecordPurchaseItemDraft({
    required this.product,
    this.quantity = 1.0,
    required this.purchasePricePaise,
    this.taxRate = 0.0,
  });

  int get subtotalPaise => (quantity * purchasePricePaise).round();
  int get taxPaise => (subtotalPaise * (taxRate / 100.0)).round();
  int get totalPaise => subtotalPaise + taxPaise;
}

class RecordPurchaseScreen extends ConsumerStatefulWidget {
  const RecordPurchaseScreen({super.key});

  @override
  ConsumerState<RecordPurchaseScreen> createState() =>
      _RecordPurchaseScreenState();
}

class _RecordPurchaseScreenState extends ConsumerState<RecordPurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _invoiceNumController = TextEditingController();
  DateTime _invoiceDate = DateTime.now();
  SupplierModel? _selectedSupplier;

  final List<RecordPurchaseItemDraft> _items = [];
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _invoiceNumController.dispose();
    super.dispose();
  }

  static String _formatRupees(int paise) {
    final double rupees = paise / 100.0;
    return '₹${rupees.toStringAsFixed(2)}';
  }

  int get _subtotalPaise =>
      _items.fold(0, (sum, item) => sum + item.subtotalPaise);
  int get _taxTotalPaise => _items.fold(0, (sum, item) => sum + item.taxPaise);
  int get _grandTotalPaise => _subtotalPaise + _taxTotalPaise;

  void _addItem(ProductData product) {
    final existingIndex =
        _items.indexWhere((item) => item.product.id == product.id);
    if (existingIndex >= 0) {
      setState(() {
        _items[existingIndex].quantity += 1.0;
      });
    } else {
      setState(() {
        _items.add(RecordPurchaseItemDraft(
          product: product,
          quantity: 1.0,
          purchasePricePaise: product.purchasePricePaise?.toInt() ??
              product.sellingPricePaise.toInt(),
          taxRate: product.gstRate,
        ));
      });
    }
  }

  Future<void> _submitPurchase() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      setState(() {
        _errorMessage = 'Please add at least one product to purchase order.';
      });
      return;
    }

    final authState = ref.read(authNotifierProvider);
    final shopId = authState.activeShopId;
    if (shopId == null) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final repo = ref.read(supplierRepositoryProvider);

    final lineItems = _items
        .map((item) => (
              productId: item.product.id,
              productName: item.product.name,
              quantity: item.quantity,
              purchasePricePaise: item.purchasePricePaise,
              taxRate: item.taxRate,
            ))
        .toList();

    final result = await repo.recordPurchase(
      shopId: shopId,
      supplierId: _selectedSupplier?.id,
      supplierNameSnapshot: _selectedSupplier?.name,
      invoiceNumber: _invoiceNumController.text,
      invoiceDate: _invoiceDate,
      lineItems: lineItems,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      ref.invalidate(suppliersListNotifierProvider);
      ref.invalidate(productsStreamProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Stock purchase recorded successfully! Inventory updated.'),
          backgroundColor: KiranaColors.success,
        ),
      );

      Navigator.of(context).pop();
    } else {
      setState(() {
        _isSaving = false;
        _errorMessage =
            result.failureOrNull?.message ?? 'Failed to record purchase';
      });
    }
  }

  void _showProductPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _ProductPickerSheet(onSelected: _addItem),
    );
  }

  @override
  Widget build(BuildContext context) {
    final suppliersState = ref.watch(suppliersListNotifierProvider);
    final activeSuppliers =
        suppliersState.suppliers.where((s) => !s.isArchived).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Inward Stock Purchase'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(KiranaSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(KiranaSpacing.md),
                  decoration: BoxDecoration(
                    color: KiranaColors.errorContainer,
                    borderRadius: KiranaRadius.borderSm,
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Colors.red[900],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: KiranaSpacing.md),
              ],

              // Supplier Selector & Invoice Header Card
              Card(
                elevation: 1,
                shape:
                    RoundedRectangleBorder(borderRadius: KiranaRadius.borderMd),
                child: Padding(
                  padding: const EdgeInsets.all(KiranaSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Purchase Invoice Details',
                          style: KiranaTypography.titleMedium
                              .copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: KiranaSpacing.md),

                      // Supplier Dropdown
                      DropdownButtonFormField<SupplierModel>(
                        value: _selectedSupplier,
                        decoration: const InputDecoration(
                          labelText: 'Select Supplier (Optional)',
                          prefixIcon: Icon(Icons.business_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: activeSuppliers.map((s) {
                          return DropdownMenuItem(
                            value: s,
                            child: Text('${s.name} (${s.phone})'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedSupplier = val);
                        },
                      ),
                      const SizedBox(height: KiranaSpacing.md),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _invoiceNumController,
                              decoration: const InputDecoration(
                                labelText: 'Invoice Number *',
                                hintText: 'e.g. INV-2026-901',
                                prefixIcon: Icon(Icons.receipt_long),
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) =>
                                  val == null || val.trim().isEmpty
                                      ? 'Enter invoice number'
                                      : null,
                            ),
                          ),
                          const SizedBox(width: KiranaSpacing.md),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _invoiceDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setState(() => _invoiceDate = picked);
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Invoice Date',
                                  prefixIcon: Icon(Icons.calendar_today),
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(
                                  '${_invoiceDate.day}/${_invoiceDate.month}/${_invoiceDate.year}',
                                  style: KiranaTypography.bodyMedium,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: KiranaSpacing.lg),

              // Items Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Purchase Items (${_items.length})',
                      style: KiranaTypography.titleLarge
                          .copyWith(fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KiranaColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _showProductPicker,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Product'),
                  ),
                ],
              ),
              const SizedBox(height: KiranaSpacing.sm),

              // Items Table / Cards
              if (_items.isEmpty)
                Container(
                  padding: const EdgeInsets.all(KiranaSpacing.xxl),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: KiranaRadius.borderMd,
                    border: Border.all(color: KiranaColors.neutral300),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          size: 48, color: KiranaColors.neutral400),
                      SizedBox(height: KiranaSpacing.sm),
                      Text('No products added yet',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: KiranaSpacing.xs),
                      Text(
                          'Tap "+ Add Product" above to add inward stock items.',
                          style: TextStyle(
                              fontSize: 12, color: KiranaColors.neutral600)),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: KiranaSpacing.xs),
                  itemBuilder: (ctx, index) {
                    final item = _items[index];
                    return _PurchaseItemCard(
                      item: item,
                      onChanged: () => setState(() {}),
                      onRemove: () {
                        setState(() => _items.removeAt(index));
                      },
                    );
                  },
                ),

              const SizedBox(height: KiranaSpacing.lg),

              // Summary Breakdown Card
              Card(
                elevation: 2,
                color: KiranaColors.primaryContainer.withValues(alpha: 0.3),
                shape:
                    RoundedRectangleBorder(borderRadius: KiranaRadius.borderMd),
                child: Padding(
                  padding: const EdgeInsets.all(KiranaSpacing.lg),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal',
                              style: KiranaTypography.bodyMedium),
                          Text(_formatRupees(_subtotalPaise),
                              style: KiranaTypography.bodyMedium),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tax Total',
                              style: KiranaTypography.bodyMedium),
                          Text(_formatRupees(_taxTotalPaise),
                              style: KiranaTypography.bodyMedium),
                        ],
                      ),
                      const Divider(height: KiranaSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Grand Purchase Total',
                              style: KiranaTypography.titleLarge
                                  .copyWith(fontWeight: FontWeight.bold)),
                          Text(
                            _formatRupees(_grandTotalPaise),
                            style: KiranaTypography.headlineMedium.copyWith(
                              color: KiranaColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: KiranaSpacing.xl),

              // Action Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: KiranaColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _isSaving ? null : _submitPurchase,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle),
                label: Text(
                  _isSaving
                      ? 'RECORDING STOCK IN...'
                      : 'RECORD PURCHASE & STOCK IN',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PurchaseItemCard extends StatelessWidget {
  final RecordPurchaseItemDraft item;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  const _PurchaseItemCard({
    required this.item,
    required this.onChanged,
    required this.onRemove,
  });

  static String _formatRupees(int paise) {
    final double rupees = paise / 100.0;
    return '₹${rupees.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final costRupees = (item.purchasePricePaise / 100.0).toStringAsFixed(2);

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(KiranaSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.product.name,
                    style: KiranaTypography.titleMedium
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: KiranaColors.error, size: 20),
                  onPressed: onRemove,
                ),
              ],
            ),
            const SizedBox(height: KiranaSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: item.quantity.toStringAsFixed(0),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Qty Inward',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      final q = double.tryParse(val.trim());
                      if (q != null && q > 0) {
                        item.quantity = q;
                        onChanged();
                      }
                    },
                  ),
                ),
                const SizedBox(width: KiranaSpacing.xs),
                Expanded(
                  child: TextFormField(
                    initialValue: costRupees,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Cost Price (₹)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      final r = double.tryParse(val.trim());
                      if (r != null && r >= 0) {
                        item.purchasePricePaise = (r * 100).round();
                        onChanged();
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: KiranaSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tax: ${item.taxRate.toStringAsFixed(0)}%',
                  style: KiranaTypography.bodySmall,
                ),
                Text(
                  'Line Total: ${_formatRupees(item.totalPaise)}',
                  style: KiranaTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: KiranaColors.primary,
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

class _ProductPickerSheet extends ConsumerWidget {
  final ValueChanged<ProductData> onSelected;

  const _ProductPickerSheet({required this.onSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsStreamProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      builder: (ctx, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(KiranaSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select Product for Inward Purchase',
                  style: KiranaTypography.titleLarge),
              const SizedBox(height: KiranaSpacing.sm),
              Expanded(
                child: productsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) =>
                      const Center(child: Text('Failed to load products')),
                  data: (products) {
                    if (products.isEmpty) {
                      return const Center(
                          child: Text('No products in inventory'));
                    }
                    return ListView.separated(
                      controller: scrollController,
                      itemCount: products.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final p = products[i];
                        return ListTile(
                          title: Text(p.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              'Current Stock: ${p.stockQuantity.toStringAsFixed(0)} ${p.unit}'),
                          trailing: const Icon(Icons.add_circle_outline,
                              color: KiranaColors.primary),
                          onTap: () {
                            onSelected(p);
                            Navigator.of(ctx).pop();
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
