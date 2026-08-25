import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kirana_mobile/app/app_providers.dart';
import 'package:kirana_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:kirana_mobile/features/shop/domain/models/shop_model.dart';
import 'package:kirana_mobile/features/shop/domain/repositories/shop_repository.dart';
import 'package:kirana_mobile/features/shop/domain/usecases/create_shop_usecase.dart';
import 'package:kirana_mobile/features/shop/data/datasources/shop_local_data_source.dart';
import 'package:kirana_mobile/features/shop/data/datasources/shop_remote_data_source.dart';
import 'package:kirana_mobile/features/shop/data/repositories/shop_repository_impl.dart';

final shopLocalDataSourceProvider = Provider<ShopLocalDataSource>((ref) {
  final db = ref.watch(databaseProvider);
  return ShopLocalDataSource(db);
});

final shopRemoteDataSourceProvider = Provider<ShopRemoteDataSource>((ref) {
  return ShopRemoteDataSource();
});

final shopRepositoryProvider = Provider<ShopRepository>((ref) {
  final local = ref.watch(shopLocalDataSourceProvider);
  final remote = ref.watch(shopRemoteDataSourceProvider);
  final imageService = ref.watch(productImageServiceProvider);
  return ShopRepositoryImpl(
    localDataSource: local,
    remoteDataSource: remote,
    imageService: imageService,
  );
});

final createShopUseCaseProvider = Provider<CreateShopUseCase>((ref) {
  final repository = ref.watch(shopRepositoryProvider);
  return CreateShopUseCase(repository);
});

class ShopSetupState {
  final bool isLoading;
  final String? errorMessage;
  final ShopModel? createdShop;

  const ShopSetupState({
    this.isLoading = false,
    this.errorMessage,
    this.createdShop,
  });
}

class ShopNotifier extends StateNotifier<ShopSetupState> {
  final CreateShopUseCase _createShopUseCase;
  final Ref _ref;

  ShopNotifier(this._createShopUseCase, this._ref)
      : super(const ShopSetupState());

  Future<bool> createShop({
    required String name,
    required String phone,
    String? address,
    String? city,
    String? stateName,
    String? pincode,
    String? gstin,
    String? fssaiLicense,
    String? upiId,
    String? logoUrl,
  }) async {
    if (state.isLoading) return false;

    final authState = _ref.read(authNotifierProvider);
    if (authState.hasActiveShop) {
      state = const ShopSetupState(
        isLoading: false,
        errorMessage: 'You already belong to an active store.',
      );
      return false;
    }

    state = const ShopSetupState(isLoading: true, errorMessage: null);

    final result = await _createShopUseCase.execute(
      name: name,
      phone: phone,
      address: address,
      city: city,
      state: stateName ?? 'Karnataka',
      pincode: pincode,
      gstin: gstin,
      fssaiLicense: fssaiLicense,
      upiId: upiId,
      logoUrl: logoUrl,
    );

    return result.fold(
      (shop) {
        state = ShopSetupState(isLoading: false, createdShop: shop);
        _ref.read(authNotifierProvider.notifier).updateActiveShop(
              shopId: shop.id,
              shopName: shop.name,
            );
        _ref.read(activeShopIdProvider.notifier).state = shop.id;
        return true;
      },
      (failure) {
        state = ShopSetupState(
          isLoading: false,
          errorMessage: failure.message,
        );
        return false;
      },
    );
  }
}

final shopNotifierProvider =
    StateNotifierProvider<ShopNotifier, ShopSetupState>((ref) {
  final useCase = ref.watch(createShopUseCaseProvider);
  return ShopNotifier(useCase, ref);
});

final currentShopDetailsProvider =
    FutureProvider.family<ShopModel?, String>((ref, shopId) async {
  if (shopId.isEmpty) return null;
  final repository = ref.watch(shopRepositoryProvider);
  final result = await repository.getShopDetails(shopId);
  return result.dataOrNull;
});
