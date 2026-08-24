import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:kirana_mobile/core/errors/app_exception.dart';
import 'package:kirana_mobile/core/utils/app_logger.dart';
import 'package:kirana_mobile/features/products/domain/models/product_model.dart';
import '../../domain/models/barcode_model.dart';

class BarcodeRemoteDataSource {
  final supabase.SupabaseClient? _client;

  BarcodeRemoteDataSource([this._client]);

  supabase.SupabaseClient get _supabase {
    if (_client != null) return _client;
    try {
      return supabase.Supabase.instance.client;
    } catch (e) {
      throw const NetworkException('Supabase client not initialized');
    }
  }

  Future<ProductModel?> fetchProductByBarcode(
      String shopId, String barcode) async {
    try {
      final response = await _supabase
          .from('product_barcodes')
          .select('barcode, products(*, categories(name))')
          .eq('shop_id', shopId)
          .eq('barcode', barcode.trim())
          .maybeSingle();

      if (response == null || response['products'] == null) {
        return null;
      }

      final productData = response['products'] as Map<String, dynamic>;
      return ProductModel.fromJson(productData);
    } on supabase.PostgrestException catch (e) {
      AppLogger.w('Supabase barcode search error: ${e.message}',
          tag: 'BarcodeRemoteDataSource');
      throw DatabaseException(e.message, e.code);
    } catch (e) {
      throw DatabaseException(
          'Failed to search product by barcode in cloud: $e');
    }
  }

  Future<BarcodeModel> createBarcode(BarcodeModel barcode) async {
    try {
      final response = await _supabase
          .from('product_barcodes')
          .insert({
            'id': barcode.id,
            'shop_id': barcode.shopId,
            'product_id': barcode.productId,
            'barcode': barcode.barcode,
            'barcode_type': barcode.barcodeType,
            'is_primary': barcode.isPrimary,
            'created_at': barcode.createdAt.toIso8601String(),
            'updated_at': barcode.updatedAt.toIso8601String(),
          })
          .select()
          .single();

      return BarcodeModel.fromJson(response);
    } on supabase.PostgrestException catch (e) {
      if (e.code == '23505') {
        throw ValidationException(
            'Barcode "${barcode.barcode}" is already registered to another product.');
      }
      throw DatabaseException(e.message, e.code);
    } catch (e) {
      throw DatabaseException('Failed to save barcode to cloud: $e');
    }
  }

  Future<BarcodeModel> updateBarcode(BarcodeModel barcode) async {
    try {
      final response = await _supabase
          .from('product_barcodes')
          .update({
            'barcode': barcode.barcode,
            'barcode_type': barcode.barcodeType,
            'is_primary': barcode.isPrimary,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', barcode.id)
          .eq('shop_id', barcode.shopId)
          .select()
          .single();

      return BarcodeModel.fromJson(response);
    } on supabase.PostgrestException catch (e) {
      if (e.code == '23505') {
        throw ValidationException(
            'Barcode "${barcode.barcode}" is already registered.');
      }
      throw DatabaseException(e.message, e.code);
    } catch (e) {
      throw DatabaseException('Failed to update barcode in cloud: $e');
    }
  }

  Future<void> deleteBarcode(String barcodeId, String shopId) async {
    try {
      await _supabase
          .from('product_barcodes')
          .delete()
          .eq('id', barcodeId)
          .eq('shop_id', shopId);
    } on supabase.PostgrestException catch (e) {
      throw DatabaseException(e.message, e.code);
    } catch (e) {
      throw DatabaseException('Failed to delete barcode from cloud: $e');
    }
  }
}
