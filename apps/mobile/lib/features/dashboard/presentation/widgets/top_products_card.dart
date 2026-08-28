import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/radius.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../domain/models/dashboard_metrics.dart';

class TopProductsCard extends StatelessWidget {
  final List<TopProductItem> topProducts;

  const TopProductsCard({
    super.key,
    required this.topProducts,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(KiranaSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: KiranaColors.secondary, size: 20),
                const SizedBox(width: KiranaSpacing.xs),
                Text(
                  "Today's Top Products",
                  style: KiranaTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: KiranaSpacing.md),
            if (topProducts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: KiranaSpacing.md),
                child: Center(
                  child: Text(
                    'No items sold today yet',
                    style: KiranaTypography.bodyMedium.copyWith(
                      color: KiranaColors.neutral500,
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: topProducts.length,
                separatorBuilder: (context, index) => const Divider(
                  height: 16,
                  color: KiranaColors.neutral200,
                ),
                itemBuilder: (context, index) {
                  final item = topProducts[index];
                  final rank = index + 1;
                  final qtyString = item.quantitySold % 1 == 0
                      ? item.quantitySold.toInt().toString()
                      : item.quantitySold.toStringAsFixed(2);

                  return Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: rank == 1
                              ? KiranaColors.primary.withValues(alpha: 0.15)
                              : KiranaColors.neutral100,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$rank',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: rank == 1
                                ? KiranaColors.primary
                                : KiranaColors.neutral700,
                          ),
                        ),
                      ),
                      const SizedBox(width: KiranaSpacing.md),
                      Expanded(
                        child: Text(
                          item.productName,
                          style: KiranaTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: KiranaColors.primaryContainer,
                          borderRadius: KiranaRadius.borderSm,
                        ),
                        child: Text(
                          '$qtyString sold',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: KiranaColors.primary,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
