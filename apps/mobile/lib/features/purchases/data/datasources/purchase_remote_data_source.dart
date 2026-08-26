import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/purchase_history_filter.dart';
import '../../domain/models/purchase_model.dart';

class PurchaseRemoteDataSource {
  final ApiClient _apiClient;

  PurchaseRemoteDataSource([ApiClient? apiClient])
      : _apiClient = apiClient ?? ApiClient();

  Future<PurchaseModel> confirmPurchaseStockIn({
    required String shopId,
    required PurchaseModel purchase,
    required String idempotencyKey,
  }) async {
    try {
      final itemsPayload = purchase.items
          .map((i) => {
                'id': i.id,
                'product_id': i.productId,
                'product_name': i.productName,
                'unit': i.unit,
                'quantity': i.quantity,
                'purchase_price_paise': i.purchasePricePaise,
              })
          .toList();

      final rpcResult = await _apiClient.supabase.rpc(
        'confirm_purchase_stock_in',
        params: {
          'p_shop_id': shopId,
          'p_purchase_id': purchase.id,
          'p_purchase_number': purchase.purchaseNumber,
          'p_supplier_id': purchase.supplierId,
          'p_supplier_reference': purchase.supplierReference,
          'p_items': itemsPayload,
          'p_idempotency_key': idempotencyKey,
        },
      );

      if (rpcResult != null) {
        final Map<String, dynamic> data = rpcResult as Map<String, dynamic>;
        return purchase.copyWith(
          status: 'completed',
          supplierId: data['supplier_id'] as String? ?? purchase.supplierId,
          supplierName:
              data['supplier_name'] as String? ?? purchase.supplierName,
          subtotalPaise: (data['subtotal_paise'] as num?)?.toInt() ??
              purchase.subtotalPaise,
          totalPaise:
              (data['total_paise'] as num?)?.toInt() ?? purchase.totalPaise,
          idempotencyKey: idempotencyKey,
        );
      }

      return purchase.copyWith(
          status: 'completed', idempotencyKey: idempotencyKey);
    } catch (e) {
      if (e is PostgrestException) {
        throw Exception('Supabase Error [${e.code}]: ${e.message}');
      }
      rethrow;
    }
  }

  Future<List<PurchaseModel>> fetchShopPurchases(String shopId) async {
    try {
      final response = await _apiClient.supabase
          .from('purchases')
          .select('*, items:purchase_items(*)')
          .eq('shop_id', shopId)
          .order('created_at', ascending: false);

      final list = (response as List<dynamic>)
          .map((json) => PurchaseModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return list;
    } catch (e) {
      if (e is PostgrestException) {
        throw Exception('Supabase Error [${e.code}]: ${e.message}');
      }
      rethrow;
    }
  }

  Future<PurchaseHistoryResult> fetchPurchaseHistory(
    String shopId, {
    PurchaseHistoryFilter filter = const PurchaseHistoryFilter(),
  }) async {
    try {
      var query = _apiClient.supabase
          .from('purchases')
          .select('*, items:purchase_items(*)')
          .eq('shop_id', shopId);

      // Search Query
      if (filter.search != null && filter.search!.trim().isNotEmpty) {
        final q = filter.search!.trim();
        query = query
            .or('invoice_number.ilike.%$q%,supplier_name_snapshot.ilike.%$q%');
      }

      // Status Filter
      final statusDb = filter.statusFilter.dbValue;
      if (statusDb != null) {
        query = query.eq('status', statusDb);
      }

      // Supplier ID Filter
      if (filter.supplierId != null && filter.supplierId!.isNotEmpty) {
        query = query.eq('supplier_id', filter.supplierId!);
      }

      // Date Range Filter
      if (filter.dateRange != null) {
        final start = DateTime(
          filter.dateRange!.start.year,
          filter.dateRange!.start.month,
          filter.dateRange!.start.day,
        ).toUtc().toIso8601String();
        final end = DateTime(
          filter.dateRange!.end.year,
          filter.dateRange!.end.month,
          filter.dateRange!.end.day,
          23,
          59,
          59,
        ).toUtc().toIso8601String();

        query = query.gte('created_at', start).lte('created_at', end);
      }

      final offset = (filter.page - 1) * filter.pageSize;
      final limit = filter.pageSize;

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final dataList = response as List<dynamic>;

      final purchases = dataList
          .map((json) => PurchaseModel.fromJson(json as Map<String, dynamic>))
          .toList();

      final hasMore = purchases.length >= limit;

      return PurchaseHistoryResult(
        purchases: purchases,
        hasMore: hasMore,
        totalCount: offset + purchases.length,
        isOffline: false,
        isPartialOfflineHistory: false,
      );
    } catch (e) {
      if (e is PostgrestException) {
        throw Exception('Supabase Error [${e.code}]: ${e.message}');
      }
      rethrow;
    }
  }
}
