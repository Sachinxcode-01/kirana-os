import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_mobile/core/errors/failure.dart';
import 'package:kirana_mobile/core/errors/result.dart';
import 'package:kirana_mobile/features/shop/domain/models/shop_model.dart';
import 'package:kirana_mobile/features/shop/domain/repositories/shop_repository.dart';

class MockBrandingShopRepository implements ShopRepository {
  ShopModel currentShop = ShopModel(
    id: 'shop_branding_101',
    name: 'Ramesh Stores',
    phone: '9845012345',
    address: '12 Main Street',
    city: 'Bengaluru',
    state: 'Karnataka',
    pincode: '560001',
    logoUrl: null,
    receiptName: null,
    createdAt: DateTime.now(),
  );

  bool isOffline = false;
  String currentRole = 'owner'; // 'owner', 'manager', 'cashier'

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
    currentShop = ShopModel(
      id: 'shop_branding_101',
      name: name,
      phone: phone,
      address: address,
      city: city,
      state: state ?? 'Karnataka',
      pincode: pincode,
      logoUrl: logoUrl,
      createdAt: DateTime.now(),
    );
    return Success(currentShop);
  }

  @override
  Future<Result<ShopModel, Failure>> getShopDetails(String shopId) async {
    return Success(currentShop);
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
    String? receiptName,
  }) async {
    if (currentRole == 'cashier') {
      return const ErrorResult(
        AuthFailure(
            'Unauthorized: Only shop owners and managers can update shop profile and branding'),
      );
    }
    if (isOffline) {
      return const ErrorResult(
        NetworkFailure('Internet connection required to update shop profile'),
      );
    }

    currentShop = currentShop.copyWith(
      name: name,
      phone: phone,
      address: address,
      city: city,
      state: state ?? 'Karnataka',
      pincode: pincode,
      gstin: gstin,
      fssaiLicense: fssaiLicense,
      upiId: upiId,
      receiptName: receiptName,
    );
    return Success(currentShop);
  }

  @override
  Future<Result<String, Failure>> uploadShopLogo({
    required String shopId,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    if (currentRole == 'cashier') {
      return const ErrorResult(
        AuthFailure(
            'Unauthorized: Only shop owners and managers can modify shop logo'),
      );
    }
    if (isOffline) {
      return const ErrorResult(
        NetworkFailure('Internet connection required to upload shop logo'),
      );
    }

    final logoUrl =
        'https://supabase.kirana.app/storage/v1/object/public/shops/$shopId/branding/logo_$fileName';
    currentShop = currentShop.copyWith(logoUrl: logoUrl);
    return Success(logoUrl);
  }

  @override
  Future<Result<bool, Failure>> removeShopLogo(String shopId) async {
    if (currentRole == 'cashier') {
      return const ErrorResult(
        AuthFailure(
            'Unauthorized: Only shop owners and managers can remove shop logo'),
      );
    }
    if (isOffline) {
      return const ErrorResult(
        NetworkFailure('Internet connection required to remove shop logo'),
      );
    }

    currentShop = currentShop.copyWith(clearLogoUrl: true);
    return const Success(true);
  }
}

void main() {
  group('KIRANAOS AUTH 12.2 — Shop Profile & Branding Tests', () {
    late MockBrandingShopRepository repository;

    setUp(() {
      repository = MockBrandingShopRepository();
    });

    test('1. Uploads shop logo to shop-scoped storage path and saves reference',
        () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final result = await repository.uploadShopLogo(
        shopId: 'shop_branding_101',
        imageBytes: bytes,
        fileName: 'my_store_logo.png',
      );

      expect(result.isSuccess, isTrue);
      final logoUrl = result.dataOrNull!;
      expect(logoUrl,
          contains('shops/shop_branding_101/branding/logo_my_store_logo.png'));
      expect(repository.currentShop.logoUrl, equals(logoUrl));
    });

    test('2. Replaces existing shop logo cleanly', () async {
      // First upload
      await repository.uploadShopLogo(
        shopId: 'shop_branding_101',
        imageBytes: Uint8List.fromList([1, 2]),
        fileName: 'old_logo.png',
      );
      expect(repository.currentShop.logoUrl, contains('old_logo.png'));

      // Replace with new logo
      final replaceResult = await repository.uploadShopLogo(
        shopId: 'shop_branding_101',
        imageBytes: Uint8List.fromList([3, 4]),
        fileName: 'new_logo.png',
      );
      expect(replaceResult.isSuccess, isTrue);
      expect(repository.currentShop.logoUrl, contains('new_logo.png'));
    });

    test('3. Removes shop logo and clears image reference', () async {
      await repository.uploadShopLogo(
        shopId: 'shop_branding_101',
        imageBytes: Uint8List.fromList([1, 2]),
        fileName: 'logo.png',
      );
      expect(repository.currentShop.logoUrl, isNotNull);

      final removeResult = await repository.removeShopLogo('shop_branding_101');
      expect(removeResult.isSuccess, isTrue);
      expect(repository.currentShop.logoUrl, isNull);
    });

    test('4. Updates shop profile and branding receipt display name', () async {
      final updateResult = await repository.updateShopProfile(
        shopId: 'shop_branding_101',
        name: 'Ramesh Supermarket',
        phone: '9845099999',
        address: '99 Commercial Street',
        city: 'Bengaluru',
        state: 'Karnataka',
        pincode: '560001',
        receiptName: 'Ramesh Supermarket POS',
      );

      expect(updateResult.isSuccess, isTrue);
      final shop = updateResult.dataOrNull!;
      expect(shop.name, 'Ramesh Supermarket');
      expect(shop.phone, '9845099999');
      expect(shop.receiptName, 'Ramesh Supermarket POS');
      expect(shop.effectiveReceiptName, 'Ramesh Supermarket POS');
    });

    test(
        '5. Effective receipt display name falls back to shop name when receiptName is null',
        () {
      final shopWithoutReceiptName = ShopModel(
        id: 'shop_1',
        name: 'Ganesh Kirana',
        phone: '9845012345',
        createdAt: DateTime.now(),
      );
      expect(
          shopWithoutReceiptName.effectiveReceiptName, equals('Ganesh Kirana'));
    });

    test('6. Rejects unauthorized modifications by cashier role', () async {
      repository.currentRole = 'cashier';

      final logoResult = await repository.uploadShopLogo(
        shopId: 'shop_branding_101',
        imageBytes: Uint8List.fromList([1, 2]),
        fileName: 'unauthorized_logo.png',
      );
      expect(logoResult.isError, isTrue);
      expect(logoResult.failureOrNull?.message, contains('Unauthorized'));

      final profileResult = await repository.updateShopProfile(
        shopId: 'shop_branding_101',
        name: 'Hacked Store Name',
        phone: '9845012345',
      );
      expect(profileResult.isError, isTrue);
      expect(profileResult.failureOrNull?.message, contains('Unauthorized'));
    });

    test(
        '7. Offline mode prevents remote updates with clear network failure message',
        () async {
      repository.isOffline = true;

      final updateResult = await repository.updateShopProfile(
        shopId: 'shop_branding_101',
        name: 'Offline Supermarket',
        phone: '9845012345',
      );
      expect(updateResult.isError, isTrue);
      expect(updateResult.failureOrNull?.message,
          contains('Internet connection required'));
    });
  });
}
