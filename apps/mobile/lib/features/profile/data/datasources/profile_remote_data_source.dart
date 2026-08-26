import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../auth/domain/models/auth_state_model.dart';

class ProfileRemoteDataSource {
  final supa.SupabaseClient? _client;

  ProfileRemoteDataSource([this._client]);

  supa.SupabaseClient get _supabase {
    if (_client != null) return _client;
    try {
      return supa.Supabase.instance.client;
    } catch (e) {
      throw const NetworkException('Supabase connection not initialized');
    }
  }

  Future<UserModel> updateProfile({
    required String fullName,
    required String phone,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('No active user session found.');
    }

    try {
      // 1. Update Supabase Auth User Metadata
      final response = await _supabase.auth.updateUser(
        supa.UserAttributes(
          data: {
            'full_name': fullName.trim(),
            'display_name': fullName.trim(),
            'phone': phone.trim(),
          },
        ),
      );

      final updatedUser = response.user ?? user;

      // 2. Persist directly into public.profiles table in Supabase
      try {
        await _supabase.from('profiles').upsert({
          'id': user.id,
          'full_name': fullName.trim(),
          'email': user.email ?? '',
          'phone': phone.trim(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
      } catch (profileError) {
        AppLogger.w('Notice: Could not upsert public.profiles: $profileError',
            tag: 'ProfileRemoteDataSource');
      }

      // 3. Update shop_users display_name if exists
      try {
        await _supabase
            .from('shop_users')
            .update({'display_name': fullName.trim()}).eq('user_id', user.id);
      } catch (e) {
        AppLogger.w('Notice: Could not update shop_users display_name: $e',
            tag: 'ProfileRemoteDataSource');
      }

      final avatarUrl = updatedUser.userMetadata?['avatar_url'] as String?;

      return UserModel(
        id: updatedUser.id,
        email: updatedUser.email ?? '',
        phone: phone.trim(),
        displayName: fullName.trim(),
        role: 'owner',
        avatarUrl: avatarUrl,
      );
    } on supa.AuthException catch (e) {
      throw AuthException(e.message, e.statusCode);
    } catch (e) {
      throw DatabaseException('Failed to update profile: $e');
    }
  }

  Future<String> uploadProfilePhoto({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('No active user session found.');
    }

    try {
      final cleanName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9\._-]'), '_');
      final path = 'profiles/${user.id}/avatar_$cleanName';

      await _supabase.storage.from('products').uploadBinary(
            path,
            bytes,
            fileOptions: const supa.FileOptions(upsert: true),
          );

      final publicUrl = _supabase.storage.from('products').getPublicUrl(path);

      await _supabase.auth.updateUser(
        supa.UserAttributes(
          data: {
            'avatar_url': publicUrl,
          },
        ),
      );

      // Persist avatar_url in public.profiles table
      try {
        await _supabase.from('profiles').upsert({
          'id': user.id,
          'avatar_url': publicUrl,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
      } catch (e) {
        AppLogger.w(
            'Notice: Could not update avatar_url in public.profiles: $e',
            tag: 'ProfileRemoteDataSource');
      }

      return publicUrl;
    } catch (e) {
      AppLogger.e('Profile photo upload error: $e',
          tag: 'ProfileRemoteDataSource');
      throw DatabaseException('Failed to upload profile photo: $e');
    }
  }

  Future<void> removeProfilePhoto() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase.auth.updateUser(
        supa.UserAttributes(
          data: {
            'avatar_url': null,
          },
        ),
      );

      try {
        await _supabase.from('profiles').update({
          'avatar_url': null,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', user.id);
      } catch (e) {
        AppLogger.w('Notice: Could not clear avatar_url in public.profiles: $e',
            tag: 'ProfileRemoteDataSource');
      }
    } catch (e) {
      throw DatabaseException('Failed to remove profile photo: $e');
    }
  }
}
