import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kirana_mobile/core/theme/colors.dart';
import 'package:kirana_mobile/core/theme/radius.dart';
import 'package:kirana_mobile/core/theme/spacing.dart';
import 'package:kirana_mobile/core/theme/typography.dart';
import 'package:kirana_mobile/core/widgets/app_button.dart';
import 'package:kirana_mobile/core/widgets/app_text_field.dart';
import 'package:kirana_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:kirana_mobile/features/products/domain/models/product_model.dart';
import 'package:kirana_mobile/features/shop/presentation/providers/shop_provider.dart';
import '../../domain/models/inventory_movement_model.dart';
import '../../domain/models/stock_adjustment_request.dart';
import '../providers/inventory_provider.dart';

class StockAdjustmentSheet extends ConsumerStatefulWidget {
  final ProductModel product;
  final VoidCallback? onStockAdjusted;

  const StockAdjustmentSheet({
    super.key,
    required this.product,
    this.onStockAdjusted,
  });

  static Future<bool?> show(BuildContext context, ProductModel product) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: StockAdjustmentSheet(product: product),
      ),
    );
  }

  @override
  ConsumerState<StockAdjustmentSheet> createState() =>
      _StockAdjustmentSheetState();
}

class _StockAdjustmentSheetState extends ConsumerState<StockAdjustmentSheet> {
  InventoryAdjustmentType _selectedType = InventoryAdjustmentType.stockIn;
  final _quantityController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedReason = 'Stock Purchase / Restock';
  String? _errorMessage;

  final List<String> _reasons = [
    'Stock Purchase / Restock',
    'Customer Return',
    'Damaged / Expired Stock',
    'Audit Adjustment',
    'Internal Consumption',
    'Other',
  ];

