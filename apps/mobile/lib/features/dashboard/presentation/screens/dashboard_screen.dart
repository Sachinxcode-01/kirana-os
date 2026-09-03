import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kirana_mobile/app/app_providers.dart';
import 'package:kirana_mobile/core/extensions/context_extensions.dart';
import 'package:kirana_mobile/core/network/connectivity_status.dart';
import 'package:kirana_mobile/core/theme/colors.dart';
import 'package:kirana_mobile/core/theme/radius.dart';
import 'package:kirana_mobile/core/theme/spacing.dart';
import 'package:kirana_mobile/core/theme/typography.dart';
import 'package:kirana_mobile/core/utils/currency_formatter.dart';
import 'package:kirana_mobile/features/dashboard/domain/models/dashboard_metrics.dart';
import 'package:kirana_mobile/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:kirana_mobile/features/dashboard/presentation/widgets/dashboard_session_header.dart';
import 'package:kirana_mobile/features/dashboard/presentation/widgets/sales_trend_chart.dart';
import 'package:kirana_mobile/features/dashboard/presentation/widgets/top_products_card.dart';
import 'package:kirana_mobile/features/inventory/presentation/widgets/low_stock_dashboard_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(dashboardMetricsStreamProvider);
    final connectivity =
        ref.watch(connectivityStatusStreamProvider).valueOrNull ??
            ConnectivityStatus.online;
    final isOffline = connectivity == ConnectivityStatus.offline;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: const DashboardSessionHeader(),
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
      body: metricsAsync.when(
        data: (metrics) =>
            _buildDashboardContent(context, ref, metrics, isOffline),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: KiranaColors.error),
              const SizedBox(height: KiranaSpacing.md),
              const Text('Failed to load dashboard metrics',
                  style: KiranaTypography.titleMedium),
              const SizedBox(height: KiranaSpacing.lg),
              ElevatedButton.icon(
                onPressed: () => ref.refresh(dashboardMetricsStreamProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardContent(
    BuildContext context,
    WidgetRef ref,
    DashboardMetrics metrics,
    bool isOffline,
  ) {
    final showOffline = isOffline || metrics.isOffline;
    final lastSyncedTimeStr = metrics.lastSyncedAt != null
        ? '${metrics.lastSyncedAt!.hour.toString().padLeft(2, '0')}:${metrics.lastSyncedAt!.minute.toString().padLeft(2, '0')}'
        : 'Unknown';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(KiranaSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Offline Banner / Sync Status
          if (showOffline)
            Container(
              margin: const EdgeInsets.only(bottom: KiranaSpacing.md),
              padding: const EdgeInsets.symmetric(
                  horizontal: KiranaSpacing.md, vertical: KiranaSpacing.sm),
              decoration: BoxDecoration(
                color: KiranaColors.warningContainer,
                borderRadius: KiranaRadius.borderMd,
                border: Border.all(color: KiranaColors.warning),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off,
                      color: KiranaColors.onSecondaryContainer, size: 20),
                  const SizedBox(width: KiranaSpacing.sm),
                  Expanded(
                    child: Text(
                      'OFFLINE • Last updated: $lastSyncedTimeStr',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: KiranaColors.onSecondaryContainer,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.refresh(dashboardMetricsStreamProvider),
                    child: const Text('Sync Now'),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.1, end: 0),

          // Quick Barcode POS Hero Banner with Vibrant Gradient & Glow
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  KiranaColors.primaryDark,
                  KiranaColors.primary,
                  Color(0xFF0D9488),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: KiranaRadius.borderLg,
              boxShadow: [
                BoxShadow(
                  color: KiranaColors.primary.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push('/billing'),
                borderRadius: KiranaRadius.borderLg,
                child: Padding(
                  padding: const EdgeInsets.all(KiranaSpacing.xl),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(KiranaSpacing.md),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: KiranaRadius.borderMd,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: KiranaSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quick Barcode POS',
                              style: KiranaTypography.headlineMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: KiranaSpacing.xxs),
                            Text(
                              'Sub-15ms barcode scan & dynamic UPI QR billing',
                              style: KiranaTypography.bodyMedium.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: KiranaSpacing.sm),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: KiranaColors.primaryDark,
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: const RoundedRectangleBorder(
                            borderRadius: KiranaRadius.borderMd,
                          ),
                        ),
                        onPressed: () => context.push('/billing'),
                        icon: const Icon(Icons.point_of_sale, size: 18),
                        label: const Text(
                          'OPEN POS',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(duration: 250.ms).scale(begin: const Offset(0.98, 0.98)),
          const SizedBox(height: KiranaSpacing.xl),

          // Staggered KPI Grid
          GridView.count(
            crossAxisCount: context.isWideScreen ? 4 : 2,
            childAspectRatio: 1.25,
            crossAxisSpacing: KiranaSpacing.md,
            mainAxisSpacing: KiranaSpacing.md,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _KpiCard(
                title: "Today's Sales",
                value: CurrencyFormatter.formatPaise(
                    metrics.todaySalesPaise.toInt()),
                subtitle: 'Completed sales',
                icon: Icons.currency_rupee,
                color: KiranaColors.primary,
              ).animate().fadeIn(duration: 240.ms, delay: 50.ms).slideY(begin: 0.08, end: 0),
              _KpiCard(
                title: "Bills Today",
                value: '${metrics.todayBillsCount}',
                subtitle: metrics.yesterdayBillsCount != null
                    ? 'Yesterday: ${metrics.yesterdayBillsCount}'
                    : null,
                icon: Icons.receipt_long,
                color: KiranaColors.primaryLight,
              ).animate().fadeIn(duration: 240.ms, delay: 100.ms).slideY(begin: 0.08, end: 0),
              _KpiCard(
                title: "Udhaar Outstanding",
                value: CurrencyFormatter.formatPaise(
                    metrics.totalUdhaarOutstandingPaise.toInt()),
                icon: Icons.account_balance_wallet,
                color: KiranaColors.secondary,
                onTap: () => context.push('/credit'),
              ).animate().fadeIn(duration: 240.ms, delay: 150.ms).slideY(begin: 0.08, end: 0),
              _KpiCard(
                title: "Low Stock Items",
                value: '${metrics.lowStockItemsCount} Items',
                icon: Icons.warning_amber_rounded,
                color: metrics.lowStockItemsCount > 0
                    ? KiranaColors.error
                    : KiranaColors.neutral500,
                onTap: () => context.push('/inventory/low-stock'),
              ).animate().fadeIn(duration: 240.ms, delay: 200.ms).slideY(begin: 0.08, end: 0),
            ],
          ),
          const SizedBox(height: KiranaSpacing.lg),

          // Today's Top Products Card
          TopProductsCard(topProducts: metrics.topProducts)
              .animate()
              .fadeIn(duration: 260.ms, delay: 220.ms),
          const SizedBox(height: KiranaSpacing.lg),

          // Basic Sales Trend Chart
          SalesTrendChart(salesTrend: metrics.salesTrend)
              .animate()
              .fadeIn(duration: 260.ms, delay: 260.ms),
          const SizedBox(height: KiranaSpacing.lg),

          // Low Stock Dashboard Card
          LowStockDashboardCard(
            onTap: () => context.push('/inventory/low-stock'),
          ).animate().fadeIn(duration: 260.ms, delay: 300.ms),
          const SizedBox(height: KiranaSpacing.xl),

          // Quick Operations Ribbon
          Text(
            'Quick Operations',
            style: KiranaTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: KiranaColors.neutral900,
            ),
          ),
          const SizedBox(height: KiranaSpacing.md),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.qr_code_scanner,
                  title: 'Scan Barcode',
                  onTap: () => context.push('/barcode'),
                ),
              ),
              const SizedBox(width: KiranaSpacing.md),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.add_shopping_cart,
                  title: 'Add Product',
                  onTap: () => context.push('/products'),
                ),
              ),
              const SizedBox(width: KiranaSpacing.md),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.person_add_alt,
                  title: 'Add Customer',
                  onTap: () => context.push('/customers'),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 260.ms, delay: 340.ms).slideY(begin: 0.05, end: 0),
          const SizedBox(height: KiranaSpacing.xxl),

          // Recent Invoices Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Invoices',
                style: KiranaTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: KiranaColors.neutral900,
                ),
              ),
              if (metrics.recentBills.isNotEmpty)
                TextButton(
                  onPressed: () => context.push('/invoices'),
                  child: const Text('View All'),
                ),
            ],
          ),
          const SizedBox(height: KiranaSpacing.sm),

          if (metrics.recentBills.isEmpty)
            Container(
              padding: const EdgeInsets.all(KiranaSpacing.xl),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: KiranaRadius.borderLg,
                border: Border.all(color: KiranaColors.neutral200),
              ),
              child: Column(
                children: [
                  const Icon(Icons.receipt_long_outlined,
                      size: 40, color: KiranaColors.neutral400),
                  const SizedBox(height: KiranaSpacing.sm),
                  Text(
                    'No bills created yet today',
                    style: KiranaTypography.bodyMedium
                        .copyWith(color: KiranaColors.neutral600),
                  ),
                  const SizedBox(height: KiranaSpacing.xs),
                  const Text(
                    'Start your first sale with Quick Barcode POS above.',
                    style:
                        TextStyle(fontSize: 12, color: KiranaColors.neutral500),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: metrics.recentBills.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: KiranaSpacing.xs),
              itemBuilder: (context, index) {
                final bill = metrics.recentBills[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: KiranaSpacing.md,
                      vertical: KiranaSpacing.xs,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: KiranaColors.primaryContainer,
                      child: const Icon(
                        Icons.receipt_long,
                        color: KiranaColors.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      bill.billNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      '${bill.createdAt.hour.toString().padLeft(2, '0')}:${bill.createdAt.minute.toString().padLeft(2, '0')} • ${bill.paymentStatus.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: KiranaColors.neutral600,
                      ),
                    ),
                    trailing: Text(
                      CurrencyFormatter.formatPaise(bill.totalPaise.toInt()),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: KiranaColors.neutral900,
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 200.ms, delay: Duration(milliseconds: 360 + index * 40));
              },
            ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _KpiCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: KiranaRadius.borderLg,
        side: BorderSide(
          color: KiranaColors.outlineVariant.withValues(alpha: 0.8),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: KiranaRadius.borderLg,
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
                      style: KiranaTypography.labelSmall.copyWith(
                        color: KiranaColors.neutral600,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 16, color: color),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: KiranaTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        color: KiranaColors.neutral900,
                      ),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 11,
                        color: KiranaColors.neutral500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: KiranaRadius.borderLg,
        side: BorderSide(
          color: KiranaColors.outlineVariant.withValues(alpha: 0.8),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: KiranaRadius.borderLg,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              vertical: KiranaSpacing.md, horizontal: KiranaSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: KiranaColors.primaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: KiranaColors.primaryDark, size: 22),
              ),
              const SizedBox(height: KiranaSpacing.xs),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: KiranaColors.neutral800,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
