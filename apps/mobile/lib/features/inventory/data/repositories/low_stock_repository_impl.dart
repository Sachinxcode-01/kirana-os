import 'dart:async';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/network/connectivity_status.dart';
import '../datasources/low_stock_local_data_source.dart';
import '../datasources/low_stock_remote_data_source.dart';
import '../../domain/models/low_stock_alert_model.dart';
import '../../domain/repositories/low_stock_repository.dart';

class LowStockRepositoryImpl implements LowStockRepository {
  final LowStockLocalDataSource _localDataSource;
  final LowStockRemoteDataSource _remoteDataSource;
  final ConnectivityService _connectivityService;

  LowStockRepositoryImpl({
    required LowStockLocalDataSource localDataSource,
    required LowStockRemoteDataSource remoteDataSource,
    required ConnectivityService connectivityService,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        _connectivityService = connectivityService;

  @override
  Future<Result<List<LowStockAlertModel>, Failure>> getLowStockAlerts({
    required String shopId,
    String? search,
  }) async {
    try {
      if (shopId.trim().isEmpty) {
        return const ErrorResult(ValidationFailure('Shop ID is required.'));
      }

      if (_connectivityService.currentStatus != ConnectivityStatus.offline) {
        try {
          final remoteAlerts = await _remoteDataSource.fetchLowStockAlerts(
            shopId,
            search: search,
          );
          await _localDataSource.saveAlerts(remoteAlerts);
          return Success(remoteAlerts);
        } catch (_) {}
      }

      // Offline or remote fallback to local cache
      final localAlerts = await _localDataSource.getLowStockAlerts(
        shopId,
        search: search,
      );
      return Success(localAlerts);
    } catch (e) {
      return ErrorResult(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Result<void, Failure>> markAlertAsRead({
    required String shopId,
    required String alertId,
  }) async {
    try {
      if (shopId.trim().isEmpty) {
        return const ErrorResult(ValidationFailure('Shop ID is required.'));
      }

      await _localDataSource.markAsRead(shopId, alertId);

      if (_connectivityService.currentStatus != ConnectivityStatus.offline) {
        try {
          await _remoteDataSource.markAlertAsRead(shopId, alertId);
        } catch (_) {}
      }

      return const Success(null);
    } catch (e) {
      return ErrorResult(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Result<void, Failure>> markAllAlertsAsRead({
    required String shopId,
  }) async {
    try {
      if (shopId.trim().isEmpty) {
        return const ErrorResult(ValidationFailure('Shop ID is required.'));
      }

      await _localDataSource.markAllAsRead(shopId);

      if (_connectivityService.currentStatus != ConnectivityStatus.offline) {
        try {
          await _remoteDataSource.markAllAlertsAsRead(shopId);
        } catch (_) {}
      }

      return const Success(null);
    } catch (e) {
      return ErrorResult(ErrorHandler.handle(e));
    }
  }

  @override
  Stream<List<LowStockAlertModel>> subscribeToLowStockAlerts(String shopId) {
    final stream = _remoteDataSource.subscribeToLowStockAlerts(shopId);
    return stream.map((alerts) {
      _localDataSource.saveAlerts(alerts);
      return alerts;
    });
  }
}
