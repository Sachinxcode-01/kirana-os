import 'package:flutter/material.dart';
import 'package:kirana_mobile/core/extensions/num_extensions.dart';
import 'package:kirana_mobile/core/theme/colors.dart';
import 'package:kirana_mobile/core/theme/radius.dart';
import 'package:kirana_mobile/core/theme/spacing.dart';
import 'package:kirana_mobile/core/theme/typography.dart';
import 'package:kirana_mobile/core/widgets/app_button.dart';
import 'package:kirana_mobile/features/products/domain/models/product_model.dart';

class ScanResultSheet extends StatelessWidget {
  final String barcode;
  final ProductModel? product;
  final bool isOffline;
  final VoidCallback onScanAgain;
  final VoidCallback? onAddToCart;
  final VoidCallback? onViewProduct;
  final VoidCallback? onAddProduct;

  const ScanResultSheet({
    super.key,
    required this.barcode,
    this.product,
    this.isOffline = false,
    required this.onScanAgain,
    this.onAddToCart,
    this.onViewProduct,
    this.onAddProduct,
  });

  @override
  Widget build(BuildContext context) {
    final hasProduct = product != null;

    return Container(
      padding: EdgeInsets.only(
        left: KiranaSpacing.xl,
        right: KiranaSpacing.xl,
        top: KiranaSpacing.xl,
        bottom: MediaQuery.of(context).padding.bottom + KiranaSpacing.xl,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Indicator & Barcode Chip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    hasProduct
                        ? Icons.check_circle_outline
                        : Icons.help_outline,
                    color: hasProduct
                        ? KiranaColors.success
                        : KiranaColors.warning,
                    size: 24,
                  ),
                  const SizedBox(width: KiranaSpacing.xs),
                  Text(
                    hasProduct ? 'Product Scanned' : 'Barcode Not Registered',
                    style: KiranaTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: KiranaColors.neutral100,
                  borderRadius: KiranaRadius.borderPill,
                  border: Border.all(color: KiranaColors.neutral300),
                ),
                child: Text(
                  barcode,
                  style: KiranaTypography.priceTabular.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: KiranaColors.neutral800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: KiranaSpacing.md),

          // Offline indicator banner if offline
          if (isOffline) ...[
            Container(
              padding: const EdgeInsets.all(KiranaSpacing.xs),
              decoration: const BoxDecoration(
                color: KiranaColors.primaryContainer,
                borderRadius: KiranaRadius.borderMd,
              ),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off,
                      size: 16, color: KiranaColors.primary),
                  const SizedBox(width: KiranaSpacing.xs),
                  Expanded(
                    child: Text(
                      hasProduct
                          ? 'Offline — product retrieved from saved local catalog.'
                          : 'Product unavailable offline.',
                      style: KiranaTypography.bodySmall.copyWith(
                        color: KiranaColors.neutral800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: KiranaSpacing.md),
          ],

          // Product Details Card OR Not Found Card
          if (hasProduct) ...[
            Container(
              padding: const EdgeInsets.all(KiranaSpacing.md),
              decoration: BoxDecoration(
                color: KiranaColors.surfaceVariant,
                borderRadius: KiranaRadius.borderMd,
                border: Border.all(color: KiranaColors.neutral200),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: KiranaColors.primaryContainer,
                    child: Text(
                      product!.name.isNotEmpty
                          ? product!.name[0].toUpperCase()
                          : 'P',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: KiranaColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: KiranaSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product!.name,
                          style: KiranaTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (product!.categoryName != null) ...[
                              Text(
                                product!.categoryName!,
                                style: KiranaTypography.bodySmall.copyWith(
                                  color: KiranaColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Text(' • ',
                                  style: TextStyle(
                                      color: KiranaColors.neutral400)),
                            ],
                            Text(
                              'Stock: ${product!.currentStock} ${product!.unit}',
                              style: KiranaTypography.bodySmall.copyWith(
                                color: product!.currentStock <=
                                        product!.minStockAlert
                                    ? KiranaColors.warning
                                    : KiranaColors.neutral600,
                                fontWeight: product!.currentStock <=
                                        product!.minStockAlert
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        product!.sellingPricePaise.toRupeesString(),
                        style: KiranaTypography.priceTabular.copyWith(
                          color: KiranaColors.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (product!.mrpPaise > product!.sellingPricePaise)
                        Text(
                          'MRP ${product!.mrpPaise.toRupeesString()}',
                          style: KiranaTypography.bodySmall.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: KiranaColors.neutral500,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(KiranaSpacing.lg),
              decoration: BoxDecoration(
                color: KiranaColors.warningContainer.withAlpha(50),
                borderRadius: KiranaRadius.borderMd,
                border: Border.all(color: KiranaColors.warning.withAlpha(100)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.qr_code_scanner,
                      size: 40, color: KiranaColors.warning),
                  const SizedBox(height: KiranaSpacing.xs),
                  Text(
                    'Barcode Not Registered',
                    style: KiranaTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: KiranaColors.neutral900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: KiranaSpacing.xs),
                  Text(
                    'Detected:\n$barcode',
                    style: KiranaTypography.priceTabular.copyWith(
                      color: KiranaColors.neutral800,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: KiranaSpacing.xs),
                  Text(
                    isOffline
                        ? 'Product unavailable offline.'
                        : 'Tap "Add Product" below to create a product with this barcode.',
                    style: KiranaTypography.bodySmall.copyWith(
                      color: KiranaColors.neutral600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: KiranaSpacing.xl),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onScanAgain,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Scan Again'),
                ),
              ),
              const SizedBox(width: KiranaSpacing.md),
              Expanded(
                child: hasProduct
                    ? AppButton(
                        label: 'Add to Cart',
                        icon: Icons.add_shopping_cart,
                        onPressed: onAddToCart ?? onViewProduct,
                      )
                    : AppButton(
                        label: '+ Add Product',
                        icon: Icons.add,
                        onPressed: onAddProduct,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
