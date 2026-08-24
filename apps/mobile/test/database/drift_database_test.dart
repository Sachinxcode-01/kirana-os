import 'package:drift/drift.dart' as d;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_mobile/database/drift/database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    // In-memory isolated database instance for fast deterministic testing
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Drift SQLite Database & DAO Tests', () {
    const testShopId = 'shop_test_123';

    test('Insert and query products with indexed barcode lookup', () async {
      final now = DateTime.now();
      const productId = 'prod_001';
      const barcode = '8901030383742';

      // 1. Insert product
      await db.productsDao.upsertProduct(
        ProductsTableCompanion(
          id: const d.Value(productId),
          shopId: const d.Value(testShopId),
          name: const d.Value('Tata Tea Gold 250g'),
          mrpPaise: d.Value(BigInt.from(14000)),
          sellingPricePaise: d.Value(BigInt.from(13500)),
          purchasePricePaise: d.Value(BigInt.from(11000)),
          currentStock: const d.Value(25.0),
          taxRatePercentage: const d.Value(5.0),
          isActive: const d.Value(true),
          createdAt: d.Value(now),
          updatedAt: d.Value(now),
        ),
      );

      // 2. Link barcode
      await db.productsDao.linkBarcode(
        ProductBarcodesTableCompanion(
          id: const d.Value('bc_001'),
          shopId: const d.Value(testShopId),
          productId: const d.Value(productId),
          barcode: const d.Value(barcode),
          isPrimary: const d.Value(true),
          createdAt: d.Value(now),
        ),
      );

      // 3. Fast lookup
      final product =
          await db.productsDao.getProductByBarcode(testShopId, barcode);
      expect(product != null, isTrue);
      expect(product!.id, productId);
      expect(product.name, 'Tata Tea Gold 250g');
      expect(product.sellingPricePaise, BigInt.from(13500));
    });

    test('Customer Khata debt reduction and atomic sync queueing', () async {
      final now = DateTime.now();
      const customerId = 'cust_001';

      // 1. Insert customer with ₹1,000 outstanding debt (100000 paise)
      await db.customersDao.upsertCustomer(
        CustomersTableCompanion(
          id: const d.Value(customerId),
          shopId: const d.Value(testShopId),
          name: const d.Value('Ramesh Kumar'),
          phone: const d.Value('9876543210'),
          creditLimitPaise: d.Value(BigInt.from(500000)),
          currentDebtPaise: d.Value(BigInt.from(100000)),
          createdAt: d.Value(now),
          updatedAt: d.Value(now),
        ),
      );

      // 2. Record ₹400 payment received (40000 paise)
      await db.customersDao.recordCreditPayment(
        customerId: customerId,
        amountPaise: 40000,
        transactionRecord: CreditTransactionsTableCompanion(
          id: const d.Value('txn_001'),
          shopId: const d.Value(testShopId),
          customerId: const d.Value(customerId),
          amountPaise: d.Value(BigInt.from(40000)),
          type: const d.Value('payment_received'),
          recordedBy: const d.Value('cashier_1'),
          createdAt: d.Value(now),
        ),
        syncOp: SyncQueueTableCompanion(
          operationId: const d.Value('op_sync_001'),
          shopId: const d.Value(testShopId),
          entityType: const d.Value('credit_transaction'),
          entityId: const d.Value('txn_001'),
          operationType: const d.Value('CREATE'),
          payload: const d.Value('{"amount_paise":40000}'),
          createdAt: d.Value(now),
          status: const d.Value('PENDING'),
        ),
      );

      // 3. Verify customer debt reduced to ₹600 (60000 paise)
      final customer = await db.customersDao.getCustomerById(customerId);
      expect(customer != null, isTrue);
      expect(customer!.currentDebtPaise, BigInt.from(60000));

      // 4. Verify sync queue contains pending item
      final pending = await db.syncDao.getPendingOperations();
      expect(pending.length, 1);
      expect(pending.first.operationId, 'op_sync_001');
      expect(pending.first.status, 'PENDING');
    });

    test('Sync DAO state progression: PENDING -> IN_PROGRESS -> SYNCED',
        () async {
      final now = DateTime.now();
      const opId = 'op_test_lifecycle';

      await db.syncDao.enqueueOperation(
        SyncQueueTableCompanion(
          operationId: const d.Value(opId),
          shopId: const d.Value(testShopId),
          entityType: const d.Value('product'),
          entityId: const d.Value('p_123'),
          operationType: const d.Value('CREATE'),
          payload: const d.Value('{}'),
          createdAt: d.Value(now),
          status: const d.Value('PENDING'),
        ),
      );

      // 1. Initial pending
      var ops = await db.syncDao.getPendingOperations();
      expect(ops.any((o) => o.operationId == opId), isTrue);

      // 2. Mark in progress
      await db.syncDao.markOperationInProgress(opId);

      // 3. Mark synced
      await db.syncDao.markOperationSynced(opId);
      ops = await db.syncDao.getPendingOperations();
      expect(ops.any((o) => o.operationId == opId), isFalse);
    });

    test('Categories DAO upsert and retrieval', () async {
      final now = DateTime.now();
      await db.categoriesDao.upsertCategory(
        CategoriesTableCompanion(
          id: const d.Value('cat_dairy'),
          shopId: const d.Value(testShopId),
          name: const d.Value('Dairy & Milk'),
          sortOrder: const d.Value(1),
          createdAt: d.Value(now),
          updatedAt: d.Value(now),
        ),
      );

      final categories = await db.categoriesDao.getCategories(testShopId);
      expect(categories.length, 1);
      expect(categories.first.name, 'Dairy & Milk');
    });
  });
}
