import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kirana_mobile/app/app_providers.dart';
import 'package:kirana_mobile/core/network/connectivity_status.dart';
import 'package:kirana_mobile/core/theme/colors.dart';
import 'package:kirana_mobile/core/theme/radius.dart';
import 'package:kirana_mobile/core/theme/spacing.dart';
import 'package:kirana_mobile/core/theme/typography.dart';
import 'package:kirana_mobile/core/widgets/app_button.dart';
import 'package:kirana_mobile/core/widgets/app_text_field.dart';
import 'package:kirana_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:kirana_mobile/features/products/domain/models/product_model.dart';
import '../../domain/models/adjustment_reason.dart';
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
  final _quantityController = TextEditingController(text: '1');
  final _noteController = TextEditingController();
  AdjustmentReason _selectedReason = AdjustmentReason.physicalCountCorrection;
  String? _errorMessage;

  @override
  void dispose() {
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _incrementQty() {
    final current = double.tryParse(_quantityController.text.trim()) ?? 0.0;
    setState(() {
      _quantityController.text = (current + 1.0).toStringAsFixed(
        widget.product.isLoose ? 2 : 0,
      );
      _errorMessage = null;
    });
  }

  void _decrementQty() {
    final current = double.tryParse(_quantityController.text.trim()) ?? 0.0;
    if (current > 1.0) {
      setState(() {
        _quantityController.text = (current - 1.0).toStringAsFixed(
          widget.product.isLoose ? 2 : 0,
        );
        _errorMessage = null;
      });
    }
  }

  double _getCalculatedNewStock(double qty) {
    final currentStock = widget.product.currentStock;
    if (_selectedType == InventoryAdjustmentType.stockIn) {
      return currentStock + qty;
    } else if (_selectedType == InventoryAdjustmentType.stockOut) {
      return currentStock - qty;
    }
    return qty;
  }

  Future<void> _handleConfirmSubmit() async {
    final qtyText = _quantityController.text.trim();
    final qty = double.tryParse(qtyText);

    if (qty == null || qty <= 0) {
      setState(() {
        _errorMessage = 'Please enter a valid quantity greater than 0';
      });
      return;
    }

    final newStock = _getCalculatedNewStock(qty);
    if (_selectedType == InventoryAdjustmentType.stockOut && newStock < 0) {
      setState(() {
        _errorMessage =
            'Stock decrease cannot exceed current stock (${widget.product.currentStock} ${widget.product.unit}). New stock cannot be negative.';
      });
      return;
    }

    if (_selectedReason == AdjustmentReason.other) {
      final noteText = _noteController.text.trim();
      if (noteText.isEmpty) {
        setState(() {
          _errorMessage =
              'Short explanation is required when selecting "Other" as the reason.';
        });
        return;
      }
    }

    // Show Confirmation Modal before applying
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(
          borderRadius: KiranaRadius.borderLg,
        ),
        title: const Text('Confirm Stock Adjustment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Product: ${widget.product.name}'),
            const SizedBox(height: 4),
            Text('Adjustment Type: ${_selectedType.label}'),
            Text(
                'Adjustment Quantity: ${_selectedType == InventoryAdjustmentType.stockOut ? "-" : "+"}$qty ${widget.product.unit}'),
            const Divider(height: 16),
            Text(
              'Current Stock: ${widget.product.currentStock} ${widget.product.unit}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'New Calculated Stock: $newStock ${widget.product.unit}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: newStock <= widget.product.minStockAlert
                    ? KiranaColors.warning
                    : KiranaColors.secondary,
              ),
            ),
            const SizedBox(height: 8),
            Text('Reason: ${_selectedReason.label}'),
            if (_noteController.text.trim().isNotEmpty)
              Text('Notes: ${_noteController.text.trim()}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: KiranaColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm & Apply'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final shopId = ref.read(activeShopIdProvider);
    final user = ref.read(authNotifierProvider).user;

    if (shopId.isEmpty) {
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
      shopId: shopId,
      adjustmentType: _selectedType,
      quantity: qty,
      reason: _selectedReason.label,
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
        SnackBar(
          content: Text(
            'Stock adjusted successfully! New stock: $newStock ${widget.product.unit}',
          ),
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

    final connectivityAsync = ref.watch(connectivityStatusStreamProvider);
    final isOffline =
        connectivityAsync.asData?.value == ConnectivityStatus.offline;

    final userRole = ref.watch(authNotifierProvider).user?.role ?? 'owner';
    final isCashier = userRole == 'cashier';

    final currentStock = widget.product.currentStock;
    final qty = double.tryParse(_quantityController.text.trim()) ?? 0.0;
    final newStock = _getCalculatedNewStock(qty);
    final isNegativeStock =
        _selectedType == InventoryAdjustmentType.stockOut && newStock < 0;

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

            // Header Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Adjust Stock',
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
            const SizedBox(height: KiranaSpacing.md),

            // Offline Banner Block
            if (isOffline) ...[
              Container(
                padding: const EdgeInsets.all(KiranaSpacing.md),
                decoration: BoxDecoration(
                  color: KiranaColors.warningContainer,
                  borderRadius: KiranaRadius.borderMd,
                  border: Border.all(color: KiranaColors.warning),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        color: KiranaColors.warning),
                    const SizedBox(width: KiranaSpacing.md),
                    Expanded(
                      child: Text(
                        'Internet connection required to adjust stock.',
                        style: KiranaTypography.bodySmall.copyWith(
                          color: KiranaColors.warning,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: KiranaSpacing.lg),
            ],

            // Cashier Permission Restriction Banner
            if (isCashier) ...[
              Container(
                padding: const EdgeInsets.all(KiranaSpacing.md),
                decoration: BoxDecoration(
                  color: KiranaColors.errorContainer,
                  borderRadius: KiranaRadius.borderMd,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_rounded, color: KiranaColors.error),
                    const SizedBox(width: KiranaSpacing.md),
                    Expanded(
                      child: Text(
                        'Cashier role restricted: Stock adjustments require Manager or Owner authorization.',
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

            // Stock Calculation Preview Card
            Container(
              padding: const EdgeInsets.all(KiranaSpacing.md),
              decoration: BoxDecoration(
                color: KiranaColors.surfaceVariant.withValues(alpha: 0.6),
                borderRadius: KiranaRadius.borderMd,
                border: Border.all(
                  color: isNegativeStock
                      ? KiranaColors.error
                      : KiranaColors.outline,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        'Current Stock',
                        style: KiranaTypography.labelSmall.copyWith(
                          color: KiranaColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$currentStock ${widget.product.unit}',
                        style: KiranaTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    _selectedType == InventoryAdjustmentType.stockIn
                        ? Icons.add_circle_outline
                        : Icons.remove_circle_outline,
                    color: _selectedType == InventoryAdjustmentType.stockIn
                        ? KiranaColors.secondary
                        : KiranaColors.error,
                  ),
                  Column(
                    children: [
                      Text(
                        'Adjustment',
                        style: KiranaTypography.labelSmall.copyWith(
                          color: KiranaColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_selectedType == InventoryAdjustmentType.stockOut ? "-" : "+"}$qty ${widget.product.unit}',
                        style: KiranaTypography.titleMedium.copyWith(
                          color:
                              _selectedType == InventoryAdjustmentType.stockIn
                                  ? KiranaColors.secondary
                                  : KiranaColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.arrow_forward_rounded,
                      color: KiranaColors.neutral500),
                  Column(
                    children: [
                      Text(
                        'New Stock',
                        style: KiranaTypography.labelSmall.copyWith(
                          color: KiranaColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$newStock ${widget.product.unit}',
                        style: KiranaTypography.titleMedium.copyWith(
                          color: isNegativeStock
                              ? KiranaColors.error
                              : KiranaColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: KiranaSpacing.lg),

            // Increase / Decrease Adjustment Type Selector
            Row(
              children: [
                Expanded(
                  child: _TabButton(
                    label: '+ INCREASE',
                    isSelected:
                        _selectedType == InventoryAdjustmentType.stockIn,
                    activeColor: KiranaColors.secondary,
                    onTap: isCashier || isOffline
                        ? null
                        : () => setState(() {
                              _selectedType = InventoryAdjustmentType.stockIn;
                              _errorMessage = null;
                            }),
                  ),
                ),
                const SizedBox(width: KiranaSpacing.xs),
                Expanded(
                  child: _TabButton(
                    label: '- DECREASE',
                    isSelected:
                        _selectedType == InventoryAdjustmentType.stockOut,
                    activeColor: KiranaColors.error,
                    onTap: isCashier || isOffline
                        ? null
                        : () => setState(() {
                              _selectedType = InventoryAdjustmentType.stockOut;
                              _errorMessage = null;
                            }),
                  ),
                ),
                const SizedBox(width: KiranaSpacing.xs),
                Expanded(
                  child: _TabButton(
                    label: '= SET STOCK',
                    isSelected:
                        _selectedType == InventoryAdjustmentType.adjustment,
                    activeColor: KiranaColors.primary,
                    onTap: isCashier || isOffline
                        ? null
                        : () => setState(() {
                              _selectedType =
                                  InventoryAdjustmentType.adjustment;
                              _errorMessage = null;
                            }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: KiranaSpacing.lg),

            // Quantity Stepper + Input Field
            Text(
              'Adjustment Quantity (${widget.product.unit})',
              style: KiranaTypography.labelLarge.copyWith(
                color: KiranaColors.textSecondary,
              ),
            ),
            const SizedBox(height: KiranaSpacing.xs),
            Row(
              children: [
                IconButton.outlined(
                  icon: const Icon(Icons.remove),
                  onPressed: isCashier || isOffline || isLoading
                      ? null
                      : _decrementQty,
                ),
                const SizedBox(width: KiranaSpacing.xs),
                Expanded(
                  child: AppTextField(
                    hint: 'e.g. 10',
                    controller: _quantityController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    readOnly: isCashier || isOffline || isLoading,
                    onChanged: (_) => setState(() => _errorMessage = null),
                  ),
                ),
                const SizedBox(width: KiranaSpacing.xs),
                IconButton.outlined(
                  icon: const Icon(Icons.add),
                  onPressed: isCashier || isOffline || isLoading
                      ? null
                      : _incrementQty,
                ),
              ],
            ),
            const SizedBox(height: KiranaSpacing.lg),

            // Reason Selector
            Text(
              'Predefined Reason',
              style: KiranaTypography.labelLarge.copyWith(
                color: KiranaColors.textSecondary,
              ),
            ),
            const SizedBox(height: KiranaSpacing.xs),
            DropdownButtonFormField<AdjustmentReason>(
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
              items: AdjustmentReason.values.map((reason) {
                return DropdownMenuItem<AdjustmentReason>(
                  value: reason,
                  child: Text(
                    reason.label,
                    style: KiranaTypography.bodyMedium,
                  ),
                );
              }).toList(),
              onChanged: isCashier || isOffline || isLoading
                  ? null
                  : (val) {
                      if (val != null) {
                        setState(() {
                          _selectedReason = val;
                          _errorMessage = null;
                        });
                      }
                    },
            ),
            const SizedBox(height: KiranaSpacing.lg),

            // Notes / Explanation Field (Required if "Other")
            AppTextField(
              label: _selectedReason == AdjustmentReason.other
                  ? 'Explanation / Notes (Required for "Other")'
                  : 'Notes / Reference (Optional)',
              hint: _selectedReason == AdjustmentReason.other
                  ? 'Provide a clear explanation for this stock change'
                  : 'e.g. Physical audit record #AUD-992',
              controller: _noteController,
              readOnly: isCashier || isOffline || isLoading,
              onChanged: (_) => setState(() => _errorMessage = null),
            ),
            const SizedBox(height: KiranaSpacing.lg),

            // Error Display
            if (_errorMessage != null || adjustmentState.hasError) ...[
              Container(
                padding: const EdgeInsets.all(KiranaSpacing.sm),
                decoration: BoxDecoration(
                  color: KiranaColors.errorContainer,
                  borderRadius: KiranaRadius.borderSm,
                ),
                child: Text(
                  _errorMessage ??
                      adjustmentState.error
                          .toString()
                          .replaceAll('Exception: ', ''),
                  style: KiranaTypography.bodySmall.copyWith(
                    color: KiranaColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: KiranaSpacing.md),
            ],

            // Action Confirm Button
            AppButton(
              label: 'Confirm Adjustment',
              icon: Icons.check_circle_outline_rounded,
              isLoading: isLoading,
              onPressed: isCashier || isOffline || isLoading || isNegativeStock
                  ? null
                  : _handleConfirmSubmit,
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
