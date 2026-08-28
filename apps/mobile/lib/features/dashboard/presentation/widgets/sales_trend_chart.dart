import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/radius.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/dashboard_metrics.dart';

class SalesTrendChart extends StatelessWidget {
  final List<SalesTrendItem> salesTrend;

  const SalesTrendChart({
    super.key,
    required this.salesTrend,
  });

  @override
  Widget build(BuildContext context) {
    BigInt maxPaise = BigInt.zero;
    for (final item in salesTrend) {
      if (item.totalPaise > maxPaise) {
        maxPaise = item.totalPaise;
      }
    }
    final double maxVal = maxPaise.toInt().toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(KiranaSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.show_chart,
                        color: KiranaColors.primary, size: 20),
                    const SizedBox(width: KiranaSpacing.xs),
                    Text(
                      'Sales Trend (Recent Days)',
                      style: KiranaTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (maxPaise > BigInt.zero)
                  Text(
                    'Peak: ${CurrencyFormatter.formatPaise(maxPaise.toInt())}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: KiranaColors.neutral600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: KiranaSpacing.lg),
            if (salesTrend.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: KiranaSpacing.md),
                child: Center(
                  child: Text(
                    'No trend data available',
                    style: KiranaTypography.bodyMedium
                        .copyWith(color: KiranaColors.neutral500),
                  ),
                ),
              )
            else
              SizedBox(
                height: 140,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: salesTrend.map((item) {
                    final double val = item.totalPaise.toInt().toDouble();
                    final double heightRatio =
                        maxVal > 0 ? (val / maxVal) : 0.0;
                    final bool isTodayRatio = item == salesTrend.last;

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (val > 0)
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  CurrencyFormatter.formatPaise(val.toInt()),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isTodayRatio
                                        ? KiranaColors.primary
                                        : KiranaColors.neutral600,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 4),
                            Expanded(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                  height: (heightRatio * 85).clamp(6.0, 85.0),
                                  decoration: BoxDecoration(
                                    color: isTodayRatio
                                        ? KiranaColors.primary
                                        : KiranaColors.primary
                                            .withValues(alpha: 0.35),
                                    borderRadius: KiranaRadius.borderSm,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.dayLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isTodayRatio
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isTodayRatio
                                    ? KiranaColors.primary
                                    : KiranaColors.neutral700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
