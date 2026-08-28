import 'package:drift/drift.dart' as d;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_mobile/database/drift/database.dart';
import 'package:kirana_mobile/features/customers/data/datasources/customer_local_data_source.dart';
import 'package:kirana_mobile/features/customers/data/datasources/customer_remote_data_source.dart';
import 'package:kirana_mobile/features/customers/data/repositories/customer_repository_impl.dart';

void main() {
  late AppDatabase db;
  late CustomerLocalDataSource localDataSource;
  late CustomerRemoteDataSource remoteDataSource;
  late CustomerRepositoryImpl repository;
  const testShopId = 'shop_cust_test_1';

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    localDataSource = CustomerLocalDataSource(db);
    remoteDataSource = CustomerRemoteDataSource();
    repository = CustomerRepositoryImpl(
      localDataSource: localDataSource,
      remoteDataSource: remoteDataSource,
      shopId: testShopId,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('CustomerRepository Foundation Tests', () {
    test('Normalizes Indian phone numbers correctly', () {
      expect(CustomerRepositoryImpl.normalizePhone('+91 98765 43210'),
          '9876543210');
      expect(
          CustomerRepositoryImpl.normalizePhone('09876543210'), '9876543210');
      expect(CustomerRepositoryImpl.normalizePhone('9876543210'), '9876543210');
    });

    test('Creates customer locally with normalized phone number', () async {
      final result = await repository.createCustomer(
        name: ' Ramesh Kumar ',
        phone: '+91 98765-43210',
        email: ' ramesh@example.com ',
        address: ' Shop 12, Main St ',
        notes: ' VIP Customer ',
      );

      expect(result.isSuccess, isTrue);
      final customerId = result.dataOrNull!;
      expect(customerId, isNotEmpty);

      final fetched = await repository.getCustomerById(customerId);
      expect(fetched.isSuccess, isTrue);
      final customer = fetched.dataOrNull!;
      expect(customer, isNotNull);
      expect(customer.name, 'Ramesh Kumar');
      expect(customer.phone, '9876543210');
      expect(customer.email, 'ramesh@example.com');
      expect(customer.address, 'Shop 12, Main St');
      expect(customer.notes, 'VIP Customer');
      expect(customer.shopId, testShopId);
    });

    test(
        'Prevents creating duplicate customer with same phone number in same shop',
        () async {
      final res1 = await repository.createCustomer(
        name: 'Ramesh Kumar',
        phone: '9876543210',
      );
      expect(res1.isSuccess, isTrue);

      final res2 = await repository.createCustomer(
        name: 'Ramesh duplicate',
        phone: '9876543210',
      );
      expect(res2.isError, isTrue);
      expect(res2.failureOrNull?.message, contains('already exists'));
    });

    test('Updates customer details without corrupting customer ID reference',
        () async {
      // 1. Create customer
      final createRes = await repository.createCustomer(
        name: 'Sita Devi',
        phone: '9123456789',
      );
      final customerId = createRes.dataOrNull!;

      // 2. Create completed bill referencing Sita Devi's ID
      final now = DateTime.now();
      await db.into(db.billsTable).insert(
            BillsTableCompanion(
              id: const d.Value('bill_sita_1'),
              shopId: const d.Value(testShopId),
              billNumber: const d.Value('BILL-1001'),
              cashierId: const d.Value('cashier_1'),
              customerId: d.Value(customerId),
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

      // 3. Update Sita Devi's profile name and phone number
      final updateRes = await repository.updateCustomer(
        id: customerId,
        name: 'Sita Devi Gupta',
        phone: '9988776655',
        notes: 'Updated address',
      );
      expect(updateRes.isSuccess, isTrue);

      // 4. Verify Sita's customer profile is updated
      final updatedCust =
          (await repository.getCustomerById(customerId)).dataOrNull!;
      expect(updatedCust.name, 'Sita Devi Gupta');
      expect(updatedCust.phone, '9988776655');

      // 5. Verify historical bill is still linked to customerId
      final historicalBill = await (db.select(db.billsTable)
            ..where((t) => t.id.equals('bill_sita_1')))
          .getSingle();
      expect(historicalBill.customerId, customerId);
    });

    test('Fetches completed sales history for specific customer', () async {
      // 1. Create 2 customers
      final c1 =
          (await repository.createCustomer(name: 'Cust A', phone: '9000000001'))
              .dataOrNull!;
      final c2 =
          (await repository.createCustomer(name: 'Cust B', phone: '9000000002'))
              .dataOrNull!;

      final now = DateTime.now();

      // Bill 1 for Cust A (Paid)
      await db.into(db.billsTable).insert(
            BillsTableCompanion(
              id: const d.Value('b_1'),
              shopId: const d.Value(testShopId),
              billNumber: const d.Value('BILL-001'),
              cashierId: const d.Value('c_1'),
              customerId: d.Value(c1),
              subtotalPaise: d.Value(BigInt.from(12000)),
              taxTotalPaise: d.Value(BigInt.zero),
              discountPaise: d.Value(BigInt.zero),
              totalPaise: d.Value(BigInt.from(12000)),
              paymentStatus: const d.Value('paid'),
              isCancelled: const d.Value(false),
              createdAt: d.Value(now),
              updatedAt: d.Value(now),
            ),
          );

      // Bill 2 for Cust A (Cancelled - should not appear in sales history)
      await db.into(db.billsTable).insert(
            BillsTableCompanion(
              id: const d.Value('b_2'),
              shopId: const d.Value(testShopId),
              billNumber: const d.Value('BILL-002'),
              cashierId: const d.Value('c_1'),
              customerId: d.Value(c1),
              subtotalPaise: d.Value(BigInt.from(15000)),
              taxTotalPaise: d.Value(BigInt.zero),
              discountPaise: d.Value(BigInt.zero),
              totalPaise: d.Value(BigInt.from(15000)),
              paymentStatus: const d.Value('paid'),
              isCancelled: const d.Value(true),
              createdAt: d.Value(now),
              updatedAt: d.Value(now),
            ),
          );

      // Bill 3 for Cust B (Paid)
      await db.into(db.billsTable).insert(
            BillsTableCompanion(
              id: const d.Value('b_3'),
              shopId: const d.Value(testShopId),
              billNumber: const d.Value('BILL-003'),
              cashierId: const d.Value('c_1'),
              customerId: d.Value(c2),
              subtotalPaise: d.Value(BigInt.from(30000)),
              taxTotalPaise: d.Value(BigInt.zero),
              discountPaise: d.Value(BigInt.zero),
              totalPaise: d.Value(BigInt.from(30000)),
              paymentStatus: const d.Value('paid'),
              isCancelled: const d.Value(false),
              createdAt: d.Value(now),
              updatedAt: d.Value(now),
            ),
          );

      final salesHistoryA =
          (await repository.getCustomerSalesHistory(c1)).dataOrNull!;
      expect(salesHistoryA.length, 1);
      expect(salesHistoryA.first.id, 'b_1');
      expect(salesHistoryA.first.totalPaise, BigInt.from(12000));
    });
  });
}
