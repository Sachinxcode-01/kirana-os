import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/models/product_model.dart';

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
          .select('*, categories(name), product_barcodes(*)')
          .eq('shop_id', shopId)
          .eq('is_active', true)
          .order('name', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } on supabase.PostgrestException catch (e) {
      AppLogger.w('Failed to fetch remote products: ${e.message}',
          tag: 'ProductRemoteDataSource');
      throw DatabaseException(e.message, e.code);
    } catch (e) {
      AppLogger.w('Failed to fetch remote products: $e',
          tag: 'ProductRemoteDataSource');
      throw const NetworkException('Unable to fetch products from cloud');
    }
  }

  Future<ProductModel> createProduct(ProductModel product) async {
    try {
      final response = await _supabase
          .from('products')
          .insert({
            'id': product.id,
            'shop_id': product.shopId,
            'category_id': product.categoryId,
            'name': product.name,
            'brand': product.brand,
            'unit': product.unit,
            'selling_price_paise': product.sellingPricePaise,
            'purchase_price_paise': product.purchasePricePaise,
            'mrp_paise': product.mrpPaise,
            'current_stock': product.currentStock,
            'min_stock_alert': product.minStockAlert,
            'description': product.description,
            'regional_name': product.regionalName,
            'hsn_code': product.hsnCode,
            'tax_rate_percentage': product.taxRatePercentage,
            'is_tax_inclusive': product.isTaxInclusive,
            'is_loose': product.isLoose,
            'is_active': product.isActive,
            'created_at': product.createdAt.toIso8601String(),
            'updated_at': product.updatedAt.toIso8601String(),
          })
          .select('*, categories(name)')
          .single();

      return ProductModel.fromJson(response);
    } on supabase.PostgrestException catch (e) {
      if (e.code == '23505') {
        throw ValidationException(
            'A product named "${product.name}" already exists in this shop.');
      }
      throw DatabaseException(e.message, e.code);
    } catch (e) {
      throw DatabaseException('Failed to create product in cloud: $e');
    }
  }

  Future<ProductModel> updateProduct(ProductModel product) async {
    try {
      final response = await _supabase
          .from('products')
          .update({
            'category_id': product.categoryId,
            'name': product.name,
            'brand': product.brand,
            'unit': product.unit,
            'selling_price_paise': product.sellingPricePaise,
            'purchase_price_paise': product.purchasePricePaise,
            'mrp_paise': product.mrpPaise,
            'min_stock_alert': product.minStockAlert,
            'description': product.description,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', product.id)
          .eq('shop_id', product.shopId)
          .select('*, categories(name)')
          .single();

      return ProductModel.fromJson(response);
    } on supabase.PostgrestException catch (e) {
      if (e.code == '23505') {
        throw ValidationException(
            'Another product named "${product.name}" already exists.');
      }
      throw DatabaseException(e.message, e.code);
    } catch (e) {
      throw DatabaseException('Failed to update product in cloud: $e');
    }
  }

  Future<void> archiveProduct(String productId, String shopId) async {
    try {
      await _supabase
          .from('products')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', productId)
          .eq('shop_id', shopId);
    } on supabase.PostgrestException catch (e) {
      throw DatabaseException(e.message, e.code);
    } catch (e) {
      throw DatabaseException('Failed to archive product in cloud: $e');
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
