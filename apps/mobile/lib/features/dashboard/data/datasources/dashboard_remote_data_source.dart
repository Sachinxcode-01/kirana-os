import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/dashboard_metrics.dart';

class DashboardRemoteDataSource {
  final ApiClient _apiClient;

  DashboardRemoteDataSource([ApiClient? apiClient])
      : _apiClient = apiClient ?? ApiClient();

  Future<DashboardMetrics> getMetrics(String shopId) async {
    try {
      final response = await _apiClient.supabase.rpc(
        'get_sales_dashboard_metrics',
        params: {'p_shop_id': shopId},
      );

      if (response == null) {
        return DashboardMetrics.empty();
      }

      return DashboardMetrics.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      if (e is PostgrestException) {
        throw Exception('Supabase Error [${e.code}]: ${e.message}');
      }
      rethrow;
    }
  }
}
