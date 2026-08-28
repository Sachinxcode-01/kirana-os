import '../../../../core/errors/error_handler.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../domain/models/dashboard_metrics.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_local_data_source.dart';
import '../datasources/dashboard_remote_data_source.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardLocalDataSource _localDataSource;
  final DashboardRemoteDataSource? _remoteDataSource;

  DashboardRepositoryImpl(
    this._localDataSource, [
    this._remoteDataSource,
  ]);

  @override
  Future<Result<DashboardMetrics, Failure>> getDashboardMetrics(
      String shopId) async {
    if (_remoteDataSource != null) {
      try {
        final remoteMetrics = await _remoteDataSource.getMetrics(shopId);
        return Success(remoteMetrics.copyWith(isOffline: false));
      } catch (_) {
        // Fallback to local Drift calculation on network or RPC failure
      }
    }

    try {
      final localMetrics =
          await _localDataSource.getMetrics(shopId, isOffline: true);
      return Success(localMetrics);
    } catch (e) {
      return ErrorResult(ErrorHandler.handle(e));
    }
  }

  @override
  Stream<DashboardMetrics> watchDashboardMetrics(String shopId) {
    return _localDataSource.watchMetrics(shopId);
  }
}
