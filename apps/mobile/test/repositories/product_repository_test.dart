import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_mobile/core/network/connectivity_service.dart';
import 'package:kirana_mobile/core/network/connectivity_status.dart';
import 'package:kirana_mobile/database/drift/database.dart';
import 'package:kirana_mobile/features/categories/data/datasources/category_local_data_source.dart';
import 'package:kirana_mobile/features/categories/domain/models/category_model.dart';
import 'package:kirana_mobile/features/products/data/datasources/product_local_data_source.dart';
import 'package:kirana_mobile/features/products/data/datasources/product_remote_data_source.dart';
import 'package:kirana_mobile/features/products/data/repositories/product_repository_impl.dart';
import 'package:kirana_mobile/features/products/domain/models/product_model.dart';

class MockProductRemoteDataSource implements ProductRemoteDataSource {
  final List<ProductModel> remoteProducts = [];

  @override
  Future<List<Map<String, dynamic>>> fetchProducts(String shopId) async {
    return remoteProducts
        .where((p) => p.shopId == shopId && p.isActive)
        .map((p) => p.toJson())
        .toList();
  }

  @override
  Future<ProductModel> createProduct(ProductModel product) async {
    remoteProducts.add(product);
    return product;
  }

  @override
  Future<ProductModel> updateProduct(ProductModel product) async {
    final index = remoteProducts.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      remoteProducts[index] = product;
    }
    return product;
  }

  @override
  Future<void> archiveProduct(String productId, String shopId) async {
    final index = remoteProducts.indexWhere((p) => p.id == productId);
    if (index != -1) {
      remoteProducts[index] = remoteProducts[index].copyWith(isActive: false);
    }
  }

  @override
  Future<void> pushProduct(Map<String, dynamic> payload) async {}
}

class MockConnectivityService implements ConnectivityService {
  bool online = true;

  @override
  Future<bool> isOnline() async => online;

  @override
  ConnectivityStatus get currentStatus =>
      online ? ConnectivityStatus.online : ConnectivityStatus.offline;

  @override
  Stream<ConnectivityStatus> get statusStream => Stream.value(currentStatus);

  @override
  Future<ConnectivityStatus> checkConnectivity() async => currentStatus;

  @override
  void updateSyncStatus(ConnectivityStatus status) {
    online = status == ConnectivityStatus.online;
  }

  @override
  void dispose() {}
}

