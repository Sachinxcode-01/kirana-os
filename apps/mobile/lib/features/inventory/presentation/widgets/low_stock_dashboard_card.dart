import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/radius.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../providers/low_stock_provider.dart';

class LowStockDashboardCard extends ConsumerWidget {
  final VoidCallback? onTap;

  const LowStockDashboardCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(lowStockNotifierProvider);

    final totalAlerts = state.lowStockCount + state.outOfStockCount;
    final hasAlerts = totalAlerts > 0;

    final cardBorderColor = state.outOfStockCount > 0
        ? KiranaColors.error
        : state.lowStockCount > 0
            ? KiranaColors.warning
            : KiranaColors.neutral200;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: KiranaRadius.borderMd,
        side: BorderSide(color: cardBorderColor, width: 1.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: KiranaRadius.borderMd,
        child: Padding(
          padding: const EdgeInsets.all(KiranaSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: hasAlerts
                            ? (state.outOfStockCount > 0
                                ? KiranaColors.error
                                : KiranaColors.warning)
                            : KiranaColors.success,
                        size: 22,
                      ),
                      const SizedBox(width: KiranaSpacing.xs),
                      Text(
                        'Stock Level Alerts',
                        style: KiranaTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (state.unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: KiranaColors.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${state.unreadCount} NEW',
                        style: KiranaTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: KiranaSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: KiranaSpacing.xs,
                          horizontal: KiranaSpacing.sm),
                      decoration: BoxDecoration(
                        color: KiranaColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LOW STOCK',
                            style: KiranaTypography.labelSmall.copyWith(
                              color: KiranaColors.warning,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            '${state.lowStockCount} products',
                            style: KiranaTypography.titleLarge.copyWith(
                              color: KiranaColors.warning,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: KiranaSpacing.xs),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: KiranaSpacing.xs,
                          horizontal: KiranaSpacing.sm),
                      decoration: BoxDecoration(
                        color: KiranaColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'OUT OF STOCK',
                            style: KiranaTypography.labelSmall.copyWith(
                              color: KiranaColors.error,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            '${state.outOfStockCount} products',
                            style: KiranaTypography.titleLarge.copyWith(
                              color: KiranaColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
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