  @override
  void dispose() {
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitAdjustment() async {
    final qtyText = _quantityController.text.trim();
    final qty = double.tryParse(qtyText);

    if (qty == null || qty <= 0) {
      setState(() {
        _errorMessage = 'Please enter a valid quantity greater than 0';
      });
      return;
    }

    final shop = ref.read(activeShopProvider);
    final user = ref.read(authNotifierProvider).user;

    if (shop == null) {
      setState(() {
        _errorMessage = 'Active shop session missing';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    final request = StockAdjustmentRequest(
      productId: widget.product.id,
      shopId: shop.id,
      adjustmentType: _selectedType,
      quantity: qty,
      reason: _selectedReason,
      note: _noteController.text.trim().isNotEmpty
          ? _noteController.text.trim()
          : null,
      userId: user?.id ?? 'current_user',
    );

    final success = await ref
        .read(stockAdjustmentNotifierProvider.notifier)
        .adjustStock(request);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stock updated successfully!'),
          backgroundColor: KiranaColors.secondary,
        ),
      );
      Navigator.of(context).pop(true);
      widget.onStockAdjusted?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final adjustmentState = ref.watch(stockAdjustmentNotifierProvider);
    final isLoading = adjustmentState.isLoading;
    final userRole = ref.watch(authNotifierProvider).user?.role ?? 'owner';
    final isCashier = userRole == 'cashier';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(KiranaSpacing.lg),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: KiranaColors.neutral300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: KiranaSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stock Adjustment',
                      style: KiranaTypography.headlineMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.product.name,
                      style: KiranaTypography.bodyMedium.copyWith(
                        color: KiranaColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: KiranaSpacing.lg),

            if (isCashier) ...[
              Container(
                padding: const EdgeInsets.all(KiranaSpacing.md),
                decoration: BoxDecoration(
                  color: KiranaColors.errorContainer,
                  borderRadius: KiranaRadius.borderMd,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock, color: KiranaColors.error),
                    const SizedBox(width: KiranaSpacing.md),
                    Expanded(
                      child: Text(
                        'Cashier role restricted: Manual inventory adjustments require Manager or Owner authorization.',
                        style: KiranaTypography.bodySmall.copyWith(
                          color: KiranaColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: KiranaSpacing.lg),
            ],

            // Action Selection Tabs
            Row(
              children: [
                Expanded(
                  child: _TabButton(
                    label: '+ Add Stock',
                    isSelected:
                        _selectedType == InventoryAdjustmentType.stockIn,
                    activeColor: KiranaColors.secondary,
                    onTap: isCashier
                        ? null
                        : () => setState(() =>
                            _selectedType = InventoryAdjustmentType.stockIn),
                  ),
                ),
                const SizedBox(width: KiranaSpacing.xs),
                Expanded(
                  child: _TabButton(
                    label: '- Remove Stock',
                    isSelected:
                        _selectedType == InventoryAdjustmentType.stockOut,
                    activeColor: KiranaColors.error,
                    onTap: isCashier
                        ? null
                        : () => setState(() =>
                            _selectedType = InventoryAdjustmentType.stockOut),
                  ),
                ),
                const SizedBox(width: KiranaSpacing.xs),
                Expanded(
                  child: _TabButton(
                    label: 'Set Stock',
                    isSelected:
                        _selectedType == InventoryAdjustmentType.adjustment,
                    activeColor: KiranaColors.primary,
                    onTap: isCashier
                        ? null
                        : () => setState(() =>
                            _selectedType = InventoryAdjustmentType.adjustment),
                  ),
                ),
              ],
            ),
            const SizedBox(height: KiranaSpacing.lg),

            // Quantity Field
            AppTextField(
              label: _selectedType == InventoryAdjustmentType.adjustment
                  ? 'New Exact Stock Count (${widget.product.unit})'
                  : 'Quantity to ${_selectedType == InventoryAdjustmentType.stockIn ? "Add" : "Remove"} (${widget.product.unit})',
              hint: 'e.g. 10',
              controller: _quantityController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              readOnly: isCashier || isLoading,
            ),
            const SizedBox(height: KiranaSpacing.lg),

            // Reason Selector
            Text(
              'Adjustment Reason',
              style: KiranaTypography.labelLarge.copyWith(
                color: KiranaColors.textSecondary,
              ),
            ),
            const SizedBox(height: KiranaSpacing.xs),
            DropdownButtonFormField<String>(
              initialValue: _selectedReason,
              decoration: const InputDecoration(
                filled: true,
                fillColor: KiranaColors.surfaceVariant,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: KiranaSpacing.lg,
                  vertical: KiranaSpacing.md,
                ),
                border: OutlineInputBorder(
                  borderRadius: KiranaRadius.borderMd,
                  borderSide: BorderSide(color: KiranaColors.outline),
                ),
              ),
              items: _reasons.map((r) {
                return DropdownMenuItem<String>(
                  value: r,
                  child: Text(r, style: KiranaTypography.bodyMedium),
                );
              }).toList(),
              onChanged: isCashier
                  ? null
                  : (val) {
                      if (val != null) setState(() => _selectedReason = val);
                    },
            ),
            const SizedBox(height: KiranaSpacing.lg),

            // Optional Note Field
            AppTextField(
              label: 'Note / Reference (Optional)',
              hint: 'e.g. Invoice #PO-9821 or damaged packaging',
              controller: _noteController,
              readOnly: isCashier || isLoading,
            ),
            const SizedBox(height: KiranaSpacing.lg),

            if (_errorMessage != null || adjustmentState.hasError) ...[
              Text(
                _errorMessage ??
                    adjustmentState.error
                        .toString()
                        .replaceAll('Exception: ', ''),
                style: KiranaTypography.bodySmall.copyWith(
                  color: KiranaColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: KiranaSpacing.md),
            ],

            AppButton(
              label: 'Confirm Adjustment',
              isLoading: isLoading,
              onPressed: isCashier || isLoading ? null : _submitAdjustment,
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback? onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.activeColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? activeColor.withValues(alpha: 0.12)
          : KiranaColors.surfaceVariant,
      borderRadius: KiranaRadius.borderMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: KiranaRadius.borderMd,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: KiranaSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? activeColor : KiranaColors.outline,
              width: isSelected ? 1.5 : 1.0,
            ),
            borderRadius: KiranaRadius.borderMd,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? activeColor : KiranaColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
