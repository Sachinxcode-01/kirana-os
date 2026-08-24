import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kirana_mobile/core/extensions/context_extensions.dart';
import 'package:kirana_mobile/core/extensions/num_extensions.dart';
import 'package:kirana_mobile/core/theme/colors.dart';
import 'package:kirana_mobile/core/theme/radius.dart';
import 'package:kirana_mobile/core/theme/spacing.dart';
import 'package:kirana_mobile/core/theme/typography.dart';

// --- DOMAIN / STATE ---
class DashboardMetrics {
  final int todaySalesPaise;
  final int todayBillsCount;
  final int totalUdhaarOutstandingPaise;
  final int lowStockItemsCount;

  const DashboardMetrics({
    required this.todaySalesPaise,
    required this.todayBillsCount,
    required this.totalUdhaarOutstandingPaise,
    required this.lowStockItemsCount,
  });
}

final dashboardMetricsProvider = Provider<DashboardMetrics>((ref) {
  return const DashboardMetrics(
    todaySalesPaise: 1845000, // ₹18,450.00
    todayBillsCount: 42,
    totalUdhaarOutstandingPaise: 3850000, // ₹38,500.00
    lowStockItemsCount: 4,
  );
});

// --- PRESENTATION SCREEN ---
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(dashboardMetricsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('KiranaOS Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(KiranaSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Quick POS Call to Action
            Card(
              color: KiranaColors.primary,
              child: Padding(
                padding: const EdgeInsets.all(KiranaSpacing.xl),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quick Barcode POS',
                            style: KiranaTypography.headlineMedium.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: KiranaSpacing.xs),
                          Text(
                            'Scan items or create cash/UPI/credit bill',
                            style: KiranaTypography.bodyMedium.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: KiranaColors.primary,
                      ),
                      onPressed: () => context.push('/billing'),
                      icon: const Icon(Icons.point_of_sale),
                      label: const Text('OPEN POS'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: KiranaSpacing.xl),

            // KPI Grid
            GridView.count(
              crossAxisCount: context.isWideScreen ? 4 : 2,
              childAspectRatio: 1.3,
              crossAxisSpacing: KiranaSpacing.md,
              mainAxisSpacing: KiranaSpacing.md,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _KpiCard(
                  title: "Today's Sales",
                  value: metrics.todaySalesPaise.toRupeesString(),
                  icon: Icons.currency_rupee,
                  color: KiranaColors.primary,
                ),
                _KpiCard(
                  title: "Bills Generated",
                  value: metrics.todayBillsCount.toString(),
                  icon: Icons.receipt_long,
                  color: KiranaColors.primaryLight,
                ),
                _KpiCard(
                  title: "Udhaar Due",
                  value: metrics.totalUdhaarOutstandingPaise.toRupeesString(),
                  icon: Icons.account_balance_wallet,
                  color: KiranaColors.secondary,
                  onTap: () => context.push('/credit'),
                ),
                _KpiCard(
                  title: "Low Stock Items",
                  value: metrics.lowStockItemsCount.toString(),
                  icon: Icons.warning_amber,
                  color: KiranaColors.error,
                  onTap: () => context.push('/inventory'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: KiranaRadius.borderMd,
        child: Padding(
          padding: const EdgeInsets.all(KiranaSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: KiranaTypography.labelSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(icon, size: 18, color: color),
                ],
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: KiranaTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
