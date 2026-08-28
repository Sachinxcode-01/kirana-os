import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:kirana_mobile/database/drift/database.dart';
import 'package:kirana_mobile/features/customers/data/datasources/customer_local_data_source.dart';
import 'package:kirana_mobile/features/customers/data/datasources/customer_remote_data_source.dart';
import 'package:kirana_mobile/features/credit/data/repositories/credit_repository_impl.dart';

void main() {
  late AppDatabase db;
  late CustomerLocalDataSource localDataSource;
  late CreditRepositoryImpl creditRepository;

  const shopA = 'shop-111-aaa';
  const shopB = 'shop-222-bbb';
  const customerId = 'cust-303';
  const cashierId = 'cashier-001';

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    localDataSource = CustomerLocalDataSource(db);
    creditRepository = CreditRepositoryImpl(
      localDataSource: localDataSource,
      remoteDataSource: CustomerRemoteDataSource(null),
      shopId: shopA,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('KIRANAOS PHASE 14.3 — Customer Ledger Foundation Tests', () {
    test('1. Empty customer ledger returns empty stream list', () async {
      final txns =
          await creditRepository.watchCreditTransactions(customerId).first;
      expect(txns, isEmpty);
    });

    test('2. Cash sales (non-Udhaar) are NOT inserted into credit_transactions',
        () async {
      final now = DateTime.now();

      // Normal Cash Sale (₹500.00)
      await db.into(db.billsTable).insert(
            BillsTableCompanion.insert(
              id: 'cash-bill-1',
              shopId: shopA,
              billNumber: 'INV-CASH-1',
              customerId: const drift.Value(customerId),
              cashierId: cashierId,
              subtotalPaise: BigInt.from(50000),
              totalPaise: BigInt.from(50000),
              paymentStatus: const drift.Value('paid'),
              createdAt: drift.Value(now),
            ),
          );

      // Verify credit_transactions table remains empty
      final txns =
          await creditRepository.watchCreditTransactions(customerId).first;
      expect(txns, isEmpty,
          reason: 'Cash sales must NOT create ledger entries');
    });

    test(
        '3. Credit transaction entries support immutable fields & correct attributes',
        () async {
      final now = DateTime.now();

      // Insert credit sale ledger entry
      await db.into(db.creditTransactionsTable).insert(
            CreditTransactionsTableCompanion.insert(
              id: 'txn-101',
              shopId: shopA,
              customerId: customerId,
              billId: const drift.Value('bill-udhaar-1'),
              amountPaise: BigInt.from(30000), // ₹300.00
              type: 'credit_given',
              notes: const drift.Value('Rice and Dal Udhaar'),
              recordedBy: cashierId,
              createdAt: drift.Value(now),
            ),
          );

      final txns =
          await creditRepository.watchCreditTransactions(customerId).first;
      expect(txns.length, equals(1));

      final entry = txns.first;
      expect(entry.id, equals('txn-101'));
      expect(entry.shopId, equals(shopA));
      expect(entry.customerId, equals(customerId));
      expect(entry.billId, equals('bill-udhaar-1'));
      expect(entry.amountPaise, equals(BigInt.from(30000)));
      expect(entry.type, equals('credit_given'));
      expect(entry.notes, equals('Rice and Dal Udhaar'));
      expect(entry.recordedBy, equals(cashierId));
    });

    test(
        '4. Security & Shop Isolation: Excludes credit transactions from other shops',
        () async {
      final now = DateTime.now();

      // Shop A Credit Transaction
      await db.into(db.creditTransactionsTable).insert(
            CreditTransactionsTableCompanion.insert(
              id: 'txn-shop-a',
              shopId: shopA,
              customerId: customerId,
              amountPaise: BigInt.from(15000),
              type: 'credit_given',
              recordedBy: cashierId,
              createdAt: drift.Value(now),
            ),
          );

      // Shop B Credit Transaction (Same Customer ID in Shop B)
      await db.into(db.creditTransactionsTable).insert(
            CreditTransactionsTableCompanion.insert(
              id: 'txn-shop-b',
              shopId: shopB,
              customerId: customerId,
              amountPaise: BigInt.from(99000),
              type: 'credit_given',
              recordedBy: cashierId,
              createdAt: drift.Value(now),
            ),
          );

      final txns =
          await creditRepository.watchCreditTransactions(customerId).first;
      expect(txns.length, equals(1));
      expect(txns.first.id, equals('txn-shop-a'));
      expect(txns.first.shopId, equals(shopA));
    });
  });
}
