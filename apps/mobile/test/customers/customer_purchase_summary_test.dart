import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:kirana_mobile/database/drift/database.dart';
import 'package:kirana_mobile/features/customers/data/datasources/customer_local_data_source.dart';
import 'package:kirana_mobile/features/customers/data/datasources/customer_remote_data_source.dart';
import 'package:kirana_mobile/features/customers/data/repositories/customer_repository_impl.dart';

void main() {
  late AppDatabase db;
  late CustomerLocalDataSource localDataSource;
  late CustomerRepositoryImpl repository;

  const shopA = 'shop-111-aaa';
  const shopB = 'shop-222-bbb';
  const customerId = 'cust-101';
  const cashierId = 'cashier-001';

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    localDataSource = CustomerLocalDataSource(db);
    repository = CustomerRepositoryImpl(
      localDataSource: localDataSource,
      remoteDataSource: CustomerRemoteDataSource(null),
      shopId: shopA,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('KIRANAOS PHASE 14.2 — Customer Purchase Summary Tests', () {
    test('1. Customer with no purchases returns 0 totals & null last purchase',
        () async {
      final result = await repository.getCustomerPurchaseSummary(customerId);
      expect(result.isSuccess, isTrue);

      final summary = result.dataOrNull!;
      expect(summary.totalPurchasesPaise, equals(0));
      expect(summary.totalBillsCount, equals(0));
      expect(summary.lastPurchase, isNull);
      expect(summary.hasPurchases, isFalse);
    });

    test(
        '2. Multiple completed sales accurately calculates total purchases & last purchase',
        () async {
      final now = DateTime.now();

      // Bill 1 (Older - ₹150.00)
      await db.into(db.billsTable).insert(
            BillsTableCompanion.insert(
              id: 'bill-1',
              shopId: shopA,
              billNumber: 'INV-101',
              customerId: const drift.Value(customerId),
              cashierId: cashierId,
              subtotalPaise: BigInt.from(15000),
              taxTotalPaise: drift.Value(BigInt.zero),
              discountPaise: drift.Value(BigInt.zero),
              totalPaise: BigInt.from(15000),
              paymentStatus: const drift.Value('paid'),
              createdAt: drift.Value(now.subtract(const Duration(days: 2))),
              updatedAt: drift.Value(now.subtract(const Duration(days: 2))),
            ),
          );

      // Bill 2 (Latest - ₹450.00)
      await db.into(db.billsTable).insert(
            BillsTableCompanion.insert(
              id: 'bill-2',
              shopId: shopA,
              billNumber: 'INV-102',
              customerId: const drift.Value(customerId),
              cashierId: cashierId,
              subtotalPaise: BigInt.from(45000),
              taxTotalPaise: drift.Value(BigInt.zero),
              discountPaise: drift.Value(BigInt.zero),
              totalPaise: BigInt.from(45000),
              paymentStatus: const drift.Value('completed'),
              createdAt: drift.Value(now),
              updatedAt: drift.Value(now),
            ),
          );

      final result = await repository.getCustomerPurchaseSummary(customerId);
      expect(result.isSuccess, isTrue);

      final summary = result.dataOrNull!;
      expect(summary.totalPurchasesPaise, equals(60000)); // ₹600.00 total
      expect(summary.totalBillsCount, equals(2));
      expect(summary.hasPurchases, isTrue);
      expect(summary.lastPurchase?.id, equals('bill-2'));
      expect(summary.lastPurchase?.totalPaise, equals(BigInt.from(45000)));
    });

    test('3. Cancelled sales and drafts are excluded from totals', () async {
      final now = DateTime.now();

      // Valid Completed Bill (₹300.00)
      await db.into(db.billsTable).insert(
            BillsTableCompanion.insert(
              id: 'bill-valid',
              shopId: shopA,
              billNumber: 'INV-201',
              customerId: const drift.Value(customerId),
              cashierId: cashierId,
              subtotalPaise: BigInt.from(30000),
              totalPaise: BigInt.from(30000),
              paymentStatus: const drift.Value('paid'),
              isCancelled: const drift.Value(false),
              createdAt: drift.Value(now),
            ),
          );

      // Cancelled Bill (₹1000.00 - SHOULD BE EXCLUDED)
      await db.into(db.billsTable).insert(
            BillsTableCompanion.insert(
              id: 'bill-cancelled',
              shopId: shopA,
              billNumber: 'INV-202',
              customerId: const drift.Value(customerId),
              cashierId: cashierId,
              subtotalPaise: BigInt.from(100000),
              totalPaise: BigInt.from(100000),
              paymentStatus: const drift.Value('paid'),
              isCancelled: const drift.Value(true),
              createdAt: drift.Value(now),
            ),
          );

      // Pending Draft (₹500.00 - SHOULD BE EXCLUDED)
      await db.into(db.billsTable).insert(
            BillsTableCompanion.insert(
              id: 'bill-draft',
              shopId: shopA,
              billNumber: 'INV-203',
              customerId: const drift.Value(customerId),
              cashierId: cashierId,
              subtotalPaise: BigInt.from(50000),
              totalPaise: BigInt.from(50000),
              paymentStatus: const drift.Value('pending_draft'),
              createdAt: drift.Value(now),
            ),
          );

      final result = await repository.getCustomerPurchaseSummary(customerId);
      expect(result.isSuccess, isTrue);

      final summary = result.dataOrNull!;
      expect(summary.totalPurchasesPaise, equals(30000)); // Only ₹300.00
      expect(summary.totalBillsCount, equals(1));
      expect(summary.lastPurchase?.id, equals('bill-valid'));
    });

    test('4. Security & Shop Isolation: Excludes sales from other shops',
        () async {
      final now = DateTime.now();

      // Shop A Bill
      await db.into(db.billsTable).insert(
            BillsTableCompanion.insert(
              id: 'bill-shop-a',
              shopId: shopA,
              billNumber: 'INV-A1',
              customerId: const drift.Value(customerId),
              cashierId: cashierId,
              subtotalPaise: BigInt.from(20000),
              totalPaise: BigInt.from(20000),
              paymentStatus: const drift.Value('paid'),
              createdAt: drift.Value(now),
            ),
          );

      // Shop B Bill (Same customer ID in Shop B - SHOULD BE EXCLUDED)
      await db.into(db.billsTable).insert(
            BillsTableCompanion.insert(
              id: 'bill-shop-b',
              shopId: shopB,
              billNumber: 'INV-B1',
              customerId: const drift.Value(customerId),
              cashierId: cashierId,
              subtotalPaise: BigInt.from(99000),
              totalPaise: BigInt.from(99000),
              paymentStatus: const drift.Value('paid'),
              createdAt: drift.Value(now),
            ),
          );

      final result = await repository.getCustomerPurchaseSummary(customerId);
      expect(result.isSuccess, isTrue);

      final summary = result.dataOrNull!;
      expect(summary.totalPurchasesPaise, equals(20000));
      expect(summary.totalBillsCount, equals(1));
      expect(summary.lastPurchase?.id, equals('bill-shop-a'));
    });
  });
}
