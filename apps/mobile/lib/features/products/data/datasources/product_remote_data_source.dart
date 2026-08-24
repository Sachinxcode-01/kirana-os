import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/app_logger.dart';

class ProductRemoteDataSource {
  final supabase.SupabaseClient? _client;

  ProductRemoteDataSource([this._client]);

  supabase.SupabaseClient get _supabase {
    if (_client != null) return _client;
    try {
      return supabase.Supabase.instance.client;
    } catch (e) {
      throw const NetworkException('Supabase client not initialized');
    }
  }

  Future<List<Map<String, dynamic>>> fetchProducts(String shopId) async {
    try {
      final response = await _supabase
          .from('products')
          .select('*, product_barcodes(*)')
          .eq('shop_id', shopId)
          .eq('is_active', true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      AppLogger.w('Failed to fetch remote products: $e',
          tag: 'ProductRemoteDataSource');
      throw const NetworkException('Unable to fetch products from cloud');
    }
  }

  Future<void> pushProduct(Map<String, dynamic> payload) async {
    try {
      await _supabase.from('products').upsert(payload);
    } catch (e) {
      AppLogger.e('Failed to push remote product: $e',
          tag: 'ProductRemoteDataSource');
      throw const NetworkException('Failed to push product to cloud');
    }
  }
}
