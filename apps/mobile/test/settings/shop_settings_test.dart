import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_mobile/core/errors/failure.dart';
import 'package:kirana_mobile/core/network/connectivity_service.dart';
import 'package:kirana_mobile/core/network/connectivity_status.dart';
import 'package:kirana_mobile/features/settings/data/datasources/shop_settings_local_data_source.dart';
import 'package:kirana_mobile/features/settings/data/datasources/shop_settings_remote_data_source.dart';
import 'package:kirana_mobile/features/settings/data/repositories/shop_settings_repository_impl.dart';
import 'package:kirana_mobile/features/settings/domain/models/shop_settings_model.dart';
import 'package:kirana_mobile/features/settings/domain/repositories/shop_settings_repository.dart';
import 'package:kirana_mobile/features/settings/domain/usecases/shop_settings_usecases.dart';

class FakeConnectivityService implements ConnectivityService {
  ConnectivityStatus status = ConnectivityStatus.online;

  @override
  ConnectivityStatus get currentStatus => status;

  @override
  Stream<ConnectivityStatus> get statusStream => Stream.value(status);

  @override
  Future<ConnectivityStatus> checkConnectivity() async => status;

  @override
  void dispose() {}

  @override
  Future<bool> isOnline() async => status == ConnectivityStatus.online;

  @override
  void updateSyncStatus(ConnectivityStatus newStatus) {
    status = newStatus;
  }
}

class FakeShopSettingsRemoteDataSource implements ShopSettingsRemoteDataSource {
  ShopSettingsModel? mockSettings = const ShopSettingsModel(
    shopId: 'shop_test_101',
    shopName: 'Test Kirana Store',
    phone: '9876543210',
    address: '123 Main St',
    city: 'Bengaluru',
    state: 'Karnataka',
    pincode: '560038',
    gstin: '29ABCDE1234F1Z5',
    currencySymbol: '₹',
    isTaxEnabled: true,
    defaultTaxPercentage: 18.0,
    billPrefix: 'INV-',
    nextInvoiceNumber: 1001,
    showShopAddress: true,
    showCustomerDetails: true,
    showTaxInformation: true,
  );

  @override
  Future<ShopSettingsModel> fetchSettings(String shopId) async {
    if (mockSettings == null || mockSettings!.shopId != shopId) {
      throw Exception('Shop not found');
    }
    return mockSettings!;
  }

  @override
  Future<ShopSettingsModel> updateSettings(ShopSettingsModel settings) async {
    mockSettings = settings;
    return mockSettings!;
  }
}

