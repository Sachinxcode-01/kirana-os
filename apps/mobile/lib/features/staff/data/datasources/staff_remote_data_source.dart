import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/models/staff_member_model.dart';

class StaffRemoteDataSource {
  final supa.SupabaseClient? _client;

  StaffRemoteDataSource([this._client]);

  supa.SupabaseClient get _supabase {
    if (_client != null) return _client;
    try {
      return supa.Supabase.instance.client;
    } catch (e) {
      throw const NetworkException('Supabase connection not initialized');
    }
  }

  Future<List<StaffMemberModel>> getShopStaff(String shopId) async {
    try {
      final response = await _supabase
          .from('shop_users')
          .select()
          .eq('shop_id', shopId)
          .order('created_at', ascending: false);

      final list = (response as List<dynamic>)
          .map(
              (json) => StaffMemberModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return list;
    } on supa.PostgrestException catch (e) {
      AppLogger.e('Get shop staff error: ${e.message}',
          tag: 'StaffRemoteDataSource');
      throw DatabaseException(e.message, e.code);
    } catch (e) {
      AppLogger.e('Get shop staff unexpected error: $e',
          tag: 'StaffRemoteDataSource');
      throw DatabaseException('Failed to fetch staff members: $e');
    }
  }

  Future<StaffMemberModel> inviteStaff({
    required String shopId,
    required String email,
    required StaffRole role,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    try {
      // 1. Check for duplicate existing membership or pending invitation
      final existing = await _supabase
          .from('shop_users')
          .select()
          .eq('shop_id', shopId)
          .eq('email', cleanEmail);

      final existingList = existing as List<dynamic>;
      if (existingList.isNotEmpty) {
        final existingStatus =
            existingList.first['status'] as String? ?? 'active';
        if (existingStatus != 'deactivated') {
          throw const ValidationException(
              'An active or pending staff membership already exists for this email address.');
        }
      }

      // 2. Insert pending staff invitation in shop_users
      final newId = 'staff_inv_${DateTime.now().millisecondsSinceEpoch}';
      final nowStr = DateTime.now().toUtc().toIso8601String();

      final insertData = {
        'id': newId,
        'shop_id': shopId,
        'email': cleanEmail,
        'display_name': cleanEmail.split('@').first,
        'role': role.value,
        'status': StaffStatus.pending.value,
        'created_at': nowStr,
      };

      try {
        await _supabase.from('shop_users').insert(insertData);
      } catch (e) {
        AppLogger.w('Notice inserting shop_users invitation: $e',
            tag: 'StaffRemoteDataSource');
      }

      return StaffMemberModel(
        id: newId,
        shopId: shopId,
        email: cleanEmail,
        displayName: cleanEmail.split('@').first,
        role: role,
        status: StaffStatus.pending,
        createdAt: DateTime.now(),
      );
    } on supa.PostgrestException catch (e) {
      AppLogger.e('Invite staff Postgrest error: ${e.message}',
          tag: 'StaffRemoteDataSource');
      throw DatabaseException(e.message, e.code);
    } on ValidationException {
      rethrow;
    } catch (e) {
      AppLogger.e('Invite staff unexpected error: $e',
          tag: 'StaffRemoteDataSource');
      throw DatabaseException('Failed to send staff invitation: $e');
    }
  }

  Future<StaffMemberModel> updateStaffRole({
    required String membershipId,
    required StaffRole newRole,
  }) async {
    try {
      final response = await _supabase
          .from('shop_users')
          .update({'role': newRole.value})
          .eq('id', membershipId)
          .select()
          .single();

      return StaffMemberModel.fromJson(response);
    } on supa.PostgrestException catch (e) {
      AppLogger.e('Update staff role error: ${e.message}',
          tag: 'StaffRemoteDataSource');
      throw DatabaseException(e.message, e.code);
    } catch (e) {
      AppLogger.e('Update staff role unexpected error: $e',
          tag: 'StaffRemoteDataSource');
      throw DatabaseException('Failed to update staff role: $e');
    }
  }

  Future<StaffMemberModel> updateStaffStatus({
    required String membershipId,
    required StaffStatus newStatus,
  }) async {
    try {
      final response = await _supabase
          .from('shop_users')
          .update({'status': newStatus.value})
          .eq('id', membershipId)
          .select()
          .single();

      return StaffMemberModel.fromJson(response);
    } on supa.PostgrestException catch (e) {
      AppLogger.e('Update staff status error: ${e.message}',
          tag: 'StaffRemoteDataSource');
      throw DatabaseException(e.message, e.code);
    } catch (e) {
      AppLogger.e('Update staff status unexpected error: $e',
          tag: 'StaffRemoteDataSource');
      throw DatabaseException('Failed to update staff status: $e');
    }
  }
}
