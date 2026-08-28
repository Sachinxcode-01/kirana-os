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

      // 1. Insert 2 completed bills created today
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
              isCancelled: const d.Value(false),
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
              isCancelled: const d.Value(false),
              createdAt: d.Value(now),
              updatedAt: d.Value(now),
            ),
          );

      // Cancelled bill (must be excluded)
      await db.into(db.billsTable).insert(
            BillsTableCompanion(
              id: const d.Value('bill_cancelled'),
              shopId: const d.Value(testShopId),
              billNumber: const d.Value('BILL-CAN'),
              cashierId: const d.Value('cashier_1'),
              subtotalPaise: d.Value(BigInt.from(90000)),
              taxTotalPaise: d.Value(BigInt.zero),
              discountPaise: d.Value(BigInt.zero),
              totalPaise: d.Value(BigInt.from(90000)),
              paymentStatus: const d.Value('unpaid'),
              isCancelled: const d.Value(true),
              createdAt: d.Value(now),
              updatedAt: d.Value(now),
            ),
          );

      // Insert bill items for top products
      await db.into(db.billItemsTable).insert(
            BillItemsTableCompanion(
              id: const d.Value('item_1'),
              billId: const d.Value('bill_001'),
              productId: const d.Value('p1'),
              productName: const d.Value('Milk'),
              quantity: const d.Value(24.0),
              unitPricePaise: d.Value(BigInt.from(3000)),
              totalPaise: d.Value(BigInt.from(72000)),
            ),
          );

      await db.into(db.billItemsTable).insert(
            BillItemsTableCompanion(
              id: const d.Value('item_2'),
              billId: const d.Value('bill_002'),
              productId: const d.Value('p2'),
              productName: const d.Value('Bread'),
              quantity: const d.Value(18.0),
              unitPricePaise: d.Value(BigInt.from(4000)),
              totalPaise: d.Value(BigInt.from(72000)),
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
      // ₹150 + ₹250 = ₹400 = 40000 paise (excluding cancelled bill)
      expect(metrics.todaySalesPaise, BigInt.from(40000));
      expect(metrics.todayBillsCount, 2);

      // Udhaar debt
      expect(metrics.totalUdhaarOutstandingPaise, BigInt.from(80000));

      // Low stock items
      expect(metrics.lowStockItemsCount, 2);

      // Recent completed bills
      expect(metrics.recentBills.length, 2);
      expect(metrics.recentBills.first.billNumber, 'BILL-002');

      // Top products
      expect(metrics.topProducts.length, 2);
      expect(metrics.topProducts.first.productName, 'Milk');
      expect(metrics.topProducts.first.quantitySold, 24.0);

      // Sales trend past 7 days
      expect(metrics.salesTrend.length, 7);
      expect(metrics.salesTrend.last.totalPaise, BigInt.from(40000));
    });

    test(
        'Excludes draft, failed payment, and cancelled bills from today sales and bill count',
        () async {
      final now = DateTime.now();

      // Completed bill = 5000 paise (₹50)
      await db.into(db.billsTable).insert(
            BillsTableCompanion(
              id: const d.Value('bill_comp'),
              shopId: const d.Value(testShopId),
              billNumber: const d.Value('BILL-C1'),
              cashierId: const d.Value('cashier_1'),
              subtotalPaise: d.Value(BigInt.from(5000)),
              taxTotalPaise: d.Value(BigInt.zero),
              discountPaise: d.Value(BigInt.zero),
              totalPaise: d.Value(BigInt.from(5000)),
              paymentStatus: const d.Value('paid'),
              isCancelled: const d.Value(false),
              createdAt: d.Value(now),
              updatedAt: d.Value(now),
            ),
          );

      // Draft bill (must be excluded)
      await db.into(db.billsTable).insert(
            BillsTableCompanion(
              id: const d.Value('bill_draft'),
              shopId: const d.Value(testShopId),
              billNumber: const d.Value('BILL-DRAFT'),
              cashierId: const d.Value('cashier_1'),
              subtotalPaise: d.Value(BigInt.from(99000)),
              taxTotalPaise: d.Value(BigInt.zero),
              discountPaise: d.Value(BigInt.zero),
              totalPaise: d.Value(BigInt.from(99000)),
              paymentStatus: const d.Value('unpaid'),
              isCancelled: const d.Value(false),
              createdAt: d.Value(now),
              updatedAt: d.Value(now),
            ),
          );

      // Failed payment bill (must be excluded)
      await db.into(db.billsTable).insert(
            BillsTableCompanion(
              id: const d.Value('bill_failed'),
              shopId: const d.Value(testShopId),
              billNumber: const d.Value('BILL-FAIL'),
              cashierId: const d.Value('cashier_1'),
              subtotalPaise: d.Value(BigInt.from(44000)),
              taxTotalPaise: d.Value(BigInt.zero),
              discountPaise: d.Value(BigInt.zero),
              totalPaise: d.Value(BigInt.from(44000)),
              paymentStatus: const d.Value('failed'),
              isCancelled: const d.Value(false),
              createdAt: d.Value(now),
              updatedAt: d.Value(now),
            ),
          );

      final result = await repository.getDashboardMetrics(testShopId);
      expect(result.isSuccess, isTrue);
      final metrics = result.dataOrNull!;
      expect(metrics.todaySalesPaise, BigInt.from(5000));
      expect(metrics.todayBillsCount, 1);
    });

    test('Enforces strict shop isolation (Shop A does not leak Shop B sales)',
        () async {
      final now = DateTime.now();

      // Shop A bill
      await db.into(db.billsTable).insert(
            BillsTableCompanion(
              id: const d.Value('shop_a_bill'),
              shopId: const d.Value(testShopId),
              billNumber: const d.Value('BILL-A1'),
              cashierId: const d.Value('cashier_1'),
              subtotalPaise: d.Value(BigInt.from(10000)),
              taxTotalPaise: d.Value(BigInt.zero),
              discountPaise: d.Value(BigInt.zero),
              totalPaise: d.Value(BigInt.from(10000)),
              paymentStatus: const d.Value('paid'),
              isCancelled: const d.Value(false),
              createdAt: d.Value(now),
              updatedAt: d.Value(now),
            ),
          );

      // Shop B bill
      await db.into(db.billsTable).insert(
            BillsTableCompanion(
              id: const d.Value('shop_b_bill'),
              shopId: const d.Value('shop_b_other'),
              billNumber: const d.Value('BILL-B1'),
              cashierId: const d.Value('cashier_2'),
              subtotalPaise: d.Value(BigInt.from(50000)),
              taxTotalPaise: d.Value(BigInt.zero),
              discountPaise: d.Value(BigInt.zero),
              totalPaise: d.Value(BigInt.from(50000)),
              paymentStatus: const d.Value('paid'),
              isCancelled: const d.Value(false),
              createdAt: d.Value(now),
              updatedAt: d.Value(now),
            ),
          );

      final shopAResult = await repository.getDashboardMetrics(testShopId);
      final shopBResult = await repository.getDashboardMetrics('shop_b_other');

      expect(shopAResult.dataOrNull!.todaySalesPaise, BigInt.from(10000));
      expect(shopAResult.dataOrNull!.todayBillsCount, 1);

      expect(shopBResult.dataOrNull!.todaySalesPaise, BigInt.from(50000));
      expect(shopBResult.dataOrNull!.todayBillsCount, 1);
    });
  });
}