void main() {
  late AppDatabase db;
  late ProductLocalDataSource localDataSource;
  late CategoryLocalDataSource categoryLocalDataSource;
  late MockProductRemoteDataSource remoteDataSource;
  late MockConnectivityService connectivityService;
  late ProductRepositoryImpl repository;
  const testShopId = 'shop_test_repo_1';
  const testCatId = 'cat_grains_1';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    localDataSource = ProductLocalDataSource(db);
    categoryLocalDataSource = CategoryLocalDataSource(db);
    remoteDataSource = MockProductRemoteDataSource();
    connectivityService = MockConnectivityService();

    repository = ProductRepositoryImpl(
      localDataSource: localDataSource,
      remoteDataSource: remoteDataSource,
      connectivityService: connectivityService,
      shopId: testShopId,
    );

    // Seed test category
    await categoryLocalDataSource.saveCategory(
      CategoryModel(
        id: testCatId,
        shopId: testShopId,
        name: 'Atta & Flours',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('ProductRepository Local-First & Invariant Tests', () {
    test('Create product creates local record and sync queue entry atomically',
        () async {
      const barcode = '8901234567890';
      const name = 'Fortune Sunlite Sunflower Oil 1L';
      const mrp = 18000;
      const sp = 16500;

      final result = await repository.createProduct(
        name: name,
        categoryId: testCatId,
        brand: 'Fortune',
        unit: 'LITER',
        mrpPaise: mrp,
        sellingPricePaise: sp,
        barcode: barcode,
        initialStock: 12.0,
        taxRate: 5.0,
      );

      expect(result.isSuccess, isTrue);
      final product = result.dataOrNull!;
      expect(product.name, name);
      expect(product.brand, 'Fortune');
      expect(product.unit, 'LITER');
      expect(product.sellingPricePaise, sp);
      expect(product.mrpPaise, mrp);

      // Verify product found immediately via local barcode lookup
      final lookupResult = await repository.getProductByBarcode(barcode);
      expect(lookupResult.isSuccess, isTrue);
      expect(lookupResult.dataOrNull, isNotNull);
      expect(lookupResult.dataOrNull!.name, name);

      // Verify sync queue contains pending operation
      final pending = await db.syncDao.getPendingOperations();
      expect(pending.length, 1);
      expect(pending.first.entityType, 'product');
      expect(pending.first.operationType, 'CREATE');
    });

    test('Rejects empty product name', () async {
      final result = await repository.createProduct(
        name: '   ',
        categoryId: testCatId,
        sellingPricePaise: 10000,
      );
      expect(result.isError, isTrue);
      expect(result.failureOrNull?.message, 'Product name is required');
    });

    test('Rejects invalid or non-positive selling price', () async {
      final result = await repository.createProduct(
        name: 'Salt 1kg',
        categoryId: testCatId,
        sellingPricePaise: 0,
      );
      expect(result.isError, isTrue);
      expect(result.failureOrNull?.message,
          'Selling price must be greater than zero');
    });

    test('Rejects negative purchase price', () async {
      final result = await repository.createProduct(
        name: 'Sugar 1kg',
        categoryId: testCatId,
        sellingPricePaise: 4500,
        purchasePricePaise: -100,
      );
      expect(result.isError, isTrue);
      expect(
          result.failureOrNull?.message, 'Purchase price cannot be negative');
    });

    test('Prevents duplicate product names in same shop (case-insensitive)',
        () async {
      final res1 = await repository.createProduct(
        name: 'Tata Tea Gold 500g',
        categoryId: testCatId,
        sellingPricePaise: 32000,
      );
      expect(res1.isSuccess, isTrue);

      final res2 = await repository.createProduct(
        name: 'tata tea gold 500g',
        categoryId: testCatId,
        sellingPricePaise: 32000,
      );
      expect(res2.isError, isTrue);
      expect(res2.failureOrNull?.message,
          'A product with the name "tata tea gold 500g" already exists.');
    });

    test('Update product modifies local record and enqueues UPDATE sync',
        () async {
      final createRes = await repository.createProduct(
        name: 'Aashirvaad Atta 5kg',
        categoryId: testCatId,
        brand: 'Aashirvaad',
        unit: 'KG',
        sellingPricePaise: 24000,
        purchasePricePaise: 21000,
      );
      final product = createRes.dataOrNull!;

      final updateRes = await repository.updateProduct(
        id: product.id,
        name: 'Aashirvaad Superior MP Atta 5kg',
        categoryId: testCatId,
        brand: 'ITC Aashirvaad',
        unit: 'KG',
        sellingPricePaise: 25000,
        purchasePricePaise: 22000,
      );

      expect(updateRes.isSuccess, isTrue);
      final updated = updateRes.dataOrNull!;
      expect(updated.name, 'Aashirvaad Superior MP Atta 5kg');
      expect(updated.brand, 'ITC Aashirvaad');
      expect(updated.sellingPricePaise, 25000);

      // Verify local record
      final local = await localDataSource.getProductById(product.id);
      expect(local!.name, 'Aashirvaad Superior MP Atta 5kg');

      // Verify sync queue UPDATE
      final pending = await db.syncDao.getPendingOperations();
      expect(pending.any((op) => op.operationType == 'UPDATE'), isTrue);
    });

    test('Archive product sets isActive to false and enqueues DELETE sync',
        () async {
      final createRes = await repository.createProduct(
        name: 'Biscuits Pack',
        categoryId: testCatId,
        sellingPricePaise: 2000,
      );
      final product = createRes.dataOrNull!;

      final archiveRes = await repository.archiveProduct(product.id);
      expect(archiveRes.isSuccess, isTrue);

      final activeList = await repository.getProducts();
      expect(activeList.dataOrNull!.any((p) => p.id == product.id), isFalse);

      final pending = await db.syncDao.getPendingOperations();
      expect(pending.any((op) => op.operationType == 'DELETE'), isTrue);
    });

    test('Filter products by category and search term locally', () async {
      final cat2 = 'cat_dairy_2';
      await categoryLocalDataSource.saveCategory(
        CategoryModel(
          id: cat2,
          shopId: testShopId,
          name: 'Dairy',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await repository.createProduct(
        name: 'Amul Butter 100g',
        categoryId: cat2,
        brand: 'Amul',
        sellingPricePaise: 5600,
      );
      await repository.createProduct(
        name: 'Amul Taaza Milk 500ml',
        categoryId: cat2,
        brand: 'Amul',
        sellingPricePaise: 2700,
      );
      await repository.createProduct(
        name: 'Pillsbury Chakki Atta 5kg',
        categoryId: testCatId,
        brand: 'Pillsbury',
        sellingPricePaise: 23500,
      );

      // Search by brand / name
      final searchAmul = await repository.getProducts(searchQuery: 'amul');
      expect(searchAmul.dataOrNull!.length, 2);

      // Filter by Category
      final filterDairy = await repository.getProducts(categoryId: cat2);
      expect(filterDairy.dataOrNull!.length, 2);

      final filterGrains = await repository.getProducts(categoryId: testCatId);
      expect(filterGrains.dataOrNull!.length, 1);
      expect(filterGrains.dataOrNull!.first.name, 'Pillsbury Chakki Atta 5kg');
    });
  });
}
