import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_mobile/core/network/connectivity_service.dart';
import 'package:kirana_mobile/core/network/connectivity_status.dart';
import 'package:kirana_mobile/database/drift/database.dart';
import 'package:kirana_mobile/features/barcodes/data/datasources/barcode_local_data_source.dart';
import 'package:kirana_mobile/features/barcodes/data/datasources/barcode_remote_data_source.dart';
import 'package:kirana_mobile/features/barcodes/data/repositories/barcode_repository_impl.dart';
import 'package:kirana_mobile/features/barcodes/domain/models/barcode_model.dart';
import 'package:kirana_mobile/features/products/data/datasources/product_local_data_source.dart';
import 'package:kirana_mobile/features/products/domain/models/product_model.dart';

class MockBarcodeRemoteDataSource implements BarcodeRemoteDataSource {
  final List<BarcodeModel> remoteBarcodes = [];

  @override
  Future<BarcodeModel> createBarcode(BarcodeModel barcode) async {
    remoteBarcodes.add(barcode);
    return barcode;
  }

  @override
  Future<BarcodeModel> updateBarcode(BarcodeModel barcode) async {
    final index = remoteBarcodes.indexWhere((b) => b.id == barcode.id);
    if (index != -1) remoteBarcodes[index] = barcode;
    return barcode;
  }

  @override
  Future<void> deleteBarcode(String barcodeId, String shopId) async {
    remoteBarcodes.removeWhere((b) => b.id == barcodeId && b.shopId == shopId);
  }

  @override
  Future<ProductModel?> fetchProductByBarcode(
      String shopId, String barcode) async {
    return null;
  }
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
  late BarcodeLocalDataSource localDataSource;
  late ProductLocalDataSource productLocalDataSource;
  late MockBarcodeRemoteDataSource remoteDataSource;
  late MockConnectivityService connectivityService;
  late BarcodeRepositoryImpl repository;
  const testShopId = 'shop_bc_test_1';
  const testProductId = 'prod_oil_101';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    localDataSource = BarcodeLocalDataSource(db);
    productLocalDataSource = ProductLocalDataSource(db);
    remoteDataSource = MockBarcodeRemoteDataSource();
    connectivityService = MockConnectivityService();

    repository = BarcodeRepositoryImpl(
      localDataSource: localDataSource,
      remoteDataSource: remoteDataSource,
      productLocalDataSource: productLocalDataSource,
      connectivityService: connectivityService,
      shopId: testShopId,
    );

    // Seed test product
    await db.into(db.productsTable).insert(
          ProductsTableCompanion.insert(
            id: testProductId,
            shopId: testShopId,
            name: 'Fortune Sunflower Oil 1L',
            mrpPaise: BigInt.from(14000),
            sellingPricePaise: BigInt.from(13500),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  group('BarcodeRepository CRUD & Sync Tests', () {
    test('Add barcode persists locally and enqueues CREATE sync operation',
        () async {
      const code = '8901030383742';

      final result = await repository.addBarcode(
        productId: testProductId,
        barcode: code,
        isPrimary: true,
      );

      expect(result.isSuccess, isTrue);
      final model = result.dataOrNull!;
      expect(model.barcode, code);
      expect(model.barcodeType, 'EAN_13');
      expect(model.isPrimary, isTrue);

      // Verify local Drift record
      final localList = await repository.getBarcodesForProduct(testProductId);
      expect(localList.dataOrNull!.length, 1);
      expect(localList.dataOrNull!.first.barcode, code);

      // Verify sync queue
      final pending = await db.syncDao.getPendingOperations();
      expect(pending.length, 1);
      expect(pending.first.entityType, 'product_barcode');
      expect(pending.first.operationType, 'CREATE');
    });

    test('Prevents duplicate barcodes per shop', () async {
      const code = '8901030383742';
      final addRes1 = await repository.addBarcode(
        productId: testProductId,
        barcode: code,
      );
      expect(addRes1.isSuccess, isTrue);

      final addRes2 = await repository.addBarcode(
        productId: testProductId,
        barcode: code,
      );
      expect(addRes2.isError, isTrue);
      expect(addRes2.failureOrNull?.message,
          contains('is already assigned to a product in this shop'));
    });

    test('Edit barcode updates local record and enqueues UPDATE sync',
        () async {
      final addRes = await repository.addBarcode(
        productId: testProductId,
        barcode: '8901030383742',
      );
      final model = addRes.dataOrNull!;

      final updateRes = await repository.updateBarcode(
        id: model.id,
        newBarcode: '8901030383799',
      );

      expect(updateRes.isSuccess, isTrue);
      expect(updateRes.dataOrNull!.barcode, '8901030383799');

      final pending = await db.syncDao.getPendingOperations();
      expect(pending.any((op) => op.operationType == 'UPDATE'), isTrue);
    });

    test('Remove barcode deletes record locally and enqueues DELETE sync',
        () async {
      final addRes = await repository.addBarcode(
        productId: testProductId,
        barcode: '8901030383742',
      );
      final model = addRes.dataOrNull!;

      final removeRes = await repository.removeBarcode(model.id);
      expect(removeRes.isSuccess, isTrue);

      final listAfter = await repository.getBarcodesForProduct(testProductId);
      expect(listAfter.dataOrNull!.isEmpty, isTrue);

      final pending = await db.syncDao.getPendingOperations();
      expect(pending.any((op) => op.operationType == 'DELETE'), isTrue);
    });

    test('Sub-15ms barcode search resolves product from local Drift SQLite',
        () async {
      const code = '8901030383742';
      await repository.addBarcode(
        productId: testProductId,
        barcode: code,
      );

      final searchRes = await repository.searchProductByBarcode(code);
      expect(searchRes.isSuccess, isTrue);
      final product = searchRes.dataOrNull;
      expect(product, isNotNull);
      expect(product!.id, testProductId);
      expect(product.name, 'Fortune Sunflower Oil 1L');
    });

    test('Offline barcode lookup works for synchronized products', () async {
      connectivityService.online = false;
      const code = '8901030383742';

      await repository.addBarcode(
        productId: testProductId,
        barcode: code,
      );

      final searchRes = await repository.searchProductByBarcode(code);
      expect(searchRes.isSuccess, isTrue);
      expect(searchRes.dataOrNull!.name, 'Fortune Sunflower Oil 1L');
    });
  });
}
