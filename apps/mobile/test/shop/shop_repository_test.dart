import 'dart:typed_data';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_mobile/core/storage/product_image_service.dart';
import 'package:kirana_mobile/database/drift/database.dart';
import 'package:kirana_mobile/features/shop/data/datasources/shop_local_data_source.dart';
import 'package:kirana_mobile/features/shop/data/datasources/shop_remote_data_source.dart';
import 'package:kirana_mobile/features/shop/data/repositories/shop_repository_impl.dart';
import 'package:kirana_mobile/features/shop/domain/models/shop_model.dart';

class MockShopRemoteDataSource implements ShopRemoteDataSource {
  @override
  Future<ShopModel> createShop({
    required String name,
    required String phone,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? gstin,
    String? fssaiLicense,
    String? upiId,
    String? logoUrl,
  }) async {
    return ShopModel(
      id: 'shop_mock_123',
      name: name,
      phone: phone,
      address: address,
      city: city,
      state: state ?? 'Karnataka',
      pincode: pincode,
      gstin: gstin,
      fssaiLicense: fssaiLicense,
      upiId: upiId,
      logoUrl: logoUrl,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<ShopModel> getShopDetails(String shopId) async {
    return ShopModel(
      id: shopId,
      name: 'Remote Store Name',
      phone: '9845012345',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<ShopModel> updateShopProfile({
    required String shopId,
    required String name,
    required String phone,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? gstin,
    String? fssaiLicense,
    String? upiId,
  }) async {
    return ShopModel(
      id: shopId,
      name: name,
      phone: phone,
      address: address,
      city: city,
      state: state ?? 'Karnataka',
      pincode: pincode,
      gstin: gstin,
      fssaiLicense: fssaiLicense,
      upiId: upiId,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<String> uploadShopLogo({
    required String shopId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    return 'https://supabase.co/storage/v1/object/public/products/$shopId/logo.jpg';
  }
}

void main() {
  late AppDatabase db;
  late ShopLocalDataSource localDataSource;
  late MockShopRemoteDataSource remoteDataSource;
  late ShopRepositoryImpl repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    localDataSource = ShopLocalDataSource(db);
    remoteDataSource = MockShopRemoteDataSource();
    repository = ShopRepositoryImpl(
      localDataSource: localDataSource,
      remoteDataSource: remoteDataSource,
      imageService: ProductImageService(),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('ShopRepository & Validation Tests', () {
    test('Reject empty store name with ValidationFailure', () async {
      final result = await repository.createShop(
        name: '   ',
        phone: '9876543210',
      );

      expect(result.isError, isTrue);
      expect(result.failureOrNull?.message, 'Shop name is required');
    });

    test('Reject invalid phone numbers with ValidationFailure', () async {
      final result = await repository.createShop(
        name: 'My Kirana Store',
        phone: '123', // Less than 10 digits
      );

      expect(result.isError, isTrue);
      expect(result.failureOrNull?.message, 'Valid 10-digit phone number is required');
    });

    test('Create shop persists to local database and returns valid ShopModel', () async {
      final result = await repository.createShop(
        name: 'Mahadev Provision Store',
        phone: '9876543210',
        city: 'Bangalore',
        state: 'Karnataka',
        pincode: '560001',
        gstin: '29AAAAA0000A1Z5',
        upiId: 'mahadev@okaxis',
      );

      expect(result.isSuccess, isTrue);
      final shop = result.dataOrNull!;
      expect(shop.id, 'shop_mock_123');
      expect(shop.name, 'Mahadev Provision Store');

      // Verify local caching
      final local = await localDataSource.getShopById('shop_mock_123');
      expect(local, isNotNull);
      expect(local!.name, 'Mahadev Provision Store');
      expect(local.gstin, '29AAAAA0000A1Z5');
      expect(local.upiId, 'mahadev@okaxis');
    });
  });
}
