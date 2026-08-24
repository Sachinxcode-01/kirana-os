import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:kirana_mobile/core/errors/app_exception.dart';
import 'package:kirana_mobile/core/utils/app_logger.dart';
import '../../domain/models/category_model.dart';

class CategoryRemoteDataSource {
  final supa.SupabaseClient? _client;

  CategoryRemoteDataSource([this._client]);

  supa.SupabaseClient get _supabase {
    if (_client != null) return _client;
    try {
      return supa.Supabase.instance.client;
    } catch (e) {
      throw const NetworkException('Supabase connection not initialized');
    }
  }

  Future<List<CategoryModel>> fetchCategories(String shopId) async {
    try {
      final response = await _supabase
          .from('categories')
          .select()
          .eq('shop_id', shopId)
          .eq('is_active', true)
          .order('sort_order', ascending: true)
          .order('name', ascending: true);

      final list = response as List<dynamic>;
      return list
          .map((item) => CategoryModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on supa.PostgrestException catch (e) {
      AppLogger.e('Supabase fetchCategories error: ${e.message}',
          tag: 'CategoryRemoteDataSource');
      throw DatabaseException(e.message, e.code);
    } catch (e) {
      throw DatabaseException('Failed to fetch categories from cloud: $e');
    }
  }

  Future<CategoryModel> createCategory(CategoryModel category) async {
    try {
      final response = await _supabase
          .from('categories')
          .insert({
            'id': category.id,
            'shop_id': category.shopId,
            'name': category.name,
            'description': category.description,
            'parent_id': category.parentId,
            'icon_url': category.iconUrl,
            'sort_order': category.sortOrder,
            'is_active': category.isActive,
            'created_at': category.createdAt.toIso8601String(),
            'updated_at': category.updatedAt.toIso8601String(),
          })
          .select()
          .single();

      return CategoryModel.fromJson(response);
    } on supa.PostgrestException catch (e) {
      if (e.code == '23505') {
        throw ValidationException(
            'A category with the name "${category.name}" already exists in your shop.');
      }
      throw DatabaseException(e.message, e.code);
    } catch (e) {
      throw DatabaseException('Failed to create category on cloud: $e');
    }
  }

  Future<CategoryModel> updateCategory(CategoryModel category) async {
    try {
      final response = await _supabase
          .from('categories')
          .update({
            'name': category.name,
            'description': category.description,
            'icon_url': category.iconUrl,
            'sort_order': category.sortOrder,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', category.id)
          .eq('shop_id', category.shopId)
          .select()
          .single();

      return CategoryModel.fromJson(response);
    } on supa.PostgrestException catch (e) {
      if (e.code == '23505') {
        throw ValidationException(
            'Another category with the name "${category.name}" already exists.');
      }
      throw DatabaseException(e.message, e.code);
    } catch (e) {
      throw DatabaseException('Failed to update category on cloud: $e');
    }
  }

  Future<void> archiveCategory(String categoryId, String shopId) async {
    try {
      await _supabase
          .from('categories')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', categoryId)
          .eq('shop_id', shopId);
    } on supa.PostgrestException catch (e) {
      throw DatabaseException(e.message, e.code);
    } catch (e) {
      throw DatabaseException('Failed to archive category on cloud: $e');
    }
  }
}
