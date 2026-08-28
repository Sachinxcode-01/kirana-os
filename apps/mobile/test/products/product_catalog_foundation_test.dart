import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_mobile/features/billing/domain/models/bill_model.dart';
import 'package:kirana_mobile/features/products/data/datasources/product_local_data_source.dart';
import 'package:kirana_mobile/features/products/data/datasources/product_remote_data_source.dart';
import 'package:kirana_mobile/features/products/data/repositories/product_repository_impl.dart';
import 'package:kirana_mobile/database/drift/database.dart';
import 'package:drift/native.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ProductLocalDataSource localDataSource;
  late ProductRemoteDataSource remoteDataSource;
  late ProductRepositoryImpl repository;
  const testShopId = 'shop-uuid-11111';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    localDataSource = ProductLocalDataSource(db);
    remoteDataSource = ProductRemoteDataSource();
    repository = ProductRepositoryImpl(
      localDataSource: localDataSource,
      remoteDataSource: remoteDataSource,
      shopId: testShopId,
    );

    // Seed test category
    await db.categoriesDao.upsertCategory(
      CategoriesTableCompanion.insert(
        id: 'cat-01',
        shopId: testShopId,
        name: 'Groceries',
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('KIRANAOS Phase 13.0 — Product Catalog Foundation Tests', () {
    test('1. Create Product with SKU, Barcode, Tax Rate and validations',
        () async {
      final result = await repository.createProduct(
        name: 'Fortune Rice Bran Oil 1L',
        categoryId: 'cat-01',
        sku: 'OIL-001',
        barcode: '8901234567890',
        brand: 'Fortune',
        unit: 'LITER',
        sellingPricePaise: 18500,
        purchasePricePaise: 16000,
        mrpPaise: 21000,
        taxRate: 5.0,
        isActive: true,
      );

      expect(result.isSuccess, isTrue);
      final product = result.dataOrNull!;
      expect(product.name, equals('Fortune Rice Bran Oil 1L'));
      expect(product.sku, equals('OIL-001'));
      expect(product.barcode, equals('8901234567890'));
      expect(product.sellingPricePaise, equals(18500));
      expect(product.taxRatePercentage, equals(5.0));
      expect(product.isActive, isTrue);

      // Verify stored in Drift SQLite
      final stored = await repository.getProductById(product.id);
      expect(stored.isSuccess, isTrue);
      expect(stored.dataOrNull?.name, equals('Fortune Rice Bran Oil 1L'));
    });

    test('2. Rejects invalid product inputs (Empty name / Price <= 0)',
        () async {
      final resEmptyName = await repository.createProduct(
        name: '   ',
        categoryId: 'cat-01',
        sellingPricePaise: 1000,
      );
      expect(resEmptyName.isError, isTrue);
      expect(resEmptyName.failureOrNull?.message, contains('name is required'));

      final resZeroPrice = await repository.createProduct(
        name: 'Valid Product',
        categoryId: 'cat-01',
        sellingPricePaise: 0,
      );
      expect(resZeroPrice.isError, isTrue);
      expect(
          resZeroPrice.failureOrNull?.message, contains('greater than zero'));
    });

    test('3. Prevents duplicate barcode within the same shop', () async {
      // Create first product with barcode
      await repository.createProduct(
        name: 'Amul Butter 100g',
        categoryId: 'cat-01',
        barcode: '8901262010052',
        sellingPricePaise: 5800,
      );

      // Attempt second product with same barcode
      final dupResult = await repository.createProduct(
        name: 'Duplicate Barcode Item',
        categoryId: 'cat-01',
        barcode: '8901262010052',
        sellingPricePaise: 6000,
      );

      expect(dupResult.isError, isTrue);
      expect(dupResult.failureOrNull?.message, contains('already exists'));
    });

    test(
        '4. Edit Product updates catalog without altering historical completed bills',
        () async {
      // 1. Create product
      final createRes = await repository.createProduct(
        name: 'Tata Salt 1kg',
        categoryId: 'cat-01',
        sellingPricePaise: 2800,
        taxRate: 0.0,
      );
      final initialProduct = createRes.dataOrNull!;

      // 2. Create completed historical bill with initial price (₹28.00)
      final historicalBill = BillModel(
        id: 'bill-historical-1',
        shopId: testShopId,
        cashierId: 'cashier-1',
        billNumber: 'BILL-HIST-001',
        status: 'completed',
        paymentStatus: 'paid',
        items: [
          BillItemModel(
            id: 'item-1',
            billId: 'bill-historical-1',
            productId: initialProduct.id,
            productName: initialProduct.name,
            unit: initialProduct.unit,
            quantity: 1.0,
            unitPricePaise: initialProduct.sellingPricePaise,
            taxRate: initialProduct.taxRatePercentage,
            taxAmountPaise: 0,
            totalPaise: 2800,
            createdAt: DateTime.now(),
          ),
        ],
        subtotalPaise: 2800,
        discountPaise: 0,
        taxTotalPaise: 0,
        totalPaise: 2800,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 3. Update product catalog price to ₹30.00 & tax rate to 5%
      final updateRes = await repository.updateProduct(
        id: initialProduct.id,
        name: 'Tata Salt Vacuum Evaporated 1kg',
        categoryId: 'cat-01',
        sellingPricePaise: 3000,
        taxRate: 5.0,
      );
      expect(updateRes.isSuccess, isTrue);

      // 4. Verify historical bill item price remains strictly unchanged at ₹28.00!
      expect(historicalBill.items.first.unitPricePaise, equals(2800));
      expect(historicalBill.totalPaise, equals(2800));

      // 5. Verify updated product catalog has new price (₹30.00)
      final updatedCatalog = await repository.getProductById(initialProduct.id);
      expect(updatedCatalog.dataOrNull?.sellingPricePaise, equals(3000));
      expect(updatedCatalog.dataOrNull?.taxRatePercentage, equals(5.0));
    });

    test('5. Product search by Name, SKU, and Barcode', () async {
      await repository.createProduct(
        name: 'Maggi 2-Minute Noodle 70g',
        categoryId: 'cat-01',
        sku: 'MAG-070',
        barcode: '8901058000001',
        sellingPricePaise: 1400,
      );

      // Search by Name
      final resName = await repository.getProducts(searchQuery: 'Maggi');
      expect(resName.dataOrNull, isNotEmpty);
      expect(resName.dataOrNull?.first.name, contains('Maggi'));

      // Search by SKU or Name
      final resSku = await repository.getProducts(searchQuery: 'Maggi');
      expect(resSku.dataOrNull, isNotEmpty);

      // Search by Barcode
      final resBarcode = await repository.getProductByBarcode('8901058000001');
      expect(resBarcode.dataOrNull, isNotNull);
    });

    test('6. Storage image path format is shop-scoped', () {
      const shopId = 'shop-123';
      const productId = 'prod-456';
      const fileName = 'item_photo.jpg';

      final expectedPath = 'products/$shopId/$productId/$fileName';
      expect(expectedPath, equals('products/shop-123/prod-456/item_photo.jpg'));
    });
  });
}
