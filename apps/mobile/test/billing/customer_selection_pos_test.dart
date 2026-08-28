import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:kirana_mobile/database/drift/database.dart';
import 'package:kirana_mobile/features/billing/domain/models/bill_model.dart';
import 'package:kirana_mobile/features/billing/domain/usecases/billing_usecases.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('KIRANAOS PHASE 14.1 — POS Customer Selection & Persistence Tests', () {
    const shopA = 'shop-aaa-111';
    const shopB = 'shop-bbb-222';
    const cashierId = 'cashier-999';
    final now = DateTime.now();

    test('1. Attach Customer to Bill Draft', () {
      final attachUseCase = AttachCustomerToBillUseCase();
      final initialBill = BillModel(
        id: 'bill-1',
        shopId: shopA,
        billNumber: 'INV-001',
        cashierId: cashierId,
        items: const [],
        subtotalPaise: 10000,
        taxTotalPaise: 500,
        discountPaise: 0,
        totalPaise: 10500,
        createdAt: now,
        updatedAt: now,
      );

      expect(initialBill.hasCustomer, isFalse);
      expect(initialBill.customerId, isNull);

      final updatedBill = attachUseCase.execute(
        bill: initialBill,
        customerId: 'cust-101',
        customerName: 'Ramesh Kumar',
        customerPhone: '9876543210',
      );

      expect(updatedBill.hasCustomer, isTrue);
      expect(updatedBill.customerId, equals('cust-101'));
      expect(updatedBill.customerName, equals('Ramesh Kumar'));
      expect(updatedBill.customerPhone, equals('9876543210'));
    });

    test('2. Change Customer on Active Draft', () {
      final attachUseCase = AttachCustomerToBillUseCase();
      final initialBill = BillModel(
        id: 'bill-1',
        shopId: shopA,
        billNumber: 'INV-001',
        cashierId: cashierId,
        items: const [],
        customerId: 'cust-101',
        customerName: 'Ramesh Kumar',
        customerPhone: '9876543210',
        subtotalPaise: 5000,
        taxTotalPaise: 0,
        discountPaise: 0,
        totalPaise: 5000,
        createdAt: now,
        updatedAt: now,
      );

      // Change customer to Suresh
      final changedBill = attachUseCase.execute(
        bill: initialBill,
        customerId: 'cust-102',
        customerName: 'Suresh Patel',
        customerPhone: '9123456789',
      );

      expect(changedBill.customerId, equals('cust-102'));
      expect(changedBill.customerName, equals('Suresh Patel'));
      expect(changedBill.customerPhone, equals('9123456789'));
    });

    test('3. Remove Customer Reverts Draft to Walk-in Customer', () {
      final removeUseCase = RemoveCustomerFromBillUseCase();
      final billWithCustomer = BillModel(
        id: 'bill-1',
        shopId: shopA,
        billNumber: 'INV-001',
        cashierId: cashierId,
        items: const [],
        customerId: 'cust-101',
        customerName: 'Ramesh Kumar',
        customerPhone: '9876543210',
        subtotalPaise: 5000,
        taxTotalPaise: 0,
        discountPaise: 0,
        totalPaise: 5000,
        createdAt: now,
        updatedAt: now,
      );

      final walkInBill = removeUseCase.execute(billWithCustomer);

      expect(walkInBill.hasCustomer, isFalse);
      expect(walkInBill.customerId, isNull);
      expect(walkInBill.customerName, isNull);
      expect(walkInBill.customerPhone, isNull);
    });

    test('4. Customer Data Persistence on Completed Sale in SQLite Database', () async {
      // 1. Insert Customer in Drift DB
      final custCompanion = CustomersTableCompanion.insert(
        id: 'cust-777',
        shopId: shopA,
        name: 'Anita Sharma',
        phone: '9988776655',
        creditLimitPaise: drift.Value(BigInt.zero),
        currentDebtPaise: drift.Value(BigInt.zero),
      );
      await db.customersDao.upsertCustomer(custCompanion);

      // 2. Insert Bill linked to customer
      final billCompanion = BillsTableCompanion.insert(
        id: 'bill-777',
        shopId: shopA,
        billNumber: 'INV-007',
        customerId: const drift.Value('cust-777'),
        cashierId: cashierId,
        subtotalPaise: BigInt.from(25000),
        taxTotalPaise: drift.Value(BigInt.zero),
        discountPaise: drift.Value(BigInt.zero),
        totalPaise: BigInt.from(25000),
        paymentStatus: const drift.Value('paid'),
        createdAt: drift.Value(now),
        updatedAt: drift.Value(now),
      );
      await db.into(db.billsTable).insert(billCompanion);

      // 3. Query bill and verify customer_id persistence
      final savedBill = await (db.select(db.billsTable)
            ..where((t) => t.id.equals('bill-777')))
          .getSingle();

      expect(savedBill.customerId, equals('cust-777'));
      expect(savedBill.totalPaise, equals(BigInt.from(25000)));

      // 4. Query customer sales history
      final customerSales = await db.customersDao.getCustomerSalesHistory(shopA, 'cust-777');
      expect(customerSales.length, equals(1));
      expect(customerSales.first.id, equals('bill-777'));
    });

    test('5. Security & Multi-tenant Shop Isolation', () async {
      // Create Customer in Shop A
      await db.customersDao.upsertCustomer(
        CustomersTableCompanion.insert(
          id: 'cust-shop-a',
          shopId: shopA,
          name: 'Shop A Customer',
          phone: '9000000001',
          creditLimitPaise: drift.Value(BigInt.zero),
          currentDebtPaise: drift.Value(BigInt.zero),
        ),
      );

      // Create Customer in Shop B
      await db.customersDao.upsertCustomer(
        CustomersTableCompanion.insert(
          id: 'cust-shop-b',
          shopId: shopB,
          name: 'Shop B Customer',
          phone: '9000000002',
          creditLimitPaise: drift.Value(BigInt.zero),
          currentDebtPaise: drift.Value(BigInt.zero),
        ),
      );

      // Stream Shop A customers -> must NOT contain Shop B customer
      final shopACustomers = await db.customersDao.watchCustomers(shopA).first;
      expect(shopACustomers.length, equals(1));
      expect(shopACustomers.first.name, equals('Shop A Customer'));

      // Stream Shop B customers -> must NOT contain Shop A customer
      final shopBCustomers = await db.customersDao.watchCustomers(shopB).first;
      expect(shopBCustomers.length, equals(1));
      expect(shopBCustomers.first.name, equals('Shop B Customer'));
    });
  });
}
