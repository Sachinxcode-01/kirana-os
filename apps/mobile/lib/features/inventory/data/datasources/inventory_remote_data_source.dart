import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:kirana_mobile/core/errors/app_exception.dart';
import 'package:kirana_mobile/core/utils/app_logger.dart';
import '../../domain/models/inventory_movement_model.dart';
import '../../domain/models/stock_adjustment_request.dart';

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

    final delta = request.calculateDelta(0);
    final idempotencyKey = request.idempotencyKey ??
        'adj_${request.productId}_${DateTime.now().millisecondsSinceEpoch}';

    try {
      final response = await _supabase.rpc('adjust_product_stock', params: {
        'p_shop_id': request.shopId,
        'p_product_id': request.productId,
        'p_quantity_delta': delta,
        'p_reason': request.adjustmentType.dbReason,
        'p_performed_by': userId,
        'p_note': request.note,
        'p_idempotency_key': idempotencyKey,
        'p_adjustment_reason': request.reason,
      });

      final Map<String, dynamic> data =
          Map<String, dynamic>.from(response as Map);

      return InventoryMovementModel.fromJson({
        ...data,
        'shop_id': request.shopId,
        'product_id': request.productId,
        'idempotency_key': idempotencyKey,
      });
    } on supa.PostgrestException catch (e) {
      AppLogger.w(
          'RPC adjust_product_stock error: ${e.message} (code: ${e.code})',
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

        return InventoryMovementModel.fromJson({
          ...map,
          'product_name': productName,
        });
      }).toList();
    } on supa.PostgrestException catch (e) {
      throw DatabaseException(e.message, e.code);
    } catch (e) {
      throw DatabaseException('Failed to fetch inventory history: $e');
    }
  }
}
