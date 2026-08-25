import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kirana_mobile/core/theme/colors.dart';
import 'package:kirana_mobile/core/theme/radius.dart';
import 'package:kirana_mobile/core/theme/spacing.dart';
import 'package:kirana_mobile/core/theme/typography.dart';
import 'package:kirana_mobile/core/widgets/app_button.dart';
import 'package:kirana_mobile/core/widgets/app_text_field.dart';
import 'package:kirana_mobile/features/products/domain/models/product_model.dart';
import '../providers/inventory_provider.dart';

class InventorySettingsDialog extends ConsumerStatefulWidget {
  final ProductModel product;

  const InventorySettingsDialog({
    super.key,
    required this.product,
  });

  static Future<bool?> show(BuildContext context, ProductModel product) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InventorySettingsDialog(product: product),
    );
  }

  @override
  ConsumerState<InventorySettingsDialog> createState() =>
      _InventorySettingsDialogState();
}

class _InventorySettingsDialogState
    extends ConsumerState<InventorySettingsDialog> {
  final _minStockController = TextEditingController();
  final _maxStockController = TextEditingController();
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _minStockController.text = widget.product.minStockAlert % 1 == 0
        ? widget.product.minStockAlert.toInt().toString()
        : widget.product.minStockAlert.toString();

    if (widget.product.maxStockAlert != null) {
      _maxStockController.text = widget.product.maxStockAlert! % 1 == 0
          ? widget.product.maxStockAlert!.toInt().toString()
          : widget.product.maxStockAlert!.toString();
    }
  }

  @override
  void dispose() {
    _minStockController.dispose();
    _maxStockController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final minText = _minStockController.text.trim();
    final maxText = _maxStockController.text.trim();

    final minVal = double.tryParse(minText);
    if (minVal == null || minVal < 0) {
      setState(() {
        _validationError = 'Minimum stock level must be a non-negative number.';
      });
      return;
    }

    double? maxVal;
    if (maxText.isNotEmpty) {
      maxVal = double.tryParse(maxText);
      if (maxVal == null || maxVal < 0) {
        setState(() {
          _validationError =
              'Maximum stock level must be a non-negative number.';
        });
        return;
      }
      if (maxVal < minVal) {
        setState(() {
          _validationError =
              'Maximum stock level must be greater than or equal to minimum stock ($minVal).';
        });
        return;
      }
    }

    setState(() => _validationError = null);

    final success = await ref
        .read(inventorySettingsNotifierProvider.notifier)
        .updateStockSettings(
          productId: widget.product.id,
          minStockAlert: minVal,
          maxStockAlert: maxVal,
        );

    if (mounted) {
      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inventory stock thresholds updated successfully'),
            backgroundColor: KiranaColors.success,
          ),
        );
      } else {
        final state = ref.read(inventorySettingsNotifierProvider);
        if (state is AsyncError) {
          setState(() {
            _validationError =
                state.error.toString().replaceAll('Exception: ', '');
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(inventorySettingsNotifierProvider);
    final isLoading = actionState.isLoading;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.all(KiranaSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Inventory Settings',
                      style: KiranaTypography.titleLarge,
                    ),
                    Text(
                      widget.product.name,
                      style: KiranaTypography.bodyMedium.copyWith(
                        color: KiranaColors.neutral600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: KiranaSpacing.md),

            // Validation Error Box
            if (_validationError != null) ...[
              Container(
                width: double.infinity,
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
                        _validationError!,
                        style: const TextStyle(
                          color: KiranaColors.error,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: KiranaSpacing.md),
            ],

            // Current Stock & Unit Banner
            Container(
              padding: const EdgeInsets.all(KiranaSpacing.sm),
              decoration: BoxDecoration(
                color: KiranaColors.neutral100,
                borderRadius: KiranaRadius.borderMd,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Unit: ${widget.product.unit}',
                    style: KiranaTypography.bodyMedium
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Current Stock: ${widget.product.currentStock % 1 == 0 ? widget.product.currentStock.toInt() : widget.product.currentStock} ${widget.product.unit}',
                    style: KiranaTypography.bodyMedium.copyWith(
                      color: KiranaColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: KiranaSpacing.md),

            // Minimum Stock Field
            AppTextField(
              label: 'Minimum Safety Stock',
              hint: 'e.g. 5',
              controller: _minStockController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              prefixIcon: const Icon(Icons.warning_amber_rounded),
            ),
            const SizedBox(height: KiranaSpacing.md),

            // Optional Maximum Stock Field
            AppTextField(
              label: 'Maximum Stock Target (Optional)',
              hint: 'e.g. 50 (leave empty if none)',
              controller: _maxStockController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              prefixIcon: const Icon(Icons.inventory),
            ),
            const SizedBox(height: KiranaSpacing.xl),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: KiranaSpacing.md),
                Expanded(
                  child: AppButton(
                    label: 'Save Settings',
                    isLoading: isLoading,
                    onPressed: _handleSave,
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
