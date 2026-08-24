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

  Future<DashboardMetrics> getMetrics(String shopId) async {
    final startOfDay = _startOfToday;

    // 1. Today's sales and bills count
    final billsQuery = _db.select(_db.billsTable)
      ..where((tbl) =>
          tbl.shopId.equals(shopId) &
          tbl.createdAt.isBiggerOrEqualValue(startOfDay));
    final todayBills = await billsQuery.get();

    BigInt todaySales = BigInt.zero;
    for (final bill in todayBills) {
      todaySales += bill.totalPaise;
    }
    final int billsCount = todayBills.length;

    // 2. Total Udhaar debt outstanding
    final customersQuery = _db.select(_db.customersTable)
      ..where((tbl) => tbl.shopId.equals(shopId));
    final customers = await customersQuery.get();

    BigInt totalDebt = BigInt.zero;
    for (final c in customers) {
      totalDebt += c.currentDebtPaise;
    }

    // 3. Low stock count
    final lowStockQuery = _db.select(_db.productsTable)
      ..where((tbl) =>
          tbl.shopId.equals(shopId) &
          tbl.currentStock.isSmallerOrEqualValue(5.0));
    final lowStockItems = await lowStockQuery.get();
    final int lowStockCount = lowStockItems.length;

    // 4. Recent bills (up to 5)
    final recentBillsQuery = _db.select(_db.billsTable)
      ..where((tbl) => tbl.shopId.equals(shopId))
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
      totalUdhaarOutstandingPaise: totalDebt,
      lowStockItemsCount: lowStockCount,
      recentBills: recentBills,
      lastSyncedAt: DateTime.now(),
    );
  }

  Stream<DashboardMetrics> watchMetrics(String shopId) {
    // Watch bills table to reactively recompute metrics on every new bill
    return _db.select(_db.billsTable).watch().asyncMap((_) async {
      return await getMetrics(shopId);
    });
  }
}
