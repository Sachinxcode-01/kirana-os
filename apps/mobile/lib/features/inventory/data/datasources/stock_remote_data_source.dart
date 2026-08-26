import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/api_client.dart';
import '../../../products/domain/models/product_model.dart';
import '../../domain/models/stock_overview_model.dart';

class StockRemoteDataSource {
  final ApiClient _apiClient;

  StockRemoteDataSource([ApiClient? apiClient])
      : _apiClient = apiClient ?? ApiClient();

  Future<StockOverviewResult> fetchStockOverview(
    String shopId, {
    StockOverviewFilter filter = const StockOverviewFilter(),
  }) async {
    try {
      var query = _apiClient.supabase
          .from('products')
          .select('*, categories(name)')
          .eq('shop_id', shopId)
          .eq('is_active', true);

      // Search Query
      if (filter.search != null && filter.search!.trim().isNotEmpty) {
        final q = filter.search!.trim();
        query = query
            .or('name.ilike.%$q%,regional_name.ilike.%$q%,hsn_code.ilike.%$q%');
      }

      // Category Filter
      if (filter.categoryId != null && filter.categoryId!.isNotEmpty) {
        query = query.eq('category_id', filter.categoryId!);
      }

      final offset = (filter.page - 1) * filter.pageSize;
      final limit = filter.pageSize;

      final response = await query
          .order('name', ascending: true)
          .range(offset, offset + limit - 1);

      final dataList = response as List<dynamic>;
      var products = dataList
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .toList();

      // Status filter locally if status specified
      if (filter.statusFilter != null) {
        products = products
            .where((p) => p.stockStatus == filter.statusFilter)
            .toList();
      }

      final hasMore = dataList.length >= limit;

      // Quick count calculations
      final inStockCount =
          products.where((p) => p.stockStatus == StockStatus.inStock).length;
      final lowStockCount =
          products.where((p) => p.stockStatus == StockStatus.lowStock).length;
      final outOfStockCount =
          products.where((p) => p.stockStatus == StockStatus.outOfStock).length;

      return StockOverviewResult(
        products: products,
        totalCount: offset + products.length,
        inStockCount: inStockCount,
        lowStockCount: lowStockCount,
        outOfStockCount: outOfStockCount,
        hasMore: hasMore,
        isOffline: false,
        lastSyncedAt: DateTime.now(),
      );
    } catch (e) {
      if (e is PostgrestException) {
        throw Exception('Supabase Error [${e.code}]: ${e.message}');
      }
      rethrow;
    }
  }

  Stream<ProductModel> subscribeToStockUpdates(String shopId) {
    final controller = StreamController<ProductModel>();

    try {
      final channel =
          _apiClient.supabase.channel('public:products:shop=$shopId');
      channel
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'products',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'shop_id',
              value: shopId,
            ),
            callback: (payload) {
              if (payload.newRecord.isNotEmpty) {
                try {
                  final product = ProductModel.fromJson(payload.newRecord);
                  controller.add(product);
                } catch (_) {}
              }
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
