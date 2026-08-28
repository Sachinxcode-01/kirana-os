import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_mobile/core/network/connectivity_service.dart';
import 'package:kirana_mobile/database/drift/database.dart';
import 'package:kirana_mobile/features/suppliers/data/datasources/supplier_local_data_source.dart';
import 'package:kirana_mobile/features/suppliers/data/datasources/supplier_remote_data_source.dart';
import 'package:kirana_mobile/features/suppliers/data/repositories/supplier_repository_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SupplierLocalDataSource localDataSource;
  late SupplierRemoteDataSource remoteDataSource;
  late SupplierRepositoryImpl repository;
  const testShopId = 'shop_purchase_test_1';

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    localDataSource = SupplierLocalDataSource(db);
    remoteDataSource = SupplierRemoteDataSource();
    repository = SupplierRepositoryImpl(
      localDataSource: localDataSource,
      remoteDataSource: remoteDataSource,
      connectivityService: ConnectivityService(),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('Supplier & Purchase Management Integration Tests', () {
    test(
        'Recording stock purchase entry automatically INCREASES product stock and updates supplier payable balance',
        () async {
      // 1. Create a product with initial stock 10.0
      await db.productsDao.upsertProduct(
        ProductsTableCompanion.insert(
          id: 'prod_pur_1',
          shopId: testShopId,
          name: 'Amul Milk 1L',
          mrpPaise: BigInt.from(6500),
          sellingPricePaise: BigInt.from(6500),
          purchasePricePaise: Value(BigInt.from(5500)),
          currentStock: Value(10.0),
          unit: const Value('pkt'),
        ),
      );

      // 2. Create supplier
      final suppRes = await repository.createSupplier(
        shopId: testShopId,
        name: 'Amul Dairy Distributor',
        phone: '9876543210',
      );
      expect(suppRes.isSuccess, isTrue);
      final supplier = suppRes.dataOrNull!;

      // 3. Record inward purchase of +25 pkts @ Rs 55.00
      final purRes = await repository.recordPurchase(
        shopId: testShopId,
        supplierId: supplier.id,
        supplierNameSnapshot: supplier.name,
        invoiceNumber: 'INV-AMUL-99',
        invoiceDate: DateTime.now(),
        lineItems: [
          (
            productId: 'prod_pur_1',
            productName: 'Amul Milk 1L',
            quantity: 25.0,
            purchasePricePaise: 5500,
            taxRate: 0.0,
          ),
        ],
      );

      expect(purRes.isSuccess, isTrue);
      final purchase = purRes.dataOrNull!;
      expect(purchase.totalPaise, 137500); // ₹1,375.00

      // 4. Verify product stock AUTOMATICALLY INCREASED from 10.0 -> 35.0
      final updatedProduct = await db.productsDao.getProductById('prod_pur_1');
      expect(updatedProduct, isNotNull);
      expect(updatedProduct!.currentStock, 35.0);

      // 5. Verify supplier payable balance INCREASED by ₹1,375.00 (137,500 paise)
      final updatedSupplier =
          await db.suppliersDao.getSupplierById(supplier.id);
      expect(updatedSupplier, isNotNull);
      expect(updatedSupplier!.currentBalancePaise, BigInt.from(137500));
    });

    test(
        'Recording supplier payment settlement reduces supplier payable balance',
        () async {
      // 1. Create supplier with initial payable debt ₹5,000.00 (500,000 paise)
      await db.suppliersDao.upsertSupplier(
        SuppliersTableCompanion.insert(
          id: 'supp_pay_1',
          shopId: testShopId,
          name: 'HUL Wholesaler',
          phone: '9123456789',
          currentBalancePaise: Value(BigInt.from(500000)),
        ),
      );

      // 2. Record payment paid of ₹2,000.00 (200,000 paise)
      final payRes = await repository.recordSupplierPayment(
        supplierId: 'supp_pay_1',
        shopId: testShopId,
        amountPaise: 200000,
        paymentMethod: 'Bank',
        notes: 'NEFT Transfer',
      );

      expect(payRes.isSuccess, isTrue);

      // 3. Verify supplier payable balance reduced from ₹5,000 to ₹3,000 (300,000 paise)
      final updatedSupp = await db.suppliersDao.getSupplierById('supp_pay_1');
      expect(updatedSupp, isNotNull);
      expect(updatedSupp!.currentBalancePaise, BigInt.from(300000));
    });
  });
}
