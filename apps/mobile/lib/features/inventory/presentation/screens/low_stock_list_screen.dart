import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../providers/low_stock_provider.dart';

class LowStockListScreen extends ConsumerStatefulWidget {
  const LowStockListScreen({super.key});

  @override
  ConsumerState<LowStockListScreen> createState() => _LowStockListScreenState();
}

class _LowStockListScreenState extends ConsumerState<LowStockListScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      ref.read(lowStockNotifierProvider.notifier).setSearchQuery(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final alertState = ref.watch(lowStockNotifierProvider);
    final alertNotifier = ref.read(lowStockNotifierProvider.notifier);
    final alerts = alertState.alerts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Low Stock Alerts'),
        actions: [
          if (alertState.unreadCount > 0)
            TextButton.icon(
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text('Mark All Read'),
              onPressed: () => alertNotifier.markAllAsRead(),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => alertNotifier.loadAlerts(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Offline Banner
          if (alertState.isOffline)
            Container(
              width: double.infinity,
              color: KiranaColors.warningContainer,
              padding: const EdgeInsets.symmetric(
                horizontal: KiranaSpacing.md,
                vertical: KiranaSpacing.xs,
              ),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off_outlined,
                      color: KiranaColors.warning, size: 18),
                  const SizedBox(width: KiranaSpacing.xs),
                  Expanded(
                    child: Text(
                      alertState.lastSyncedAt != null
                          ? 'Offline · Last synced ${DateFormatter.formatDate(alertState.lastSyncedAt!)}'
                          : 'Offline · Showing cached low-stock alerts',
                      style: KiranaTypography.bodySmall.copyWith(
                        color: KiranaColors.warning,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(KiranaSpacing.md),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search low-stock products by name or barcode...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: KiranaSpacing.md,
                  vertical: KiranaSpacing.xs,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          // Summary Metric Pill
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: KiranaSpacing.md),
            child: Row(
              children: [
                _HeaderPill(
                  label: 'OUT OF STOCK: ${alertState.outOfStockCount}',
                  color: KiranaColors.error,
                ),
                const SizedBox(width: KiranaSpacing.xs),
                _HeaderPill(
                  label: 'LOW STOCK: ${alertState.lowStockCount}',
                  color: KiranaColors.warning,
                ),
                const SizedBox(width: KiranaSpacing.xs),
                _HeaderPill(
                  label: 'UNREAD: ${alertState.unreadCount}',
                  color: KiranaColors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: KiranaSpacing.sm),

          // Alert List
          Expanded(
            child: alertState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : alerts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline,
                                size: 56, color: KiranaColors.success),
                            const SizedBox(height: KiranaSpacing.md),
                            Text(
                              alertState.search.isNotEmpty
                                  ? 'No low-stock alerts match search query.'
                                  : 'All stock levels are healthy!',
                              style: KiranaTypography.titleMedium,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          await alertNotifier.loadAlerts();
                        },
                        child: ListView.separated(
                          padding: const EdgeInsets.all(KiranaSpacing.md),
                          itemCount: alerts.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: KiranaSpacing.xs),
                          itemBuilder: (context, index) {
                            final alert = alerts[index];
                            final isOutOfStock = alert.isOutOfStock;
                            final badgeColor = isOutOfStock
                                ? KiranaColors.error
                                : KiranaColors.warning;

                            return Card(
                              elevation: alert.isRead ? 1 : 3,
                              color: alert.isRead
                                  ? KiranaColors.surface
                                  : KiranaColors.primaryContainer
                                      .withValues(alpha: 0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: badgeColor.withValues(
                                      alpha: alert.isRead ? 0.3 : 0.8),
                                  width: alert.isRead ? 1 : 1.5,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: KiranaSpacing.md,
                                  vertical: KiranaSpacing.xs,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor:
                                      badgeColor.withValues(alpha: 0.15),
                                  child: Icon(
                                    isOutOfStock
                                        ? Icons.error_outline
                                        : Icons.warning_amber_rounded,
                                    color: badgeColor,
                                    size: 20,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        alert.productName,
                                        style: KiranaTypography.titleMedium
                                            .copyWith(
                                          fontWeight: alert.isRead
                                              ? FontWeight.normal
                                              : FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color:
                                            badgeColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        isOutOfStock
                                            ? 'OUT OF STOCK'
                                            : 'LOW STOCK',
                                        style: KiranaTypography.labelSmall
                                            .copyWith(
                                          color: badgeColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 2),
                                    Text(
                                      'Current: ${alert.currentQuantity} ${alert.unit} • Minimum: ${alert.minimumQuantity} ${alert.unit}',
                                      style: KiranaTypography.bodySmall,
                                    ),
                                    if (alert.barcode != null)
                                      Text(
                                        'Barcode: ${alert.barcode}',
                                        style: KiranaTypography.labelSmall
                                            .copyWith(
                                                color: KiranaColors.textMuted),
                                      ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (!alert.isRead)
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          color: KiranaColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                onTap: () {
                                  if (!alert.isRead) {
                                    alertNotifier.markAlertAsRead(alert.id);
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  final String label;
  final Color color;

  const _HeaderPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: KiranaTypography.labelSmall.copyWith(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
