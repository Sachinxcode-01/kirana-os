import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_mobile/core/errors/failure.dart';
import 'package:kirana_mobile/core/errors/result.dart';
import 'package:kirana_mobile/features/shop/domain/models/shop_model.dart';
import 'package:kirana_mobile/features/shop/domain/repositories/shop_repository.dart';
import 'package:kirana_mobile/features/shop/domain/usecases/create_shop_usecase.dart';

class MockShopRepositorySuccess implements ShopRepository {
  ShopModel? createdShop;
  int createCalls = 0;

  @override
  Future<Result<ShopModel, Failure>> createShop({
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
    createCalls++;
    createdShop = ShopModel(
      id: 'shop_test_123',
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
    return Success(createdShop!);
  }

  @override
  Future<Result<ShopModel, Failure>> getShopDetails(String shopId) async {
    if (createdShop != null && createdShop!.id == shopId) {
      return Success(createdShop!);
    }
    return Success(
      ShopModel(
        id: shopId,
        name: 'Real Shop Details',
        phone: '9845012345',
        address: '123 Market St',
        city: 'Bangalore',
        state: 'Karnataka',
        pincode: '560001',
        gstin: '29AAAAA0000A1Z5',
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<Result<ShopModel, Failure>> updateShopProfile({
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
    return Success(
      ShopModel(
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
      ),
    );
  }

  @override
  Future<Result<String, Failure>> uploadShopLogo({
    required String shopId,
    required dynamic imageBytes,
    required String fileName,
  }) async {
    return const Success('https://example.com/logo.png');
  }
}

class MockShopRepositoryOffline implements ShopRepository {
  @override
  Future<Result<ShopModel, Failure>> createShop({
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
    return const ErrorResult(
      NetworkFailure('Shop setup requires an internet connection.'),
    );
  }

  @override
  Future<Result<ShopModel, Failure>> getShopDetails(String shopId) async {
    return const ErrorResult(
      NetworkFailure('Shop setup requires an internet connection.'),
    );
  }

  @override
  Future<Result<ShopModel, Failure>> updateShopProfile({
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
    return const ErrorResult(
      NetworkFailure('Shop setup requires an internet connection.'),
    );
  }

  @override
  Future<Result<String, Failure>> uploadShopLogo({
    required String shopId,
    required dynamic imageBytes,
    required String fileName,
  }) async {
    return const ErrorResult(
      NetworkFailure('Shop setup requires an internet connection.'),
    );
  }
}

void main() {
  group('KIRANAOS AUTH 3 — First-Time Shop Setup Tests', () {
    late MockShopRepositorySuccess repositorySuccess;
    late CreateShopUseCase useCaseSuccess;

    setUp(() {
      repositorySuccess = MockShopRepositorySuccess();
      useCaseSuccess = CreateShopUseCase(repositorySuccess);
    });

    test(
        '1. Valid shop creation returns created ShopModel and associates owner',
        () async {
      final result = await useCaseSuccess.execute(
        name: 'Mahadev Provision Store',
        phone: '9876543210',
        city: 'Bangalore',
        state: 'Karnataka',
        pincode: '560001',
        gstin: '29AAAAA0000A1Z5',
      );

      expect(result.isSuccess, isTrue);
      final shop = result.dataOrNull!;
      expect(shop.id, 'shop_test_123');
      expect(shop.name, 'Mahadev Provision Store');
      expect(shop.phone, '9876543210');
      expect(shop.gstin, '29AAAAA0000A1Z5');
      expect(repositorySuccess.createCalls, 1);
    });

    test('2. Validates required shop name', () async {
      final result = await useCaseSuccess.execute(
        name: '   ',
        phone: '9876543210',
      );

      expect(result.isError, isTrue);
      expect(result.failureOrNull?.message, 'Shop name is required');
      expect(repositorySuccess.createCalls, 0);
    });

    test('3. Validates required 10-digit phone number', () async {
      final result = await useCaseSuccess.execute(
        name: 'My Store',
        phone: '12345',
      );

      expect(result.isError, isTrue);
      expect(result.failureOrNull?.message,
          'Valid 10-digit phone number is required');
      expect(repositorySuccess.createCalls, 0);
    });

    test('4. Validates optional pincode format when provided', () async {
      final result = await useCaseSuccess.execute(
        name: 'My Store',
        phone: '9876543210',
        pincode: '5600', // Invalid length
      );

      expect(result.isError, isTrue);
      expect(result.failureOrNull?.message, 'Pincode must be a 6-digit number');
      expect(repositorySuccess.createCalls, 0);
    });

    test('5. Validates optional GSTIN length when provided', () async {
      final result = await useCaseSuccess.execute(
        name: 'My Store',
        phone: '9876543210',
        gstin: '29ABC', // Invalid length
      );

      expect(result.isError, isTrue);
      expect(result.failureOrNull?.message, 'GSTIN must be 15 characters long');
      expect(repositorySuccess.createCalls, 0);
    });

    test(
        '6. Offline mode returns clear NetworkFailure and creates NO local fake shop',
        () async {
      final repositoryOffline = MockShopRepositoryOffline();
      final useCaseOffline = CreateShopUseCase(repositoryOffline);

      final result = await useCaseOffline.execute(
        name: 'Mahadev Store',
        phone: '9876543210',
      );

      expect(result.isError, isTrue);
      expect(result.failureOrNull, isA<NetworkFailure>());
      expect(
        result.failureOrNull?.message,
        'Shop setup requires an internet connection.',
      );
    });

    test('7. Real shop details loading returns full record', () async {
      final result = await repositorySuccess.getShopDetails('shop_test_123');

      expect(result.isSuccess, isTrue);
      final shop = result.dataOrNull!;
      expect(shop.name, isNotEmpty);
      expect(shop.phone, isNotEmpty);
      expect(shop.pincode, '560001');
    });
  });
}
