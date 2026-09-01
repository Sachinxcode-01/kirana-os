import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_mobile/database/drift/database.dart';
import 'package:kirana_mobile/features/credit/data/repositories/credit_repository_impl.dart';
import 'package:kirana_mobile/features/customers/data/datasources/customer_local_data_source.dart';
import 'package:kirana_mobile/features/customers/data/datasources/customer_remote_data_source.dart';

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
      'transaction_id': 'mock-txn-credit-test-101',
      'new_debt_paise': 150000,
    };
  }
}

void main() {
  late AppDatabase db;
  late CustomerLocalDataSource localDataSource;
  late CustomerRemoteDataSource remoteDataSource;
  late CreditRepositoryImpl repository;
  const testShopId = 'shop_credit_test_1';

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    localDataSource = CustomerLocalDataSource(db);
    remoteDataSource = FakeCustomerRemoteDataSource();
    repository = CreditRepositoryImpl(
      localDataSource: localDataSource,
      remoteDataSource: remoteDataSource,
      shopId: testShopId,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('CreditRepository Udhaar & Khata Tests', () {
    test('Recording Udhaar credit sale increases customer current debt',
        () async {
      // 1. Create customer with 0 debt
      await db.customersDao.upsertCustomer(
        CustomersTableCompanion.insert(
          id: 'cust_credit_1',
          shopId: testShopId,
          name: 'Ramesh Gupta',
          phone: '9876543210',
          creditLimitPaise: Value(BigInt.from(500000)), // ₹5,000.00
          currentDebtPaise: Value(BigInt.zero),
        ),
      );

      // 2. Record Udhaar credit sale of ₹1,500.00 (150,000 paise)
      final res = await repository.recordCreditSale(
        customerId: 'cust_credit_1',
        amountPaise: 150000,
        billId: 'bill_udhaar_101',
        notes: 'POS Udhaar Sale #BILL-101',
      );

      expect(res.isSuccess, isTrue);

      // 3. Verify customer debt updated to 150,000 paise
      final updatedCust =
          await db.customersDao.getCustomerById('cust_credit_1');
      expect(updatedCust, isNotNull);
      expect(updatedCust!.currentDebtPaise, BigInt.from(150000));

      // 4. Verify transaction logged
      final txns = await db.customersDao
          .watchCreditTransactions(testShopId, 'cust_credit_1')
          .first;
      expect(txns.length, 1);
      expect(txns.first.amountPaise, BigInt.from(150000));
      expect(txns.first.type, 'credit_given');
      expect(txns.first.billId, 'bill_udhaar_101');
    });

    test('Recording Khata debt payment decreases customer current debt',
        () async {
      // 1. Create customer with ₹2,000.00 (200,000 paise) initial debt
      await db.customersDao.upsertCustomer(
        CustomersTableCompanion.insert(
          id: 'cust_credit_2',
          shopId: testShopId,
          name: 'Suresh Kumar',
          phone: '9876543211',
          creditLimitPaise: Value(BigInt.from(500000)),
          currentDebtPaise: Value(BigInt.from(200000)),
        ),
      );

      // 2. Record payment received of ₹500.00 (50,000 paise)
      final res = await repository.recordCreditPayment(
        customerId: 'cust_credit_2',
        amountPaise: 50000,
        paymentMethod: 'UPI',
        notes: 'GPay payment',
      );

      expect(res.isSuccess, isTrue);

      // 3. Verify customer debt reduced to ₹1,500.00 (150,000 paise)
      final updatedCust =
          await db.customersDao.getCustomerById('cust_credit_2');
      expect(updatedCust, isNotNull);
      expect(updatedCust!.currentDebtPaise, BigInt.from(150000));

      // 4. Verify transaction logged
      final txns = await db.customersDao
          .watchCreditTransactions(testShopId, 'cust_credit_2')
          .first;
      expect(txns.length, 1);
      expect(txns.first.amountPaise, BigInt.from(50000));
      expect(txns.first.type, 'payment_received');
    });

    test('Calculates total shop outstanding Udhaar summary correctly',
        () async {
      // 1. Insert Customer A with ₹1,250 debt
      await db.customersDao.upsertCustomer(
        CustomersTableCompanion.insert(
          id: 'cust_sum_1',
          shopId: testShopId,
          name: 'Cust A',
          phone: '9000000001',
          currentDebtPaise: Value(BigInt.from(125000)),
        ),
      );

      // 2. Insert Customer B with ₹3,400 debt
      await db.customersDao.upsertCustomer(
        CustomersTableCompanion.insert(
          id: 'cust_sum_2',
          shopId: testShopId,
          name: 'Cust B',
          phone: '9000000002',
          currentDebtPaise: Value(BigInt.from(340000)),
        ),
      );

      // 3. Insert Customer C with ₹0 debt
      await db.customersDao.upsertCustomer(
        CustomersTableCompanion.insert(
          id: 'cust_sum_3',
          shopId: testShopId,
          name: 'Cust C',
          phone: '9000000003',
          currentDebtPaise: Value(BigInt.zero),
        ),
      );

      final summaryRes = await repository.getShopCreditSummary();
      expect(summaryRes.isSuccess, isTrue);
      final summary = summaryRes.dataOrNull!;
      expect(summary.totalDebtPaise, 465000); // ₹4,650.00
      expect(summary.indebtedCount, 2);
    });
  });
}
