import 'package:flutter/material.dart';
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
import 'package:kirana_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:kirana_mobile/features/dashboard/domain/models/dashboard_metrics.dart';
import 'package:kirana_mobile/features/dashboard/presentation/providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(dashboardMetricsStreamProvider);
    final authState = ref.watch(authNotifierProvider);
    final pendingSyncCount = ref.watch(pendingSyncCountProvider).valueOrNull ?? 0;
    final connectivity =
        ref.watch(connectivityStatusStreamProvider).valueOrNull ??
            ConnectivityStatus.online;
    final isOffline = connectivity == ConnectivityStatus.offline;

    final storeName = authState.activeShopName ?? 'Kirana Store';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(storeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isOffline ? KiranaColors.error : KiranaColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  isOffline
                      ? 'Offline (Billing Available)'
                      : (pendingSyncCount > 0
                          ? '$pendingSyncCount sync pending'
                          : 'Cloud Synced'),
                  style: const TextStyle(fontSize: 11, color: KiranaColors.neutral600),
                ),
              ],
            ),
          ],
        ),
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
        data: (metrics) => _buildDashboardContent(context, metrics, isOffline),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: KiranaColors.error),
              const SizedBox(height: KiranaSpacing.md),
              const Text('Failed to load dashboard metrics', style: KiranaTypography.titleMedium),
              const SizedBox(height: KiranaSpacing.lg),
              ElevatedButton(
                onPressed: () => ref.refresh(dashboardMetricsStreamProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardContent(
    BuildContext context,
    DashboardMetrics metrics,
    bool isOffline,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(KiranaSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Quick Barcode POS CTA
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
                          'Sub-15ms barcode scan & dynamic UPI QR billing',
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: () => context.push('/billing'),
                    icon: const Icon(Icons.point_of_sale),
                    label: const Text('OPEN POS', style: TextStyle(fontWeight: FontWeight.bold)),
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
                value: CurrencyFormatter.formatPaise(metrics.todaySalesPaise.toInt()),
                icon: Icons.currency_rupee,
                color: KiranaColors.primary,
              ),
              _KpiCard(
                title: "Bills Generated",
                value: '${metrics.todayBillsCount}',
                icon: Icons.receipt_long,
                color: KiranaColors.primaryLight,
              ),
              _KpiCard(
                title: "Udhaar Outstanding",
                value: CurrencyFormatter.formatPaise(metrics.totalUdhaarOutstandingPaise.toInt()),
                icon: Icons.account_balance_wallet,
                color: KiranaColors.secondary,
                onTap: () => context.push('/credit'),
              ),
              _KpiCard(
                title: "Low Stock Items",
                value: '${metrics.lowStockItemsCount} Items',
                icon: Icons.warning_amber,
                color: metrics.lowStockItemsCount > 0 ? KiranaColors.error : KiranaColors.neutral500,
                onTap: () => context.push('/inventory'),
              ),
            ],
          ),
          const SizedBox(height: KiranaSpacing.xxl),

          // Quick Action Buttons
          Text(
            'Quick Operations',
            style: KiranaTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
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
          ),
          const SizedBox(height: KiranaSpacing.xxl),

          // Recent Invoices Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Invoices',
                style: KiranaTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
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
                borderRadius: KiranaRadius.borderMd,
                border: Border.all(color: KiranaColors.neutral200),
              ),
              child: Column(
                children: [
                  const Icon(Icons.receipt_long_outlined, size: 40, color: KiranaColors.neutral400),
                  const SizedBox(height: KiranaSpacing.sm),
                  Text(
                    'No bills created yet today',
                    style: KiranaTypography.bodyMedium.copyWith(color: KiranaColors.neutral600),
                  ),
                  const SizedBox(height: KiranaSpacing.xs),
                  const Text(
                    'Start your first sale with Quick Barcode POS above.',
                    style: TextStyle(fontSize: 12, color: KiranaColors.neutral500),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: metrics.recentBills.length,
              separatorBuilder: (context, index) => const SizedBox(height: KiranaSpacing.xs),
              itemBuilder: (context, index) {
                final bill = metrics.recentBills[index];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: KiranaColors.primaryContainer,
                      child: Icon(Icons.receipt, color: KiranaColors.primary, size: 20),
                    ),
                    title: Text(
                      bill.billNumber,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${bill.createdAt.hour.toString().padLeft(2, '0')}:${bill.createdAt.minute.toString().padLeft(2, '0')} • ${bill.paymentStatus.toUpperCase()}',
                    ),
                    trailing: Text(
                      CurrencyFormatter.formatPaise(bill.totalPaise.toInt()),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                );
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
      child: InkWell(
        onTap: onTap,
        borderRadius: KiranaRadius.borderMd,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: KiranaSpacing.md, horizontal: KiranaSpacing.sm),
          child: Column(
            children: [
              Icon(icon, color: KiranaColors.primary, size: 24),
              const SizedBox(height: KiranaSpacing.xs),
              Text(
                title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
