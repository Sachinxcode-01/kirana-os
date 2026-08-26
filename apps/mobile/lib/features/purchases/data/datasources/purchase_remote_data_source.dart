import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/api_client.dart';
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
          'p_supplier_reference': purchase.supplierReference,
          'p_items': itemsPayload,
          'p_idempotency_key': idempotencyKey,
        },
      );

      if (rpcResult != null) {
        final Map<String, dynamic> data = rpcResult as Map<String, dynamic>;
        return purchase.copyWith(
          status: 'completed',
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
}
