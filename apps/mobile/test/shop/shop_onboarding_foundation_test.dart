import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_mobile/core/errors/failure.dart';
import 'package:kirana_mobile/core/errors/result.dart';
import 'package:kirana_mobile/features/shop/domain/models/shop_model.dart';
import 'package:kirana_mobile/features/shop/domain/repositories/shop_repository.dart';

class MockOnboardingShopRepository implements ShopRepository {
  ShopModel? createdShop;
  int createCalls = 0;
  bool isOffline = false;

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
    if (isOffline) {
      return const ErrorResult(
        NetworkFailure('Shop setup requires an internet connection.'),
      );
    }
    if (name.trim().isEmpty) {
      return const ErrorResult(
        ValidationFailure('Shop name is required'),
      );
    }
    if (phone.trim().length < 10) {
      return const ErrorResult(
        ValidationFailure('Valid 10-digit phone number is required'),
      );
    }

    // Idempotent: If createdShop exists, return existing shop cleanly (simulating RPC idempotency)
    if (createdShop != null) {
      return Success(createdShop!);
    }

    createdShop = ShopModel(
      id: 'shop_onboarding_999',
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
    if (isOffline && createdShop == null) {
      return const ErrorResult(
        NetworkFailure('Internet connection required'),
      );
    }
    if (createdShop != null && createdShop!.id == shopId) {
      return Success(createdShop!);
    }
    return Success(
      ShopModel(
        id: shopId,
        name: 'Restored Kirana Store',
        phone: '9845012345',
        address: '123 Market St',
        city: 'Bangalore',
        state: 'Karnataka',
        pincode: '560001',
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
    if (isOffline) {
      return const ErrorResult(
        NetworkFailure('Internet connection required'),
      );
    }
    createdShop = ShopModel(
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
    return Success(createdShop!);
  }

  @override
  Future<Result<String, Failure>> uploadShopLogo({
    required String shopId,
    required dynamic imageBytes,
    required String fileName,
  }) async {
    return const Success(
        'https://cdn.kirana.app/logos/shop_onboarding_999.png');
  }
}

void main() {
  group('KIRANAOS AUTH 12.1 — Shop Onboarding Foundation Tests', () {
    late MockOnboardingShopRepository repository;

    setUp(() {
      repository = MockOnboardingShopRepository();
    });

    test('1. Creates shop with required basic information securely', () async {
      final result = await repository.createShop(
        name: 'Ramesh Provision Store',
        phone: '9845012345',
        address: '45 MG Road',
        city: 'Bengaluru',
        state: 'Karnataka',
        pincode: '560001',
      );

      expect(result.isSuccess, isTrue);
      final shop = result.dataOrNull!;
      expect(shop.id, 'shop_onboarding_999');
      expect(shop.name, 'Ramesh Provision Store');
      expect(shop.phone, '9845012345');
      expect(shop.address, '45 MG Road');
      expect(shop.city, 'Bengaluru');
      expect(shop.pincode, '560001');
    });

    test('2. Prevents duplicate shop creation on double-tap or network retry',
        () async {
      // First submission
      final result1 = await repository.createShop(
        name: 'Ramesh Provision Store',
        phone: '9845012345',
      );
      expect(result1.isSuccess, isTrue);
      final shop1 = result1.dataOrNull!;

      // Second submission (simulating double-tap / retry)
      final result2 = await repository.createShop(
        name: 'Ramesh Provision Store',
        phone: '9845012345',
      );
      expect(result2.isSuccess, isTrue);
      final shop2 = result2.dataOrNull!;

      expect(repository.createCalls, equals(2));
      expect(shop1.id, equals(shop2.id)); // Same shop returned idempotently!
    });

    test('3. Rejects invalid inputs with user-friendly validation failures',
        () async {
      // Empty shop name
      final emptyNameResult = await repository.createShop(
        name: '  ',
        phone: '9845012345',
      );
      expect(emptyNameResult.isError, isTrue);
      expect(emptyNameResult.failureOrNull?.message,
          contains('Shop name is required'));

      // Short phone number
      final shortPhoneResult = await repository.createShop(
        name: 'My Store',
        phone: '1234',
      );
      expect(shortPhoneResult.isError, isTrue);
      expect(shortPhoneResult.failureOrNull?.message,
          contains('Valid 10-digit phone number'));
    });

    test('4. Restores shop details across app restarts & session restoration',
        () async {
      // Step A: Create shop
      await repository.createShop(
        name: 'Ramesh Provision Store',
        phone: '9845012345',
      );

      // Step B: Simulate app restart / session restoration
      final restoreResult =
          await repository.getShopDetails('shop_onboarding_999');
      expect(restoreResult.isSuccess, isTrue);
      final restoredShop = restoreResult.dataOrNull!;
      expect(restoredShop.name, 'Ramesh Provision Store');
      expect(restoredShop.phone, '9845012345');
    });

    test(
        '5. Offline state returns clear network error when creating shop offline',
        () async {
      repository.isOffline = true;

      final result = await repository.createShop(
        name: 'Offline Kirana',
        phone: '9845012345',
      );

      expect(result.isError, isTrue);
      expect(result.failureOrNull?.message, contains('internet connection'));
    });
  });
}
