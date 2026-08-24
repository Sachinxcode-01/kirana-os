class RecentBillItem {
  final String id;
  final String billNumber;
  final BigInt totalPaise;
  final String paymentStatus;
  final String? customerName;
  final DateTime createdAt;

  const RecentBillItem({
    required this.id,
    required this.billNumber,
    required this.totalPaise,
    required this.paymentStatus,
    this.customerName,
    required this.createdAt,
  });
}

class DashboardMetrics {
  final BigInt todaySalesPaise;
  final int todayBillsCount;
  final BigInt totalUdhaarOutstandingPaise;
  final int lowStockItemsCount;
  final List<RecentBillItem> recentBills;
  final DateTime? lastSyncedAt;

  const DashboardMetrics({
    required this.todaySalesPaise,
    required this.todayBillsCount,
    required this.totalUdhaarOutstandingPaise,
    required this.lowStockItemsCount,
    required this.recentBills,
    this.lastSyncedAt,
  });

  factory DashboardMetrics.empty() {
    return DashboardMetrics(
      todaySalesPaise: BigInt.zero,
      todayBillsCount: 0,
      totalUdhaarOutstandingPaise: BigInt.zero,
      lowStockItemsCount: 0,
      recentBills: const [],
      lastSyncedAt: null,
    );
  }
}
