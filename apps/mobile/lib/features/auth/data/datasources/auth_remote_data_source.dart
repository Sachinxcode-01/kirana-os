import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/models/auth_state_model.dart';

class AuthRemoteDataSource {
  final supabase.SupabaseClient? _client;

  AuthRemoteDataSource([this._client]);

  supabase.SupabaseClient get _supabase {
    if (_client != null) return _client;
    try {
      return supabase.Supabase.instance.client;
    } catch (e) {
      AppLogger.w('Supabase instance not initialized, using offline fallback',
          tag: 'AuthRemoteDataSource');
      throw const NetworkException('Supabase connection not initialized');
    }
  }

  Future<UserModel> login(
      {required String email, required String password}) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw const AuthException('No user returned from authentication');
      }

      // Fetch shop membership from shop_users
      final shopUsers = await _supabase
          .from('shop_users')
          .select('shop_id, role, display_name')
          .eq('user_id', user.id)
          .eq('status', 'active')
          .maybeSingle();

      final shopId = shopUsers?['shop_id'] as String? ?? 'default_shop';
      final role = shopUsers?['role'] as String? ?? 'cashier';
      final displayName =
          shopUsers?['display_name'] as String? ?? user.email ?? 'Staff';

      return UserModel(
        id: user.id,
        email: user.email ?? email,
        phone: user.phone,
        displayName: displayName,
        role: role,
        shopId: shopId,
      );
    } on supabase.AuthException catch (e) {
      AppLogger.e('Supabase Auth error: ${e.message}',
          tag: 'AuthRemoteDataSource');
      throw AuthException(e.message, e.statusCode);
    } catch (e) {
      AppLogger.e('Unexpected login error: $e', tag: 'AuthRemoteDataSource');
      throw AuthException(e.toString());
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

      final shopUsers = await _supabase
          .from('shop_users')
          .select('shop_id, role, display_name')
          .eq('user_id', user.id)
          .eq('status', 'active')
          .maybeSingle();

      final shopId = shopUsers?['shop_id'] as String? ?? 'default_shop';
      final role = shopUsers?['role'] as String? ?? 'cashier';
      final displayName =
          shopUsers?['display_name'] as String? ?? user.email ?? 'Staff';

      return UserModel(
        id: user.id,
        email: user.email ?? '',
        phone: user.phone,
        displayName: displayName,
        role: role,
        shopId: shopId,
      );
    } catch (e) {
      AppLogger.w('Could not restore remote session: $e',
          tag: 'AuthRemoteDataSource');
      return null;
    }
  }
}
