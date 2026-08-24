import 'package:drift/drift.dart' as d;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_mobile/core/network/connectivity_service.dart';
import 'package:kirana_mobile/core/network/connectivity_status.dart';
import 'package:kirana_mobile/database/drift/database.dart';
import 'package:kirana_mobile/features/categories/data/datasources/category_local_data_source.dart';
import 'package:kirana_mobile/features/categories/data/datasources/category_remote_data_source.dart';
import 'package:kirana_mobile/features/categories/data/repositories/category_repository_impl.dart';
import 'package:kirana_mobile/features/categories/domain/models/category_model.dart';

class MockCategoryRemoteDataSource implements CategoryRemoteDataSource {
  final List<CategoryModel> remoteCategories = [];

  @override
  Future<List<CategoryModel>> fetchCategories(String shopId) async {
    return remoteCategories
        .where((c) => c.shopId == shopId && c.isActive)
        .toList();
  }

  @override
  Future<CategoryModel> createCategory(CategoryModel category) async {
    remoteCategories.add(category);
    return category;
  }

  @override
  Future<CategoryModel> updateCategory(CategoryModel category) async {
    final index = remoteCategories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      remoteCategories[index] = category;
    }
    return category;
  }

  @override
  Future<void> archiveCategory(String categoryId, String shopId) async {
    final index = remoteCategories.indexWhere((c) => c.id == categoryId);
    if (index != -1) {
      remoteCategories[index] =
          remoteCategories[index].copyWith(isActive: false);
    }
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
  late CategoryLocalDataSource localDataSource;
  late MockCategoryRemoteDataSource remoteDataSource;
  late MockConnectivityService connectivityService;
  late CategoryRepositoryImpl repository;
  const testShopId = 'shop_cat_test_1';

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    localDataSource = CategoryLocalDataSource(db);
    remoteDataSource = MockCategoryRemoteDataSource();
    connectivityService = MockConnectivityService();

    repository = CategoryRepositoryImpl(
      localDataSource: localDataSource,
      remoteDataSource: remoteDataSource,
      connectivityService: connectivityService,
      shopId: testShopId,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('CategoryRepository CRUD & Invariants Tests', () {
    test('Create category persists to Drift SQLite and enqueues sync mutation',
        () async {
      final result = await repository.createCategory(
        name: 'Atta, Rice & Grains',
        description: 'Flours and grains',
      );

      expect(result.isSuccess, isTrue);
      final cat = result.dataOrNull!;
      expect(cat.name, 'Atta, Rice & Grains');
      expect(cat.shopId, testShopId);
      expect(cat.isActive, isTrue);

      // Verify local Drift record
      final local = await localDataSource.getCategoryById(cat.id);
      expect(local, isNotNull);
      expect(local!.name, 'Atta, Rice & Grains');

      // Verify sync queue entry
      final pending = await db.syncDao.getPendingOperations();
      expect(pending.length, 1);
      expect(pending.first.entityType, 'category');
      expect(pending.first.operationType, 'INSERT');
      expect(pending.first.entityId, cat.id);
    });

    test('Rejects empty or whitespace category name', () async {
      final result = await repository.createCategory(name: '   ');
      expect(result.isError, isTrue);
      expect(result.failureOrNull?.message, 'Category name is required');
    });

    test('Prevents duplicate category names per shop (case-insensitive)',
        () async {
      // 1. Create first category
      final first = await repository.createCategory(name: 'Dairy & Milk');
      expect(first.isSuccess, isTrue);

      // 2. Try creating category with same name in different case
      final duplicate = await repository.createCategory(name: 'dairy & milk');
      expect(duplicate.isError, isTrue);
      expect(duplicate.failureOrNull?.message,
          'A category with the name "dairy & milk" already exists.');
    });

    test(
        'Update category details updates local record and enqueues UPDATE sync',
        () async {
      final createRes = await repository.createCategory(
        name: 'Snacks',
        description: 'Biscuits and chips',
      );
      final cat = createRes.dataOrNull!;

      final updateRes = await repository.updateCategory(
        id: cat.id,
        name: 'Snacks & Beverages',
        description: 'Biscuits, chips and soft drinks',
      );

      expect(updateRes.isSuccess, isTrue);
      final updated = updateRes.dataOrNull!;
      expect(updated.name, 'Snacks & Beverages');
      expect(updated.description, 'Biscuits, chips and soft drinks');

      final local = await localDataSource.getCategoryById(cat.id);
      expect(local!.name, 'Snacks & Beverages');

      final pending = await db.syncDao.getPendingOperations();
      expect(pending.any((op) => op.operationType == 'UPDATE'), isTrue);
    });

    test('Archive category with 0 products sets isActive to false', () async {
      final createRes = await repository.createCategory(name: 'Cosmetics');
      final cat = createRes.dataOrNull!;

      final archiveRes = await repository.archiveCategory(cat.id);
      expect(archiveRes.isSuccess, isTrue);

      final activeCats = await repository.getCategories();
      expect(activeCats.dataOrNull!.any((c) => c.id == cat.id), isFalse);
    });

    test('Prevents archiving category when active products are associated',
        () async {
      final createRes = await repository.createCategory(name: 'Edible Oils');
      final cat = createRes.dataOrNull!;

      // Insert product linked to this category
      await db.into(db.productsTable).insert(
            ProductsTableCompanion(
              id: const d.Value('prod_oil_1'),
              shopId: const d.Value(testShopId),
              categoryId: d.Value(cat.id),
              name: const d.Value('Fortune Sunflower Oil 1L'),
              mrpPaise: d.Value(BigInt.from(14000)),
              sellingPricePaise: d.Value(BigInt.from(13500)),
              currentStock: const d.Value(10.0),
              isActive: const d.Value(true),
              createdAt: d.Value(DateTime.now()),
              updatedAt: d.Value(DateTime.now()),
            ),
          );

      final archiveRes = await repository.archiveCategory(cat.id);
      expect(archiveRes.isError, isTrue);
      expect(archiveRes.failureOrNull?.message,
          contains('Cannot archive category with 1 active products'));
    });

    test(
        'Search categories performs fast, responsive local substring filtering',
        () async {
      await repository.createCategory(
        name: 'Atta & Flours',
        description: 'Wheat, maida, besan',
      );
      await repository.createCategory(
        name: 'Dairy',
        description: 'Milk, paneer, curd',
      );
      await repository.createCategory(
        name: 'Spices & Masala',
        description: 'Chilli, turmeric, garam masala',
      );

      final search1 = await repository.searchCategories('atta');
      expect(search1.dataOrNull!.length, 1);
      expect(search1.dataOrNull!.first.name, 'Atta & Flours');

      final searchByDesc = await repository.searchCategories('besan');
      expect(searchByDesc.dataOrNull!.length, 1);
      expect(searchByDesc.dataOrNull!.first.name, 'Atta & Flours');

      final searchNone = await repository.searchCategories('electronics');
      expect(searchNone.dataOrNull!.isEmpty, isTrue);
    });
  });
}
