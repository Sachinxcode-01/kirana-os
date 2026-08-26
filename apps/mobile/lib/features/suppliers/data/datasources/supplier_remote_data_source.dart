import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/supplier_model.dart';

class SupplierRemoteDataSource {
  final ApiClient _apiClient;

  SupplierRemoteDataSource([ApiClient? apiClient])
      : _apiClient = apiClient ?? ApiClient();

  Future<SupplierModel> insertSupplier(SupplierModel supplier) async {
    try {
      final response = await _apiClient.supabase
          .from('suppliers')
          .insert(supplier.toJson())
          .select()
          .single();

      return SupplierModel.fromJson(response);
    } catch (e) {
      if (e is PostgrestException) {
        throw Exception('Supabase Error [${e.code}]: ${e.message}');
      }
      rethrow;
    }
  }

  Future<SupplierModel> updateSupplier(SupplierModel supplier) async {
    try {
      final response = await _apiClient.supabase
          .from('suppliers')
          .update(supplier.toJson())
          .eq('id', supplier.id)
          .eq('shop_id', supplier.shopId)
          .select()
          .single();

      return SupplierModel.fromJson(response);
    } catch (e) {
      if (e is PostgrestException) {
        throw Exception('Supabase Error [${e.code}]: ${e.message}');
      }
      rethrow;
    }
  }

  Future<SupplierModel> archiveSupplier(
      String shopId, String supplierId) async {
    try {
      final response = await _apiClient.supabase
          .from('suppliers')
          .update({
            'is_archived': true,
            'updated_at': DateTime.now().toUtc().toIso8601String()
          })
          .eq('id', supplierId)
          .eq('shop_id', shopId)
          .select()
          .single();

      return SupplierModel.fromJson(response);
    } catch (e) {
      if (e is PostgrestException) {
        throw Exception('Supabase Error [${e.code}]: ${e.message}');
      }
      rethrow;
    }
  }

  Future<List<SupplierModel>> fetchSuppliers(
    String shopId, {
    bool includeArchived = false,
    String? searchQuery,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query =
          _apiClient.supabase.from('suppliers').select().eq('shop_id', shopId);

      if (!includeArchived) {
        query = query.eq('is_archived', false);
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim();
        query = query.or('name.ilike.%$q%,phone.ilike.%$q%,gstin.ilike.%$q%');
      }

      final response = await query
          .order('name', ascending: true)
          .range(offset, offset + limit - 1);

      final list = (response as List<dynamic>)
          .map((json) => SupplierModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return list;
    } catch (e) {
      if (e is PostgrestException) {
        throw Exception('Supabase Error [${e.code}]: ${e.message}');
      }
      rethrow;
    }
  }

  Future<SupplierModel?> fetchSupplierById(String id) async {
    try {
      final response = await _apiClient.supabase
          .from('suppliers')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return SupplierModel.fromJson(response);
    } catch (e) {
      if (e is PostgrestException) {
        throw Exception('Supabase Error [${e.code}]: ${e.message}');
      }
      rethrow;
    }
  }
}
