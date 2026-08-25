import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_mobile/database/drift/database.dart';
import 'package:kirana_mobile/features/products/domain/models/product_model.dart';
import 'package:kirana_mobile/features/products/data/repositories/product_repository_impl.dart';
import 'package:kirana_mobile/features/products/data/datasources/product_local_data_source.dart';
import 'package:kirana_mobile/features/products/data/datasources/product_remote_data_source.dart';
import 'package:kirana_mobile/core/errors/failure.dart';

class FakeProductRemoteDataSource implements ProductRemoteDataSource {
  @override
  Future<List<Map<String, dynamic>>> fetchProducts(String shopId) async => [];

  @override
  Future<ProductModel> createProduct(ProductModel product) async => product;

  @override
  Future<ProductModel> updateProduct(ProductModel product) async => product;

  @override
  Future<void> archiveProduct(String productId, String shopId) async {}

  @override
  Future<void> pushProduct(Map<String, dynamic> payload) async {}

  @override
  Future<String> uploadProductImage({
    required String shopId,
    required String productId,
    required List<int> imageBytes,
    required String fileName,
  }) async {
    return 'https://example.com/storage/products/$shopId/$productId/$fileName';
  }

  @override
  Future<void> deleteProductImage({
    required String shopId,
    required String productId,
    required String storagePath,
  }) async {}
}

void main() {
  late AppDatabase db;
  late ProductLocalDataSource localDataSource;
  late FakeProductRemoteDataSource remoteDataSource;
  late ProductRepositoryImpl repository;

  final testProduct = ProductModel(
    id: 'prod-123',
    shopId: 'shop-456',
    name: 'Rice Bag 10kg',
    categoryId: 'cat-789',
    sellingPricePaise: 45000,
    mrpPaise: 50000,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    imageUrl:
        'https://example.com/storage/products/shop-456/prod-123/primary.jpg',
  );

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    localDataSource = ProductLocalDataSource(db);
    remoteDataSource = FakeProductRemoteDataSource();
    repository = ProductRepositoryImpl(
      localDataSource: localDataSource,
      remoteDataSource: remoteDataSource,
      shopId: 'shop-456',
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('ProductModel Image Field Tests', () {
    test('serializes imageUrl to JSON correctly', () {
      final json = testProduct.toJson();
      expect(json['image_url'],
          'https://example.com/storage/products/shop-456/prod-123/primary.jpg');
    });

    test('deserializes imageUrl from JSON correctly', () {
      final json = {
        'id': 'prod-123',
        'shop_id': 'shop-456',
        'name': 'Rice Bag 10kg',
        'category_id': 'cat-789',
        'selling_price_paise': 45000,
        'mrp_paise': 50000,
        'image_url':
            'https://example.com/storage/products/shop-456/prod-123/primary.jpg',
        'created_at': '2026-01-01T00:00:00.000',
        'updated_at': '2026-01-01T00:00:00.000',
      };
      final model = ProductModel.fromJson(json);
      expect(model.imageUrl,
          'https://example.com/storage/products/shop-456/prod-123/primary.jpg');
    });

    test('copyWith updates imageUrl', () {
      final updated =
          testProduct.copyWith(imageUrl: 'https://example.com/new.jpg');
      expect(updated.imageUrl, 'https://example.com/new.jpg');
    });
  });

  group('Product Repository Image Validation Tests', () {
    test('returns ValidationFailure when uploading empty image bytes',
        () async {
      final result = await repository.uploadProductImage(
        productId: 'prod-123',
        imageBytes: [],
        fileName: 'test.jpg',
      );
      expect(result.isError, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(result.failureOrNull?.message, contains('cannot be empty'));
    });

    test('returns ValidationFailure when image exceeds 5MB', () async {
      final oversizedBytes = List<int>.filled(5 * 1024 * 1024 + 1, 0);
      final result = await repository.uploadProductImage(
        productId: 'prod-123',
        imageBytes: oversizedBytes,
        fileName: 'large.jpg',
      );
      expect(result.isError, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(result.failureOrNull?.message,
          contains('exceeds maximum limit of 5MB'));
    });
  });
}