void main() {
  group('KIRANAOS Phase 05.3 — Shop Settings Foundation Tests', () {
    late ShopSettingsLocalDataSource localDataSource;
    late FakeShopSettingsRemoteDataSource remoteDataSource;
    late FakeConnectivityService connectivityService;
    late ShopSettingsRepository repository;
    late GetShopSettingsUseCase getUseCase;
    late UpdateShopSettingsUseCase updateUseCase;

    final initialSettings = const ShopSettingsModel(
      shopId: 'shop_test_101',
      shopName: 'Test Kirana Store',
      phone: '9876543210',
      address: '123 Main St',
      city: 'Bengaluru',
      state: 'Karnataka',
      pincode: '560038',
      gstin: '29ABCDE1234F1Z5',
      currencySymbol: '₹',
      isTaxEnabled: true,
      defaultTaxPercentage: 18.0,
      billPrefix: 'INV-',
      nextInvoiceNumber: 1001,
      showShopAddress: true,
      showCustomerDetails: true,
      showTaxInformation: true,
    );

    setUp(() {
      localDataSource = ShopSettingsLocalDataSource();
      remoteDataSource = FakeShopSettingsRemoteDataSource();
      connectivityService = FakeConnectivityService();
      repository = ShopSettingsRepositoryImpl(
        localDataSource: localDataSource,
        remoteDataSource: remoteDataSource,
        connectivityService: connectivityService,
      );
      getUseCase = GetShopSettingsUseCase(repository);
      updateUseCase = UpdateShopSettingsUseCase(repository);
    });

    test('1. Loads shop settings successfully for active shop ID', () async {
      final result = await getUseCase.execute('shop_test_101');
      expect(result.isSuccess, true);
      final settings = result.dataOrNull!;
      expect(settings.shopId, 'shop_test_101');
      expect(settings.shopName, 'Test Kirana Store');
      expect(settings.phone, '9876543210');
      expect(settings.defaultTaxPercentage, 18.0);
      expect(settings.billPrefix, 'INV-');
    });

    test(
        '2. Allows authorized OWNER or MANAGER to update shop basic info, tax, and bill defaults',
        () async {
      final updatedModel = initialSettings.copyWith(
        shopName: 'Updated Kirana Superstore',
        defaultTaxPercentage: 12.0,
        billPrefix: 'KRN-',
        nextInvoiceNumber: 2005,
      );

      final result = await updateUseCase.execute(
        settings: updatedModel,
        userRole: 'owner',
        activeShopId: 'shop_test_101',
      );

      expect(result.isSuccess, true);
      final saved = result.dataOrNull!;
      expect(saved.shopName, 'Updated Kirana Superstore');
      expect(saved.defaultTaxPercentage, 12.0);
      expect(saved.billPrefix, 'KRN-');
      expect(saved.nextInvoiceNumber, 2005);
    });

    test('3. Rejects invalid tax percentage outside 0% to 100%', () async {
      final invalidTaxHigh =
          initialSettings.copyWith(defaultTaxPercentage: 150.0);
      final resultHigh = await updateUseCase.execute(
        settings: invalidTaxHigh,
        userRole: 'manager',
        activeShopId: 'shop_test_101',
      );

      expect(resultHigh.isError, true);
      expect(resultHigh.failureOrNull, isA<ValidationFailure>());
      expect(resultHigh.failureOrNull!.message,
          'Tax percentage must be between 0% and 100%.');

      final invalidTaxLow =
          initialSettings.copyWith(defaultTaxPercentage: -5.0);
      final resultLow = await updateUseCase.execute(
        settings: invalidTaxLow,
        userRole: 'manager',
        activeShopId: 'shop_test_101',
      );

      expect(resultLow.isError, true);
      expect(resultLow.failureOrNull, isA<ValidationFailure>());
    });

    test('4. Rejects next invoice number less than 1', () async {
      final invalidInvoiceNo = initialSettings.copyWith(nextInvoiceNumber: 0);
      final result = await updateUseCase.execute(
        settings: invalidInvoiceNo,
        userRole: 'owner',
        activeShopId: 'shop_test_101',
      );

      expect(result.isError, true);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(result.failureOrNull!.message,
          'Next invoice number must be at least 1.');
    });

    test('5. Rejects empty shop name or invalid phone number', () async {
      final emptyName = initialSettings.copyWith(shopName: '   ');
      final resultName = await updateUseCase.execute(
        settings: emptyName,
        userRole: 'owner',
        activeShopId: 'shop_test_101',
      );
      expect(resultName.isError, true);
      expect(resultName.failureOrNull, isA<ValidationFailure>());

      final invalidPhone = initialSettings.copyWith(phone: '12345');
      final resultPhone = await updateUseCase.execute(
        settings: invalidPhone,
        userRole: 'owner',
        activeShopId: 'shop_test_101',
      );
      expect(resultPhone.isError, true);
      expect(resultPhone.failureOrNull, isA<ValidationFailure>());
    });

    test(
        '6. Restricts CASHIER and INVENTORY_STAFF from updating shop settings with PermissionDeniedFailure',
        () async {
      final updateAttempt = initialSettings.copyWith(shopName: 'Cashier Edit');

      final resultCashier = await updateUseCase.execute(
        settings: updateAttempt,
        userRole: 'cashier',
        activeShopId: 'shop_test_101',
      );

      expect(resultCashier.isError, true);
      expect(resultCashier.failureOrNull, isA<PermissionDeniedFailure>());
      expect(
        resultCashier.failureOrNull!.message,
        'Only Shop Owners and Managers are authorized to modify shop settings.',
      );

      final resultInventory = await updateUseCase.execute(
        settings: updateAttempt,
        userRole: 'inventory_staff',
        activeShopId: 'shop_test_101',
      );

      expect(resultInventory.isError, true);
      expect(resultInventory.failureOrNull, isA<PermissionDeniedFailure>());
    });

    test('7. Enforces shop isolation (cannot modify another shop ID settings)',
        () async {
      final updateAttempt = initialSettings.copyWith(shopId: 'shop_other_999');

      final result = await updateUseCase.execute(
        settings: updateAttempt,
        userRole: 'owner',
        activeShopId: 'shop_test_101',
      );

      expect(result.isError, true);
      expect(result.failureOrNull, isA<PermissionDeniedFailure>());
      expect(result.failureOrNull!.message,
          'Cannot modify settings for another shop.');
    });

    test(
        '8. Offline mode serves cached settings for read and returns NetworkFailure for update',
        () async {
      // 1. Populate cache first
      await localDataSource.saveSettings(initialSettings);

      // 2. Set connectivity to offline
      connectivityService.status = ConnectivityStatus.offline;

      // 3. Read cached settings when offline
      final cachedResult = await getUseCase.execute('shop_test_101');
      expect(cachedResult.isSuccess, true);
      expect(cachedResult.dataOrNull!.shopId, 'shop_test_101');

      // 4. Update attempt when offline returns NetworkFailure
      final updateAttempt = initialSettings.copyWith(shopName: 'Offline Edit');
      final updateResult = await updateUseCase.execute(
        settings: updateAttempt,
        userRole: 'owner',
        activeShopId: 'shop_test_101',
      );

      expect(updateResult.isError, true);
      expect(updateResult.failureOrNull, isA<NetworkFailure>());
    });
  });
}
