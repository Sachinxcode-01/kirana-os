import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../models/dashboard_metrics.dart';

abstract interface class DashboardRepository {
  Future<Result<DashboardMetrics, Failure>> getDashboardMetrics(String shopId);
  Stream<DashboardMetrics> watchDashboardMetrics(String shopId);
}
