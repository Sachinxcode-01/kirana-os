import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/app_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/shop_settings_model.dart';
import '../../domain/repositories/shop_settings_repository.dart';
import '../../domain/usecases/shop_settings_usecases.dart';
import '../../data/datasources/shop_settings_local_data_source.dart';
import '../../data/datasources/shop_settings_remote_data_source.dart';
import '../../data/repositories/shop_settings_repository_impl.dart';

final shopSettingsLocalDataSourceProvider =
    Provider<ShopSettingsLocalDataSource>((ref) {
  return ShopSettingsLocalDataSource();
});

final shopSettingsRemoteDataSourceProvider =
    Provider<ShopSettingsRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ShopSettingsRemoteDataSource(apiClient);
});

final shopSettingsRepositoryProvider = Provider<ShopSettingsRepository>((ref) {
  final local = ref.watch(shopSettingsLocalDataSourceProvider);
  final remote = ref.watch(shopSettingsRemoteDataSourceProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  return ShopSettingsRepositoryImpl(
    localDataSource: local,
    remoteDataSource: remote,
    connectivityService: connectivity,
  );
});

final getShopSettingsUseCaseProvider = Provider<GetShopSettingsUseCase>((ref) {
  final repo = ref.watch(shopSettingsRepositoryProvider);
  return GetShopSettingsUseCase(repo);
});

final updateShopSettingsUseCaseProvider =
    Provider<UpdateShopSettingsUseCase>((ref) {
  final repo = ref.watch(shopSettingsRepositoryProvider);
  return UpdateShopSettingsUseCase(repo);
});

class ShopSettingsState {
  final bool isLoading;
  final bool isSaving;
  final ShopSettingsModel? settings;
  final String? errorMessage;
  final String? successMessage;

  const ShopSettingsState({
    this.isLoading = false,
    this.isSaving = false,
    this.settings,
    this.errorMessage,
    this.successMessage,
  });

  ShopSettingsState copyWith({
    bool? isLoading,
    bool? isSaving,
    ShopSettingsModel? settings,
    String? errorMessage,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
  }) {
    return ShopSettingsState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      settings: settings ?? this.settings,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class ShopSettingsNotifier extends StateNotifier<ShopSettingsState> {
  final GetShopSettingsUseCase _getUseCase;
  final UpdateShopSettingsUseCase _updateUseCase;
  final Ref _ref;

  ShopSettingsNotifier(this._getUseCase, this._updateUseCase, this._ref)
      : super(const ShopSettingsState());

  Future<void> loadSettings(String shopId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _getUseCase.execute(shopId);

    result.fold(
      (settings) {
        state = state.copyWith(isLoading: false, settings: settings);
      },
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
      },
    );
  }

  Future<bool> saveSettings(ShopSettingsModel updatedSettings) async {
    final authState = _ref.read(authNotifierProvider);
    final user = authState.user;
    final activeShopId = authState.activeShopId ?? updatedSettings.shopId;

    state = state.copyWith(
      isSaving: true,
      clearError: true,
      clearSuccess: true,
    );

    final result = await _updateUseCase.execute(
      settings: updatedSettings,
      userRole: user?.role ?? 'cashier',
      activeShopId: activeShopId,
    );

    return result.fold(
      (savedSettings) {
        state = state.copyWith(
          isSaving: false,
          settings: savedSettings,
          successMessage: 'Shop settings updated successfully!',
        );
        return true;
      },
      (failure) {
        state = state.copyWith(
          isSaving: false,
          errorMessage: failure.message,
        );
        return false;
      },
    );
  }
}

final shopSettingsNotifierProvider =
    StateNotifierProvider<ShopSettingsNotifier, ShopSettingsState>((ref) {
  final getUseCase = ref.watch(getShopSettingsUseCaseProvider);
  final updateUseCase = ref.watch(updateShopSettingsUseCaseProvider);
  return ShopSettingsNotifier(getUseCase, updateUseCase, ref);
});
