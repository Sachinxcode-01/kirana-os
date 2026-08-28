import 'package:drift/drift.dart';
import '../../../../database/drift/database.dart';
import '../../domain/models/dashboard_metrics.dart';

class DashboardLocalDataSource {
  final AppDatabase _db;

  DashboardLocalDataSource(this._db);

  DateTime get _startOfToday {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime get _startOfYesterday {
    return _startOfToday.subtract(const Duration(days: 1));
  }

  Future<DashboardMetrics> getMetrics(String shopId,
      {bool isOffline = true}) async {
    final startOfDay = _startOfToday;
    final startOfYesterday = _startOfYesterday;

    // 1. Today's completed non-cancelled sales and bills count
    final billsQuery = _db.select(_db.billsTable)
      ..where((tbl) =>
          tbl.shopId.equals(shopId) &
          tbl.paymentStatus.isIn(const ['paid', 'completed']) &
          tbl.isCancelled.equals(false) &
          tbl.createdAt.isBiggerOrEqualValue(startOfDay));
    final todayBills = await billsQuery.get();

    BigInt todaySales = BigInt.zero;
    final todayBillIds = <String>{};
    for (final bill in todayBills) {
      todaySales += bill.totalPaise;
      todayBillIds.add(bill.id);
    }
    final int billsCount = todayBills.length;

    // 2. Yesterday's bill count
    final yesterdayBillsQuery = _db.select(_db.billsTable)
      ..where((tbl) =>
          tbl.shopId.equals(shopId) &
          tbl.paymentStatus.isIn(const ['paid', 'completed']) &
          tbl.isCancelled.equals(false) &
          tbl.createdAt.isBiggerOrEqualValue(startOfYesterday) &
          tbl.createdAt.isSmallerThanValue(startOfDay));
    final yesterdayBills = await yesterdayBillsQuery.get();
    final int yesterdayCount = yesterdayBills.length;

    // 3. Today's Top Products (Ranked by quantity sold from completed bill_items today)
    List<TopProductItem> topProducts = [];
    if (todayBillIds.isNotEmpty) {
      final itemsQuery = _db.select(_db.billItemsTable)
        ..where((tbl) => tbl.billId.isIn(todayBillIds));
      final items = await itemsQuery.get();

      final Map<String, double> qtyMap = {};
      for (final item in items) {
        qtyMap[item.productName] =
            (qtyMap[item.productName] ?? 0.0) + item.quantity;
      }

      final sortedEntries = qtyMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      topProducts = sortedEntries
          .take(5)
          .map((e) => TopProductItem(productName: e.key, quantitySold: e.value))
          .toList();
    }

    // 4. Basic Sales Trend for recent 7 days
    final List<SalesTrendItem> salesTrend = [];
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    for (int i = 6; i >= 0; i--) {
      final dayStart = startOfDay.subtract(Duration(days: i));
      final dayEnd = dayStart.add(const Duration(days: 1));

      final dayBillsQuery = _db.select(_db.billsTable)
        ..where((tbl) =>
            tbl.shopId.equals(shopId) &
            tbl.paymentStatus.isIn(const ['paid', 'completed']) &
            tbl.isCancelled.equals(false) &
            tbl.createdAt.isBiggerOrEqualValue(dayStart) &
            tbl.createdAt.isSmallerThanValue(dayEnd));
      final dayBills = await dayBillsQuery.get();

      BigInt dayTotal = BigInt.zero;
      for (final b in dayBills) {
        dayTotal += b.totalPaise;
      }

      final monthStr = dayStart.month.toString().padLeft(2, '0');
      final dayStr = dayStart.day.toString().padLeft(2, '0');
      final dateStr = '${dayStart.year}-$monthStr-$dayStr';
      final dayLabel = dayNames[dayStart.weekday - 1];

      salesTrend.add(SalesTrendItem(
        dateStr: dateStr,
        dayLabel: dayLabel,
        totalPaise: dayTotal,
      ));
    }

    // 5. Total Udhaar debt outstanding
    final customersQuery = _db.select(_db.customersTable)
      ..where((tbl) => tbl.shopId.equals(shopId));
    final customers = await customersQuery.get();

    BigInt totalDebt = BigInt.zero;
    for (final c in customers) {
      totalDebt += c.currentDebtPaise;
    }

    // 6. Low stock count
    final lowStockQuery = _db.select(_db.productsTable)
      ..where((tbl) =>
          tbl.shopId.equals(shopId) &
          tbl.currentStock.isSmallerOrEqualValue(5.0));
    final lowStockItems = await lowStockQuery.get();
    final int lowStockCount = lowStockItems.length;

    // 7. Recent completed bills (up to 5)
    final recentBillsQuery = _db.select(_db.billsTable)
      ..where((tbl) =>
          tbl.shopId.equals(shopId) &
          tbl.paymentStatus.isIn(const ['paid', 'completed']) &
          tbl.isCancelled.equals(false))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)])
      ..limit(5);
    final recentRows = await recentBillsQuery.get();

    final recentBills = recentRows.map((r) {
      return RecentBillItem(
        id: r.id,
        billNumber: r.billNumber,
        totalPaise: r.totalPaise,
        paymentStatus: r.paymentStatus,
        createdAt: r.createdAt,
      );
    }).toList();

    return DashboardMetrics(
      todaySalesPaise: todaySales,
      todayBillsCount: billsCount,
      yesterdayBillsCount: yesterdayCount,
      topProducts: topProducts,
      salesTrend: salesTrend,
      totalUdhaarOutstandingPaise: totalDebt,
      lowStockItemsCount: lowStockCount,
      recentBills: recentBills,
      lastSyncedAt: DateTime.now(),
      isOffline: isOffline,
    );
  }

  Stream<DashboardMetrics> watchMetrics(String shopId) {
    // Watch bills table to reactively recompute metrics on every new bill
    return _db.select(_db.billsTable).watch().asyncMap((_) async {
      return await getMetrics(shopId, isOffline: true);
    });
  }
}
