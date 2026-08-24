import '../../../../core/errors/error_handler.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../domain/models/dashboard_metrics.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_local_data_source.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardLocalDataSource _localDataSource;

  DashboardRepositoryImpl(this._localDataSource);

  @override
  Future<Result<DashboardMetrics, Failure>> getDashboardMetrics(
      String shopId) async {
    try {
      final metrics = await _localDataSource.getMetrics(shopId);
      return Success(metrics);
    } catch (e) {
      return ErrorResult(ErrorHandler.handle(e));
    }
  }

  @override
  Stream<DashboardMetrics> watchDashboardMetrics(String shopId) {
    return _localDataSource.watchMetrics(shopId);
  }
}
