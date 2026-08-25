import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/radius.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../../products/domain/models/product_model.dart';
import '../../domain/models/stock_status.dart';

class ProductStockCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onAdjustStockPressed;

  const ProductStockCard({
    super.key,
    required this.product,
    this.onAdjustStockPressed,
  });

  @override
  Widget build(BuildContext context) {
    final status = StockStatus.fromQuantities(
      product.currentStock,
      product.minStockAlert,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: KiranaRadius.borderLg,
        border: Border.all(color: KiranaColors.neutral200),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(KiranaSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Stock Information',
                style: KiranaTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: KiranaColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: KiranaSpacing.md,
                  vertical: KiranaSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: status.containerColor,
                  borderRadius: KiranaRadius.borderSm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(status.icon, size: 14, color: status.badgeColor),
                    const SizedBox(width: KiranaSpacing.xs),
                    Text(
                      status.label,
                      style: KiranaTypography.labelSmall.copyWith(
                        color: status.badgeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: KiranaSpacing.md),
          Row(
            children: [
              Expanded(
                child: _StockInfoTile(
                  label: 'Current Stock',
                  value:
                      '${product.currentStock % 1 == 0 ? product.currentStock.toInt() : product.currentStock}',
                  unit: product.unit,
                  valueColor: status.badgeColor,
                ),
              ),
              Container(
                height: 36,
                width: 1,
                color: KiranaColors.neutral200,
              ),
              Expanded(
                child: _StockInfoTile(
                  label: 'Minimum Stock',
                  value:
                      '${product.minStockAlert % 1 == 0 ? product.minStockAlert.toInt() : product.minStockAlert}',
                  unit: product.unit,
                  valueColor: KiranaColors.textSecondary,
                ),
              ),
            ],
          ),
          if (onAdjustStockPressed != null) ...[
            const SizedBox(height: KiranaSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: KiranaColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: KiranaSpacing.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: KiranaRadius.borderMd,
                  ),
                ),
                onPressed: onAdjustStockPressed,
                icon: const Icon(Icons.edit_note, size: 20),
                label: const Text(
                  'Adjust Stock',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StockInfoTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color valueColor;

  const _StockInfoTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: KiranaTypography.bodySmall.copyWith(
            color: KiranaColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                value,
                key: ValueKey(value),
                style: KiranaTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              unit,
              style: KiranaTypography.bodySmall.copyWith(
                color: KiranaColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
