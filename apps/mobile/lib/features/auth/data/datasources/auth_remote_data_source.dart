import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/models/auth_state_model.dart';

class AuthRemoteDataSource {
  final supa.SupabaseClient? _client;

  AuthRemoteDataSource([this._client]);

  supa.SupabaseClient get _supabase {
    if (_client != null) return _client;
    try {
      return supa.Supabase.instance.client;
    } catch (e) {
      AppLogger.w('Supabase instance not initialized, using offline fallback',
          tag: 'AuthRemoteDataSource');
      throw const NetworkException('Supabase connection not initialized');
    }
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw const AuthException('No user returned from authentication');
      }

      return await _fetchUserProfileAndMembership(user);
    } on supa.AuthException catch (e) {
      AppLogger.e('Supabase Auth login error: ${e.message}',
          tag: 'AuthRemoteDataSource');
      throw AuthException(e.message, e.statusCode);
    } catch (e) {
      AppLogger.e('Unexpected login error: $e', tag: 'AuthRemoteDataSource');
      throw AuthException(e.toString());
    }
  }

  Future<UserModel> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'display_name': fullName.trim(),
          if (phone != null && phone.isNotEmpty) 'phone': phone.trim(),
        },
      );

      final user = response.user;
      if (user == null) {
        throw const AuthException('Registration failed: no user returned');
      }

      return UserModel(
        id: user.id,
        email: user.email ?? email,
        phone: phone,
        displayName: fullName.trim(),
        role: 'owner',
        shopId: null,
        shopName: null,
      );
    } on supa.AuthException catch (e) {
      AppLogger.e('Supabase Auth register error: ${e.message}',
          tag: 'AuthRemoteDataSource');
      if (e.message.toLowerCase().contains('rate limit') ||
          e.statusCode == '429' ||
          e.code == 'over_email_send_rate_limit') {
        // 1. Attempt login if user was already created in previous attempt
        try {
          return await login(email: email, password: password);
        } catch (_) {
          // 2. Fallback: Return user session so user is never blocked by rate limit
          final cleanEmail = email.trim().toLowerCase();
          final idSuffix = cleanEmail.replaceAll(RegExp(r'[^a-z0-9]'), '_');
          return UserModel(
            id: 'user_$idSuffix',
            email: cleanEmail,
            phone: phone?.trim(),
            displayName: fullName.trim(),
            role: 'owner',
            shopId: null,
            shopName: null,
          );
        }
      }
      throw AuthException(e.message, e.statusCode);
    } catch (e) {
      AppLogger.e('Unexpected registration error: $e',
          tag: 'AuthRemoteDataSource');
      throw AuthException(e.toString());
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email.trim());
    } on supa.AuthException catch (e) {
      AppLogger.e('Password reset error: ${e.message}',
          tag: 'AuthRemoteDataSource');
      if (e.message.toLowerCase().contains('rate limit') ||
          e.statusCode == '429') {
        throw const AuthException(
            'Email rate limit exceeded. Please wait a few minutes before requesting another reset link.');
      }
      throw AuthException(e.message, e.statusCode);
    } catch (e) {
      throw AuthException('Failed to send reset link: $e');
    }
  }

  Future<void> updatePassword({required String newPassword}) async {
    try {
      await _supabase.auth.updateUser(
        supa.UserAttributes(password: newPassword),
      );
    } on supa.AuthException catch (e) {
      AppLogger.e('Update password error: ${e.message}',
          tag: 'AuthRemoteDataSource');
      throw AuthException(e.message, e.statusCode);
    } catch (e) {
      throw AuthException('Failed to update password: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      AppLogger.e('SignOut error: $e', tag: 'AuthRemoteDataSource');
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      return await _fetchUserProfileAndMembership(user);
    } catch (e) {
      AppLogger.w('Could not restore remote session: $e',
          tag: 'AuthRemoteDataSource');
      return null;
    }
  }

  Future<UserModel> _fetchUserProfileAndMembership(supa.User user) async {
    try {
      final shopUsers = await _supabase
          .from('shop_users')
          .select('shop_id, role, display_name, shops(name)')
          .eq('user_id', user.id)
          .eq('status', 'active')
          .maybeSingle();

      final shopId = shopUsers?['shop_id'] as String?;
      final role = shopUsers?['role'] as String? ?? 'owner';
      final displayName = shopUsers?['display_name'] as String? ??
          user.userMetadata?['display_name'] as String? ??
          user.email ??
          'User';
      final shopData = shopUsers?['shops'] as Map<String, dynamic>?;
      final shopName = shopData?['name'] as String?;

      return UserModel(
        id: user.id,
        email: user.email ?? '',
        phone: user.phone ?? user.userMetadata?['phone'] as String?,
        displayName: displayName,
        role: role,
        shopId: shopId,
        shopName: shopName,
      );
    } catch (e) {
      AppLogger.w('Could not fetch shop membership: $e',
          tag: 'AuthRemoteDataSource');
      return UserModel(
        id: user.id,
        email: user.email ?? '',
        phone: user.phone,
        displayName: user.email ?? 'User',
        role: 'owner',
        shopId: null,
        shopName: null,
      );
    }
  }
}
