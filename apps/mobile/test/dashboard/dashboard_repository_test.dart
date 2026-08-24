import 'package:drift/drift.dart' as d;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_mobile/database/drift/database.dart';
import 'package:kirana_mobile/features/dashboard/data/datasources/dashboard_local_data_source.dart';
import 'package:kirana_mobile/features/dashboard/data/repositories/dashboard_repository_impl.dart';

void main() {
  late AppDatabase db;
  late DashboardLocalDataSource localDataSource;
  late DashboardRepositoryImpl repository;
  const testShopId = 'shop_dash_test_1';

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    localDataSource = DashboardLocalDataSource(db);
    repository = DashboardRepositoryImpl(localDataSource);
  });

  tearDown(() async {
    await db.close();
  });

  group('Dashboard Real Aggregations Tests', () {
    test(
        'Calculates exact sales, bills count, udhaar debt, and low stock items',
        () async {
      final now = DateTime.now();
      final earlier = now.subtract(const Duration(minutes: 15));

      // 1. Insert 2 bills created today
      await db.into(db.billsTable).insert(
            BillsTableCompanion(
              id: const d.Value('bill_001'),
              shopId: const d.Value(testShopId),
              billNumber: const d.Value('BILL-001'),
              cashierId: const d.Value('cashier_1'),
              subtotalPaise: d.Value(BigInt.from(15000)), // ₹150
              taxTotalPaise: d.Value(BigInt.zero),
              discountPaise: d.Value(BigInt.zero),
              totalPaise: d.Value(BigInt.from(15000)),
              paymentStatus: const d.Value('paid'),
              createdAt: d.Value(earlier),
              updatedAt: d.Value(earlier),
            ),
          );

      await db.into(db.billsTable).insert(
            BillsTableCompanion(
              id: const d.Value('bill_002'),
              shopId: const d.Value(testShopId),
              billNumber: const d.Value('BILL-002'),
              cashierId: const d.Value('cashier_1'),
              subtotalPaise: d.Value(BigInt.from(25000)), // ₹250
              taxTotalPaise: d.Value(BigInt.zero),
              discountPaise: d.Value(BigInt.zero),
              totalPaise: d.Value(BigInt.from(25000)),
              paymentStatus: const d.Value('paid'),
              createdAt: d.Value(now),
              updatedAt: d.Value(now),
            ),
          );

      // 2. Insert 2 customers with Udhaar debt
      await db.into(db.customersTable).insert(
            CustomersTableCompanion(
              id: const d.Value('cust_001'),
              shopId: const d.Value(testShopId),
              name: const d.Value('Anand Sharma'),
              phone: const d.Value('9876543210'),
              creditLimitPaise: d.Value(BigInt.from(500000)),
              currentDebtPaise: d.Value(BigInt.from(50000)), // ₹500
              createdAt: d.Value(now),
              updatedAt: d.Value(now),
            ),
          );

      await db.into(db.customersTable).insert(
            CustomersTableCompanion(
              id: const d.Value('cust_002'),
              shopId: const d.Value(testShopId),
              name: const d.Value('Pooja Patel'),
              phone: const d.Value('9876543211'),
              creditLimitPaise: d.Value(BigInt.from(500000)),
              currentDebtPaise: d.Value(BigInt.from(30000)), // ₹300
              createdAt: d.Value(now),
              updatedAt: d.Value(now),
            ),
          );

      // 3. Insert products (1 normal stock, 2 low stock <= 5.0)
      await db.into(db.productsTable).insert(
            ProductsTableCompanion(
              id: const d.Value('prod_in_stock'),
              shopId: const d.Value(testShopId),
              name: const d.Value('Basmati Rice 5kg'),
              mrpPaise: d.Value(BigInt.from(45000)),
              sellingPricePaise: d.Value(BigInt.from(42000)),
              purchasePricePaise: d.Value(BigInt.from(38000)),
              currentStock: const d.Value(20.0), // Normal
              createdAt: d.Value(now),
              updatedAt: d.Value(now),
            ),
          );

      await db.into(db.productsTable).insert(
            ProductsTableCompanion(
              id: const d.Value('prod_low_1'),
              shopId: const d.Value(testShopId),
              name: const d.Value('Amul Butter 100g'),
              mrpPaise: d.Value(BigInt.from(5600)),
              sellingPricePaise: d.Value(BigInt.from(5400)),
              purchasePricePaise: d.Value(BigInt.from(4800)),
              currentStock: const d.Value(3.0), // Low stock
              createdAt: d.Value(now),
              updatedAt: d.Value(now),
            ),
          );

      await db.into(db.productsTable).insert(
            ProductsTableCompanion(
              id: const d.Value('prod_low_2'),
              shopId: const d.Value(testShopId),
              name: const d.Value('Maggi 70g'),
              mrpPaise: d.Value(BigInt.from(1400)),
              sellingPricePaise: d.Value(BigInt.from(1400)),
              purchasePricePaise: d.Value(BigInt.from(1200)),
              currentStock: const d.Value(1.0), // Low stock
              createdAt: d.Value(now),
              updatedAt: d.Value(now),
            ),
          );

      // 4. Query aggregated metrics
      final result = await repository.getDashboardMetrics(testShopId);
      expect(result.isSuccess, isTrue);

      final metrics = result.dataOrNull!;
      // ₹150 + ₹250 = ₹400 = 40000 paise
      expect(metrics.todaySalesPaise, BigInt.from(40000));
      expect(metrics.todayBillsCount, 2);

      // ₹500 + ₹300 = ₹800 = 80000 paise
      expect(metrics.totalUdhaarOutstandingPaise, BigInt.from(80000));

      // 2 low stock items
      expect(metrics.lowStockItemsCount, 2);

      // 2 recent bills
      expect(metrics.recentBills.length, 2);
      expect(metrics.recentBills.first.billNumber, 'BILL-002');
    });
  });
}
