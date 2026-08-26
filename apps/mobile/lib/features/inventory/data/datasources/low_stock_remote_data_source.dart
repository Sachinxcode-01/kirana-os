import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/low_stock_alert_model.dart';

class LowStockRemoteDataSource {
  final ApiClient _apiClient;

  LowStockRemoteDataSource([ApiClient? apiClient])
      : _apiClient = apiClient ?? ApiClient();

  Future<List<LowStockAlertModel>> fetchLowStockAlerts(
    String shopId, {
    String? search,
  }) async {
    try {
      var query = _apiClient.supabase
          .from('low_stock_alerts')
          .select('*, products(name, hsn_code, unit)')
          .eq('shop_id', shopId);

      if (search != null && search.trim().isNotEmpty) {
        final q = search.trim();
        query =
            query.or('products.name.ilike.%$q%,products.hsn_code.ilike.%$q%');
      }

      final response = await query.order('created_at', ascending: false);
      final dataList = response as List<dynamic>;

      final alerts = dataList
          .map((json) =>
              LowStockAlertModel.fromJson(json as Map<String, dynamic>))
          .toList();

      // Urgency sort
      alerts.sort((a, b) {
        if (a.isOutOfStock && !b.isOutOfStock) return -1;
        if (!a.isOutOfStock && b.isOutOfStock) return 1;
        return a.urgencyRatio.compareTo(b.urgencyRatio);
      });

      return alerts;
    } catch (e) {
      if (e is PostgrestException) {
        throw Exception('Supabase Error [${e.code}]: ${e.message}');
      }
      rethrow;
    }
  }

  Future<void> markAlertAsRead(String shopId, String alertId) async {
    try {
      await _apiClient.supabase
          .from('low_stock_alerts')
          .update(
              {'is_read': true, 'updated_at': DateTime.now().toIso8601String()})
          .eq('shop_id', shopId)
          .eq('id', alertId);
    } catch (e) {
      if (e is PostgrestException) {
        throw Exception('Supabase Error [${e.code}]: ${e.message}');
      }
      rethrow;
    }
  }

  Future<void> markAllAlertsAsRead(String shopId) async {
    try {
      await _apiClient.supabase
          .from('low_stock_alerts')
          .update(
              {'is_read': true, 'updated_at': DateTime.now().toIso8601String()})
          .eq('shop_id', shopId)
          .eq('is_read', false);
    } catch (e) {
      if (e is PostgrestException) {
        throw Exception('Supabase Error [${e.code}]: ${e.message}');
      }
      rethrow;
    }
  }

  Stream<List<LowStockAlertModel>> subscribeToLowStockAlerts(String shopId) {
    final controller = StreamController<List<LowStockAlertModel>>();

    try {
      final channel =
          _apiClient.supabase.channel('public:low_stock_alerts:shop=$shopId');
      channel
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'low_stock_alerts',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'shop_id',
              value: shopId,
            ),
            callback: (_) async {
              try {
                final updatedList = await fetchLowStockAlerts(shopId);
                controller.add(updatedList);
              } catch (_) {}
            },
          )
          .subscribe();

      controller.onCancel = () {
        channel.unsubscribe();
        controller.close();
      };
    } catch (_) {
      // In mock/test environments without live Supabase Realtime channel
    }

    return controller.stream;
  }
}
