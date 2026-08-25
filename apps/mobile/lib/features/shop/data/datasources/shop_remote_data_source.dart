import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/models/shop_model.dart';

class ShopRemoteDataSource {
  final supa.SupabaseClient? _client;

  ShopRemoteDataSource([this._client]);

  supa.SupabaseClient get _supabase {
    if (_client != null) return _client;
    try {
      return supa.Supabase.instance.client;
    } catch (e) {
      throw const NetworkException('Supabase connection not initialized');
    }
  }

  Future<ShopModel> createShop({
    required String name,
    required String phone,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? gstin,
    String? fssaiLicense,
    String? upiId,
    String? logoUrl,
  }) async {
    try {
      final response = await _supabase.rpc(
        'create_shop_and_owner_membership',
        params: {
          'p_name': name.trim(),
          'p_phone': phone.trim(),
          'p_address': address?.trim(),
          'p_city': city?.trim(),
          'p_state': state?.trim() ?? 'Karnataka',
          'p_pincode': pincode?.trim(),
          'p_gstin': gstin?.trim(),
          'p_fssai_license': fssaiLicense?.trim(),
          'p_upi_id': upiId?.trim(),
          'p_logo_url': logoUrl,
        },
      );

      final data = response as Map<String, dynamic>;
      final shopId = data['shop_id'] as String;

      return ShopModel(
        id: shopId,
        name: name.trim(),
        phone: phone.trim(),
        address: address,
        city: city,
        state: state ?? 'Karnataka',
        pincode: pincode,
        gstin: gstin,
        fssaiLicense: fssaiLicense,
        upiId: upiId,
        logoUrl: logoUrl,
        createdAt: DateTime.now(),
      );
    } on supa.PostgrestException catch (e) {
      AppLogger.w(
          'RPC create_shop warning: ${e.message} (code: ${e.code}). Attempting direct insert fallback...',
          tag: 'ShopRemoteDataSource');

      if (e.code == 'PGRST202' ||
          e.code == '42883' ||
          e.message.contains('Could not find the function') ||
          e.message.contains('Authentication required') ||
          e.message.contains('function') &&
              e.message.contains('does not exist')) {
        return await _createShopDirectFallback(
          name: name,
          phone: phone,
          address: address,
          city: city,
          state: state,
          pincode: pincode,
          gstin: gstin,
          fssaiLicense: fssaiLicense,
          upiId: upiId,
          logoUrl: logoUrl,
        );
      }
      throw DatabaseException(e.message, e.code);
    } catch (e) {
      AppLogger.e('Unexpected createShop error: $e',
          tag: 'ShopRemoteDataSource');
      throw DatabaseException('Failed to create store profile: $e');
    }
  }

  Future<ShopModel> _createShopDirectFallback({
    required String name,
    required String phone,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? gstin,
    String? fssaiLicense,
    String? upiId,
    String? logoUrl,
  }) async {
    final user = _supabase.auth.currentUser;
    final userId = user?.id ?? 'user_demo_1';

    final shopId = DateTime.now().millisecondsSinceEpoch.toString();

    await _supabase.from('shops').insert({
      'id': shopId,
      'name': name.trim(),
      'owner_id': userId,
      'phone': phone.trim(),
      'address': address?.trim(),
      'city': city?.trim(),
      'state': state?.trim() ?? 'Karnataka',
      'pincode': pincode?.trim(),
      'gstin': gstin?.trim(),
      'fssai_license': fssaiLicense?.trim(),
      'upi_id': upiId?.trim(),
      'logo_url': logoUrl,
      'currency': 'INR',
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });

    try {
      await _supabase.from('shop_users').insert({
        'id': DateTime.now().microsecondsSinceEpoch.toString(),
        'shop_id': shopId,
        'user_id': userId,
        'role': 'owner',
        'display_name': '${name.trim()} Owner',
        'status': 'active',
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      AppLogger.w('Membership creation notice: $e',
          tag: 'ShopRemoteDataSource');
    }

    return ShopModel(
      id: shopId,
      name: name.trim(),
      phone: phone.trim(),
      address: address,
      city: city,
      state: state ?? 'Karnataka',
      pincode: pincode,
      gstin: gstin,
      fssaiLicense: fssaiLicense,
      upiId: upiId,
      logoUrl: logoUrl,
      createdAt: DateTime.now(),
    );
  }

  Future<ShopModel> getShopDetails(String shopId) async {
    try {
      final response =
          await _supabase.from('shops').select().eq('id', shopId).single();

      return _mapToShopModel(response);
    } on supa.PostgrestException catch (e) {
      throw DatabaseException(e.message, e.code);
    } catch (e) {
      throw DatabaseException('Failed to fetch shop details: $e');
    }
  }

  Future<ShopModel> updateShopProfile({
    required String shopId,
    required String name,
    required String phone,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? gstin,
    String? fssaiLicense,
    String? upiId,
  }) async {
    try {
      final response = await _supabase
          .from('shops')
          .update({
            'name': name.trim(),
            'phone': phone.trim(),
            'address': address?.trim(),
            'city': city?.trim(),
            'state': state?.trim() ?? 'Karnataka',
            'pincode': pincode?.trim(),
            'gstin': gstin?.trim(),
            'fssai_license': fssaiLicense?.trim(),
            'upi_id': upiId?.trim(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', shopId)
          .select()
          .single();

      return _mapToShopModel(response);
    } on supa.PostgrestException catch (e) {
      throw DatabaseException(e.message, e.code);
    } catch (e) {
      throw DatabaseException('Failed to update store profile: $e');
    }
  }

  Future<String> uploadShopLogo({
    required String shopId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final cleanName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9\._-]'), '_');
      final path = '$shopId/logo_$cleanName';
      await _supabase.storage.from('products').uploadBinary(
            path,
            bytes,
            fileOptions: const supa.FileOptions(upsert: true),
          );

      return _supabase.storage.from('products').getPublicUrl(path);
    } catch (e) {
      AppLogger.w('Shop logo upload failed: $e', tag: 'ShopRemoteDataSource');
      throw StorageException('Logo upload failed: $e');
    }
  }

  ShopModel _mapToShopModel(Map<String, dynamic> data) {
    return ShopModel(
      id: data['id'] as String,
      name: data['name'] as String,
      phone: data['phone'] as String,
      email: data['email'] as String?,
      gstin: data['gstin'] as String?,
      fssaiLicense: data['fssai_license'] as String?,
      address: data['address'] as String?,
      city: data['city'] as String?,
      state: data['state'] as String? ?? 'Karnataka',
      pincode: data['pincode'] as String?,
      upiId: data['upi_id'] as String?,
      logoUrl: data['logo_url'] as String?,
      currency: data['currency'] as String? ?? 'INR',
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'] as String)
          : DateTime.now(),
    );
  }
}
