import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/app_providers.dart';
import '../../domain/models/dashboard_metrics.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../data/datasources/dashboard_local_data_source.dart';
import '../../data/repositories/dashboard_repository_impl.dart';

final dashboardLocalDataSourceProvider = Provider<DashboardLocalDataSource>((ref) {
  final db = ref.watch(databaseProvider);
  return DashboardLocalDataSource(db);
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final local = ref.watch(dashboardLocalDataSourceProvider);
  return DashboardRepositoryImpl(local);
});

final dashboardMetricsStreamProvider =
    StreamProvider.autoDispose<DashboardMetrics>((ref) {
  final repository = ref.watch(dashboardRepositoryProvider);
  final shopId = ref.watch(activeShopIdProvider);
  return repository.watchDashboardMetrics(shopId);
});
