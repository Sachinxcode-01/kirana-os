import 'package:flutter/material.dart';
import '../../../../core/extensions/num_extensions.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../../products/domain/models/product_model.dart';
import '../../domain/models/stock_overview_model.dart';

class StockDetailsModal extends StatelessWidget {
  final ProductModel product;

  const StockDetailsModal({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final status = product.stockStatus;

    Color badgeColor;
    Color containerColor;
    IconData statusIcon;

    switch (status) {
      case StockStatus.inStock:
        badgeColor = KiranaColors.success;
        containerColor = KiranaColors.success.withValues(alpha: 0.15);
        statusIcon = Icons.check_circle_outline;
      case StockStatus.lowStock:
        badgeColor = KiranaColors.warning;
        containerColor = KiranaColors.warning.withValues(alpha: 0.15);
        statusIcon = Icons.warning_amber_rounded;
      case StockStatus.outOfStock:
        badgeColor = KiranaColors.error;
        containerColor = KiranaColors.error.withValues(alpha: 0.15);
        statusIcon = Icons.error_outline;
    }

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
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: KiranaColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: KiranaSpacing.sm),

          // Product Name & Close Button
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: KiranaTypography.headlineMedium),
                    if (product.brand != null || product.categoryName != null)
                      Text(
                        '${product.brand ?? ""} ${product.categoryName != null ? "• ${product.categoryName}" : ""}',
                        style: KiranaTypography.bodySmall,
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: KiranaSpacing.xs),

          // Status Badge Row
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: containerColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 16, color: badgeColor),
                    const SizedBox(width: 4),
                    Text(
                      status.label,
                      style: KiranaTypography.labelSmall.copyWith(
                        color: badgeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: KiranaSpacing.md),

          // Stock Overview Grid / Summary Card
          Card(
            color: KiranaColors.surfaceVariant.withValues(alpha: 0.5),
            child: Padding(
              padding: const EdgeInsets.all(KiranaSpacing.md),
              child: Column(
                children: [
                  _DetailRow(
                    label: 'Current Quantity:',
                    value: '${product.currentStock} ${product.unit}',
                    valueStyle: KiranaTypography.titleLarge.copyWith(
                      color: badgeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 16),
                  _DetailRow(
                    label: 'Min Stock Level:',
                    value: '${product.minStockAlert} ${product.unit}',
                  ),
                  if (product.maxStockAlert != null) ...[
                    const SizedBox(height: 6),
                    _DetailRow(
                      label: 'Max Stock Level:',
                      value: '${product.maxStockAlert} ${product.unit}',
                    ),
                  ],
                  const SizedBox(height: 6),
                  _DetailRow(
                    label: 'Selling Price:',
                    value: product.sellingPricePaise.toRupeesString(),
                    valueStyle: KiranaTypography.titleMedium.copyWith(
                      color: KiranaColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _DetailRow(
                    label: 'Last Purchase Price:',
                    value: product.purchasePricePaise > 0
                        ? product.purchasePricePaise.toRupeesString()
                        : 'N/A',
                  ),
                  if (product.mrpPaise > 0) ...[
                    const SizedBox(height: 6),
                    _DetailRow(
                      label: 'MRP:',
                      value: product.mrpPaise.toRupeesString(),
                    ),
                  ],
                  if (product.hsnCode != null) ...[
                    const SizedBox(height: 6),
                    _DetailRow(
                      label: 'HSN Code:',
                      value: product.hsnCode!,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: KiranaSpacing.md),

          // Stock Summary Health Banner
          Container(
            padding: const EdgeInsets.all(KiranaSpacing.sm),
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: badgeColor, size: 20),
                const SizedBox(width: KiranaSpacing.xs),
                Expanded(
                  child: Text(
                    status == StockStatus.outOfStock
                        ? 'Product is currently out of stock. Inward new purchase to replenish inventory.'
                        : status == StockStatus.lowStock
                            ? 'Stock level is below safety minimum threshold (${product.minStockAlert} ${product.unit}).'
                            : 'Stock inventory level is healthy.',
                    style: KiranaTypography.bodySmall.copyWith(
                        color: badgeColor, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: KiranaTypography.bodyMedium),
        Text(value, style: valueStyle ?? KiranaTypography.titleMedium),
      ],
    );
  }
}
