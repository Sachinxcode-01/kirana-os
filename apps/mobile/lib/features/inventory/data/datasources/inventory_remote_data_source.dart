import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:kirana_mobile/core/errors/exceptions.dart';
import 'package:kirana_mobile/core/utils/app_logger.dart';
import '../models/inventory_movement_model.dart';
import '../models/stock_adjustment_request.dart';

class InventoryRemoteDataSource {
  final supa.SupabaseClient? _client;

  InventoryRemoteDataSource({supa.SupabaseClient? supabaseClient})
      : _client = supabaseClient;

  supa.SupabaseClient get _supabase {
    if (_client != null) return _client;
    try {
      return supa.Supabase.instance.client;
    } catch (e) {
      throw DatabaseException('Supabase connection not initialized');
    }
  }

  Future<InventoryMovementModel> adjustStock(
      StockAdjustmentRequest request) async {
    final user = _supabase.auth.currentUser;
    final userId = user?.id ?? request.userId;

    try {
      final response = await _supabase.rpc('adjust_product_stock', params: {
        'p_shop_id': request.shopId,
        'p_product_id': request.productId,
        'p_quantity_delta': request.calculateDelta(0),
        'p_reason': request.adjustmentType.dbReason,
        'p_performed_by': userId,
        'p_note': request.note,
      });

      final Map<String, dynamic> data =
          Map<String, dynamic>.from(response as Map);

      return InventoryMovementModel(
        id: data['movement_id'] as String? ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        shopId: request.shopId,
        productId: request.productId,
        quantityDelta: (data['quantity_delta'] as num).toDouble(),
        balanceAfter: (data['new_stock'] as num).toDouble(),
        reason: data['reason'] as String? ?? request.adjustmentType.dbReason,
        performedBy: userId,
        note: request.note,
        createdAt: DateTime.now(),
      );
    } on supa.PostgrestException catch (e) {
      AppLogger.w(
          'RPC adjust_product_stock warning: ${e.message} (code: ${e.code})',
          tag: 'InventoryRemoteDataSource');
      throw DatabaseException(e.message, e.code);
    } catch (e) {
      AppLogger.e('Unexpected adjustStock remote error: $e',
          tag: 'InventoryRemoteDataSource');
      throw DatabaseException('Failed to adjust stock on remote database: $e');
    }
  }

  Future<List<InventoryMovementModel>> getInventoryHistory({
    required String shopId,
    String? productId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var query = _supabase
          .from('inventory_movements')
          .select('*, products(name)')
          .eq('shop_id', shopId);

      if (productId != null && productId.isNotEmpty) {
        query = query.eq('product_id', productId);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final List<dynamic> list = response as List<dynamic>;

      return list.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        final productData = map['products'] as Map<String, dynamic>?;
        final productName = productData?['name'] as String?;

        return InventoryMovementModel(
          id: map['id'] as String,
          shopId: map['shop_id'] as String,
          productId: map['product_id'] as String,
          productName: productName,
          quantityDelta: (map['quantity_delta'] as num).toDouble(),
          balanceAfter: (map['balance_after'] as num).toDouble(),
          reason: map['reason'] as String? ?? 'adjustment',
          referenceId: map['reference_id'] as String?,
          performedBy: map['performed_by'] as String? ?? 'user',
          createdAt: map['created_at'] != null
              ? DateTime.parse(map['created_at'] as String)
              : DateTime.now(),
        );
      }).toList();
    } on supa.PostgrestException catch (e) {
      throw DatabaseException(e.message, e.code);
    } catch (e) {
      throw DatabaseException('Failed to fetch inventory history: $e');
    }
  }
}
