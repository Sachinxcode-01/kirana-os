import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kirana_mobile/core/theme/colors.dart';
import 'package:kirana_mobile/core/theme/radius.dart';
import 'package:kirana_mobile/core/theme/spacing.dart';
import 'package:kirana_mobile/core/theme/typography.dart';
import 'package:kirana_mobile/core/widgets/app_button.dart';
import 'package:kirana_mobile/core/widgets/app_text_field.dart';
import '../../domain/models/barcode_model.dart';
import '../../domain/utils/barcode_validator.dart';
import '../providers/barcode_provider.dart';

class ProductBarcodeSection extends ConsumerStatefulWidget {
  final String productId;

  const ProductBarcodeSection({
    super.key,
    required this.productId,
  });

  @override
  ConsumerState<ProductBarcodeSection> createState() =>
      _ProductBarcodeSectionState();
}

class _ProductBarcodeSectionState extends ConsumerState<ProductBarcodeSection> {
  void _showBarcodeDialog({BarcodeModel? barcodeItem}) {
    showDialog(
      context: context,
      builder: (dialogCtx) => _BarcodeFormDialog(
        productId: widget.productId,
        barcodeItem: barcodeItem,
      ),
    );
  }

  void _confirmDelete(BarcodeModel barcodeItem) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Remove Barcode'),
        content: Text(
            'Are you sure you want to remove barcode "${barcodeItem.barcode}"?'),
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
                  .read(barcodeNotifierProvider.notifier)
                  .removeBarcode(barcodeItem.id);

              if (mounted) {
                final state = ref.read(barcodeNotifierProvider);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.successMessage ?? 'Barcode removed'),
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
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final barcodesAsync =
        ref.watch(productBarcodesStreamProvider(widget.productId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.qr_code,
                    size: 20, color: KiranaColors.primary),
                const SizedBox(width: KiranaSpacing.xs),
                Text(
                  'Product Barcodes',
                  style: KiranaTypography.titleMedium
                      .copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () => _showBarcodeDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Barcode'),
            ),
          ],
        ),
        const SizedBox(height: KiranaSpacing.xs),
        barcodesAsync.when(
          data: (barcodes) {
            if (barcodes.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(KiranaSpacing.md),
                decoration: BoxDecoration(
                  color: KiranaColors.neutral100,
                  borderRadius: KiranaRadius.borderMd,
                  border: Border.all(color: KiranaColors.neutral200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.qr_code_2_outlined,
                        size: 24, color: KiranaColors.neutral500),
                    const SizedBox(width: KiranaSpacing.sm),
                    Expanded(
                      child: Text(
                        'No barcodes linked yet. Click "+ Add Barcode" to assign EAN-13, UPC, or custom barcodes.',
                        style: KiranaTypography.bodySmall
                            .copyWith(color: KiranaColors.neutral600),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: barcodes.map((item) {
                return Container(
                  margin: const EdgeInsets.only(bottom: KiranaSpacing.xs),
                  padding: const EdgeInsets.symmetric(
                    horizontal: KiranaSpacing.md,
                    vertical: KiranaSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: KiranaRadius.borderMd,
                    border: Border.all(color: KiranaColors.neutral200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.qr_code,
                          size: 22, color: KiranaColors.neutral700),
                      const SizedBox(width: KiranaSpacing.md),

                      // Barcode value & type chip
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.barcode,
                              style: KiranaTypography.priceTabular.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: KiranaColors.primaryContainer,
                                    borderRadius: KiranaRadius.borderPill,
                                  ),
                                  child: Text(
                                    item.barcodeType,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: KiranaColors.primary,
                                    ),
                                  ),
                                ),
                                if (item.isPrimary) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: KiranaColors.secondaryContainer,
                                      borderRadius: KiranaRadius.borderPill,
                                    ),
                                    child: const Text(
                                      'PRIMARY',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: KiranaColors.secondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Edit & Remove buttons
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () => _showBarcodeDialog(barcodeItem: item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 18, color: KiranaColors.error),
                        onPressed: () => _confirmDelete(item),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const Text('Failed to load barcodes'),
        ),
      ],
    );
  }
}

class _BarcodeFormDialog extends ConsumerStatefulWidget {
  final String productId;
  final BarcodeModel? barcodeItem;

  const _BarcodeFormDialog({
    required this.productId,
    this.barcodeItem,
  });

  @override
  ConsumerState<_BarcodeFormDialog> createState() => _BarcodeFormDialogState();
}

class _BarcodeFormDialogState extends ConsumerState<_BarcodeFormDialog> {
  final _barcodeController = TextEditingController();
  String _selectedType = 'EAN_13';
  String? _validationError;

  @override
  void initState() {
    super.initState();
    if (widget.barcodeItem != null) {
      _barcodeController.text = widget.barcodeItem!.barcode;
      _selectedType = widget.barcodeItem!.barcodeType;
    }
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    super.dispose();
  }

  void _onBarcodeChanged(String text) {
    if (text.trim().isNotEmpty) {
      final detected = BarcodeValidator.detectType(text);
      setState(() {
        _selectedType = detected.code;
        _validationError = null;
      });
    }
  }

  Future<void> _handleSubmit() async {
    final raw = _barcodeController.text.trim();
    final validation = BarcodeValidator.validate(raw);

    if (validation.isError) {
      setState(() => _validationError = validation.failureOrNull!.message);
      return;
    }

    setState(() => _validationError = null);

    bool success = false;
    if (widget.barcodeItem == null) {
      // Add
      success = await ref.read(barcodeNotifierProvider.notifier).addBarcode(
            productId: widget.productId,
            barcode: raw,
            barcodeType: _selectedType,
          );
    } else {
      // Update
      success = await ref.read(barcodeNotifierProvider.notifier).updateBarcode(
            id: widget.barcodeItem!.id,
            newBarcode: raw,
            barcodeType: _selectedType,
          );
    }

    if (success && mounted) {
      Navigator.pop(context);
      final state = ref.read(barcodeNotifierProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.successMessage ?? 'Barcode saved'),
          backgroundColor: KiranaColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(barcodeNotifierProvider);
    final isEditing = widget.barcodeItem != null;
    final errorMessage = _validationError ?? actionState.errorMessage;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Barcode' : 'Add Barcode'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
              label: 'Barcode String *',
              hint: 'e.g. 8901030383742',
              controller: _barcodeController,
              prefixIcon: const Icon(Icons.qr_code),
              onChanged: _onBarcodeChanged,
            ),
            const SizedBox(height: KiranaSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Format / Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                    value: 'EAN_13', child: Text('EAN-13 (Standard Retail)')),
                DropdownMenuItem(value: 'EAN_8', child: Text('EAN-8')),
                DropdownMenuItem(value: 'UPC_A', child: Text('UPC-A')),
                DropdownMenuItem(value: 'UPC_E', child: Text('UPC-E')),
                DropdownMenuItem(value: 'CODE_128', child: Text('Code 128')),
                DropdownMenuItem(value: 'CODE_39', child: Text('Code 39')),
                DropdownMenuItem(value: 'QR_CODE', child: Text('QR Code')),
                DropdownMenuItem(
                    value: 'CUSTOM', child: Text('Custom Barcode')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedType = val);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        AppButton(
          label: isEditing ? 'Save' : 'Add',
          isLoading: actionState.isLoading,
          onPressed: actionState.isLoading ? null : _handleSubmit,
        ),
      ],
    );
  }
}
