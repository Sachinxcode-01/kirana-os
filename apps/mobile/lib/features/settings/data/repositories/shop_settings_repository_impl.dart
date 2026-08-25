import '../../../../core/errors/error_handler.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/network/connectivity_status.dart';
import '../../domain/models/shop_settings_model.dart';
import '../../domain/repositories/shop_settings_repository.dart';
import '../datasources/shop_settings_local_data_source.dart';
import '../datasources/shop_settings_remote_data_source.dart';

class ShopSettingsRepositoryImpl implements ShopSettingsRepository {
  final ShopSettingsLocalDataSource _localDataSource;
  final ShopSettingsRemoteDataSource _remoteDataSource;
  final ConnectivityService _connectivityService;

  ShopSettingsRepositoryImpl({
    required ShopSettingsLocalDataSource localDataSource,
    required ShopSettingsRemoteDataSource remoteDataSource,
    required ConnectivityService connectivityService,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        _connectivityService = connectivityService;

  @override
  Future<Result<ShopSettingsModel, Failure>> getShopSettings(
    String shopId,
  ) async {
    try {
      // 1. Try local cache first for fast/offline view
      final local = await _localDataSource.getSettings(shopId);
      if (_connectivityService.currentStatus == ConnectivityStatus.offline &&
          local != null) {
        return Success(local);
      }

      // 2. Try remote query
      try {
        final remote = await _remoteDataSource.fetchSettings(shopId);
        await _localDataSource.saveSettings(remote);
        return Success(remote);
      } catch (e) {
        if (local != null) {
          return Success(local);
        }
        return ErrorResult(ErrorHandler.handle(e));
      }
    } catch (e) {
      return ErrorResult(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Result<ShopSettingsModel, Failure>> updateShopSettings(
    ShopSettingsModel settings,
  ) async {
    if (_connectivityService.currentStatus == ConnectivityStatus.offline) {
      return const ErrorResult(
        NetworkFailure(
          'Updating shop settings requires an active internet connection.',
        ),
      );
    }

    try {
      final updated = await _remoteDataSource.updateSettings(settings);
      await _localDataSource.saveSettings(updated);
      return Success(updated);
    } catch (e) {
      return ErrorResult(ErrorHandler.handle(e));
    }
  }
}
