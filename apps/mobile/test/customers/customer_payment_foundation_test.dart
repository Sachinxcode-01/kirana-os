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
  const customerId = 'cust-404';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    localDataSource = CustomerLocalDataSource(db);

    // Create target customer with ₹1,000.00 debt in Shop A
    await db.into(db.customersTable).insert(
          CustomersTableCompanion.insert(
            id: customerId,
            shopId: shopA,
            name: 'Payment Test Customer',
            phone: '9876543210',
            creditLimitPaise: drift.Value(BigInt.from(100000)),
            currentDebtPaise:
                drift.Value(BigInt.from(100000)), // ₹1,000.00 debt
            createdAt: drift.Value(DateTime.now()),
            updatedAt: drift.Value(DateTime.now()),
          ),
        );

    final mockRemote = FakeCustomerRemoteDataSource();
    creditRepository = CreditRepositoryImpl(
      localDataSource: localDataSource,
      remoteDataSource: mockRemote,
      shopId: shopA,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('KIRANAOS PHASE 14.4 — Customer Payment Foundation Tests', () {
    test('1. Zero or negative payment amount is rejected with validation error',
        () async {
      final resZero = await creditRepository.recordCreditPayment(
        customerId: customerId,
        amountPaise: 0,
      );
      expect(resZero.isError, isTrue);

      final resNeg = await creditRepository.recordCreditPayment(
        customerId: customerId,
        amountPaise: -500,
      );
      expect(resNeg.isError, isTrue);
    });

    test('2. Payment exceeding outstanding balance is rejected', () async {
      // Current debt is ₹1,000.00 (100,000 paise). Attempting ₹1,500.00 (150,000 paise)
      final result = await creditRepository.recordCreditPayment(
        customerId: customerId,
        amountPaise: 150000,
      );
      expect(result.isError, isTrue);
      expect(result.failureOrNull?.message,
          contains('cannot exceed outstanding balance'));
    });

    test(
        '3. Valid partial payment atomically updates balance & creates ledger entry',
        () async {
      // Pay ₹400.00 (40,000 paise)
      final result = await creditRepository.recordCreditPayment(
        customerId: customerId,
        amountPaise: 40000,
        paymentMethod: 'UPI',
        notes: 'Ref #UPI12345',
      );
      expect(result.isSuccess, isTrue);

      // Verify updated customer debt balance in local Drift SQLite
      final customer = await localDataSource.getCustomerById(customerId);
      expect(customer?.currentDebtPaise,
          equals(BigInt.from(60000))); // ₹600.00 remaining

      // Verify credit transaction entry created
      final txns =
          await creditRepository.watchCreditTransactions(customerId).first;
      expect(txns.length, equals(1));
      expect(txns.first.type, equals('payment_received'));
      expect(txns.first.amountPaise, equals(BigInt.from(40000)));
      expect(txns.first.notes, contains('Via UPI'));
    });

    test('4. Full payment settles customer balance to zero', () async {
      // Pay full ₹1,000.00 (100,000 paise)
      final result = await creditRepository.recordCreditPayment(
        customerId: customerId,
        amountPaise: 100000,
        paymentMethod: 'Cash',
      );
      expect(result.isSuccess, isTrue);

      final customer = await localDataSource.getCustomerById(customerId);
      expect(
          customer?.currentDebtPaise, equals(BigInt.zero)); // Account Settled
    });

    test('5. Offline / Cloud failure prevents unverified balance mutation',
        () async {
      final offlineRemote = FailingCustomerRemoteDataSource();
      final offlineRepo = CreditRepositoryImpl(
        localDataSource: localDataSource,
        remoteDataSource: offlineRemote,
        shopId: shopA,
      );

      final result = await offlineRepo.recordCreditPayment(
        customerId: customerId,
        amountPaise: 50000,
      );

      expect(result.isError, isTrue);
      expect(result.failureOrNull?.message,
          contains('Internet connection required'));

      // Ensure customer debt balance remained unchanged at ₹1,000.00
      final customer = await localDataSource.getCustomerById(customerId);
      expect(customer?.currentDebtPaise, equals(BigInt.from(100000)));
    });
  });
}

class FakeCustomerRemoteDataSource extends CustomerRemoteDataSource {
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
      'transaction_id': 'mock-txn-uuid-101',
      'new_debt_paise': 60000,
    };
  }
}

class FailingCustomerRemoteDataSource extends CustomerRemoteDataSource {
  @override
  Future<Map<String, dynamic>> recordCreditTransactionAtomic({
    required String shopId,
    required String customerId,
    required int amountPaise,
    required String type,
    String? billId,
    String? notes,
  }) async {
    throw Exception('Network Offline');
  }
}
