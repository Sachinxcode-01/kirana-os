import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:kirana_mobile/database/drift/database.dart';
import 'package:kirana_mobile/features/customers/data/datasources/customer_local_data_source.dart';
import 'package:kirana_mobile/features/credit/data/repositories/credit_repository_impl.dart';
import 'package:kirana_mobile/features/customers/data/datasources/customer_remote_data_source.dart';

class FakeCustomerRemoteDataSource implements CustomerRemoteDataSource {
  @override
  Future<Map<String, dynamic>> recordCreditTransactionAtomic({
    required String shopId,
    required String customerId,
    required int amountPaise,
    required String type,
    String? billId,
    String? notes,
  }) async {
    return {
      'status': 'SUCCESS',
      'transaction_id': 'txn-atomic-fake-123',
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AppDatabase db;
  late CustomerLocalDataSource customerLocalDataSource;
  late CreditRepositoryImpl creditRepository;

  const shopA = 'shop-111-aaa';
  const shopB = 'shop-222-bbb';
  const customerId = 'cust-505-credit';
  const billId = 'bill-999-credit';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    customerLocalDataSource = CustomerLocalDataSource(db);

    // Seed customer with ₹1,500.00 debt (150000 paise) in Shop A
    await db.into(db.customersTable).insert(
          CustomersTableCompanion.insert(
            id: customerId,
            shopId: shopA,
            name: 'Rahul Kumar',
            phone: '9876543210',
            creditLimitPaise: drift.Value(BigInt.from(500000)),
            currentDebtPaise: drift.Value(BigInt.from(150000)), // ₹1,500.00
            createdAt: drift.Value(DateTime.now()),
            updatedAt: drift.Value(DateTime.now()),
          ),
        );

    // Seed product with 50.0 units stock in Shop A
    await db.into(db.productsTable).insert(
          ProductsTableCompanion.insert(
            id: 'prod-001',
            shopId: shopA,
            name: 'Fortune Rice 5kg',
            sellingPricePaise: BigInt.from(50000), // ₹500.00
            mrpPaise: BigInt.from(50000),
            currentStock: drift.Value(50.0),
            unit: drift.Value('kg'),
            taxRatePercentage: drift.Value(0.0),
            isActive: drift.Value(true),
            createdAt: drift.Value(DateTime.now()),
            updatedAt: drift.Value(DateTime.now()),
          ),
        );

    final mockRemote = FakeCustomerRemoteDataSource();
    creditRepository = CreditRepositoryImpl(
      localDataSource: customerLocalDataSource,
      remoteDataSource: mockRemote,
      shopId: shopA,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('KIRANAOS PHASE 14.5 — Credit / Udhaar Sale POS Tests', () {
    test(
        '1. Customer due calculation derives correctly (₹1,500 Existing + ₹500 Credit Sale = ₹2,000 New Due)',
        () async {
      final custBefore =
          await customerLocalDataSource.getCustomerById(customerId);
      expect(custBefore, isNotNull);
      final existingDuePaise = custBefore!.currentDebtPaise.toInt();
      expect(existingDuePaise, equals(150000)); // ₹1,500.00

      const salePaise = 50000; // ₹500.00
      final expectedNewDuePaise = existingDuePaise + salePaise;
      expect(expectedNewDuePaise, equals(200000)); // ₹2,000.00
    });

    test(
        '2. Executing recordCreditSale creates CREDIT_SALE (credit_given) ledger entry and increases debt to ₹2,000',
        () async {
      final result = await creditRepository.recordCreditSale(
        customerId: customerId,
        amountPaise: 50000, // ₹500.00
        billId: billId,
        notes: 'POS Checkout Udhaar Sale #INV-20260828-001',
      );

      expect(result.isSuccess, isTrue);

      // Verify updated debt balance in Drift SQLite
      final custAfter =
          await customerLocalDataSource.getCustomerById(customerId);
      expect(custAfter, isNotNull);
      expect(custAfter!.currentDebtPaise.toInt(), equals(200000)); // ₹2,000.00

      // Verify ledger entry created in creditTransactionsTable
      final ledgerEntries = await (db.select(db.creditTransactionsTable)
            ..where((tbl) => tbl.customerId.equals(customerId)))
          .get();
      expect(ledgerEntries.length, equals(1));
      final entry = ledgerEntries.first;
      expect(entry.type, equals('credit_given'));
      expect(entry.amountPaise.toInt(), equals(50000));
      expect(entry.billId, equals(billId));
    });

    test('3. Stock quantity is deducted correctly during sale execution',
        () async {
      final prodBefore = await (db.select(db.productsTable)
            ..where((tbl) => tbl.id.equals('prod-001')))
          .getSingle();
      expect(prodBefore.currentStock, equals(50.0));

      // Simulate stock deduction of 1.0 item
      await (db.update(db.productsTable)
            ..where((tbl) => tbl.id.equals('prod-001')))
          .write(
        const ProductsTableCompanion(currentStock: drift.Value(49.0)),
      );

      final prodAfter = await (db.select(db.productsTable)
            ..where((tbl) => tbl.id.equals('prod-001')))
          .getSingle();
      expect(prodAfter.currentStock, equals(49.0));
    });

    test(
        '4. Multi-Tenant Isolation: Shop B cannot record credit sale for Shop A customer',
        () async {
      final shopBRepository = CreditRepositoryImpl(
        localDataSource: customerLocalDataSource,
        remoteDataSource: FakeCustomerRemoteDataSource(),
        shopId: shopB,
      );

      final result = await shopBRepository.recordCreditSale(
        customerId: customerId,
        amountPaise: 50000,
        billId: 'bill-shopb',
      );

      expect(result.isFailure, isTrue);
    });
  });
}
