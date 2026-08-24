import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_mobile/database/drift/database.dart';
import 'package:kirana_mobile/features/products/data/datasources/product_local_data_source.dart';
import 'package:kirana_mobile/features/products/data/datasources/product_remote_data_source.dart';
import 'package:kirana_mobile/features/products/data/repositories/product_repository_impl.dart';

void main() {
  late AppDatabase db;
  late ProductLocalDataSource localDataSource;
  late ProductRepositoryImpl repository;
  const testShopId = 'shop_test_repo_1';

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    localDataSource = ProductLocalDataSource(db);
    repository = ProductRepositoryImpl(
      localDataSource: localDataSource,
      remoteDataSource: ProductRemoteDataSource(),
      shopId: testShopId,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('ProductRepository Local-First Tests', () {
    test('Create product creates local record and sync queue entry atomically',
        () async {
      const barcode = '8901234567890';
      const name = 'Fortune Sunlite Sunflower Oil 1L';
      const mrp = 18000;
      const sp = 16500;

      final result = await repository.createProduct(
        name: name,
        mrpPaise: mrp,
        sellingPricePaise: sp,
        barcode: barcode,
        initialStock: 12.0,
        taxRate: 5.0,
      );

      expect(result.isSuccess, isTrue);

      // Verify product found immediately via local lookup
      final lookupResult = await repository.getProductByBarcode(barcode);
      expect(lookupResult.isSuccess, isTrue);
      final product = lookupResult.dataOrNull;
      expect(product, isNotNull);
      expect(product!.name, name);
      expect(product.sellingPricePaise, BigInt.from(sp));

      // Verify sync queue contains pending operation
      final pending = await db.syncDao.getPendingOperations();
      expect(pending.length, 1);
      expect(pending.first.entityType, 'product');
      expect(pending.first.operationType, 'CREATE');
    });
  });
}
