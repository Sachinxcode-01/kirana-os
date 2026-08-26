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
      AppLogger.w('Supabase instance not initialized',
          tag: 'AuthRemoteDataSource');
      throw const NetworkException('Supabase connection not initialized');
    }
  }

  Stream<supa.AuthState> get onAuthStateChange =>
      _supabase.auth.onAuthStateChange;

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
      if (e.message.toLowerCase().contains('email not confirmed')) {
        throw AuthException(
          'Email not confirmed. Please check your inbox to verify your email address.',
          e.statusCode,
        );
      }
      if (e.message.toLowerCase().contains('invalid login credentials')) {
        throw AuthException(
          'Invalid email or password. Please try again.',
          e.statusCode,
        );
      }
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
          'full_name': fullName.trim(),
          'display_name': fullName.trim(),
          if (phone != null && phone.isNotEmpty) 'phone': phone.trim(),
        },
      );

      final user = response.user;
      if (user == null) {
        throw const AuthException('Registration failed: no user returned');
      }

      // Explicitly persist profile into public.profiles table
      try {
        await _supabase.from('profiles').upsert({
          'id': user.id,
          'full_name': fullName.trim(),
          'email': user.email ?? email.trim(),
          if (phone != null && phone.isNotEmpty) 'phone': phone.trim(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
      } catch (profileError) {
        AppLogger.w('Profile upsert warning during registration: $profileError',
            tag: 'AuthRemoteDataSource');
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
        throw const AuthException(
          'Email rate limit exceeded. Please wait a few minutes before registering again.',
        );
      }
      if (e.message.toLowerCase().contains('already registered') ||
          e.message.toLowerCase().contains('user_already_exists')) {
        throw const AuthException(
          'User with this email is already registered. Please sign in instead.',
        );
      }
      throw AuthException(e.message, e.statusCode);
    } catch (e) {
      AppLogger.e('Unexpected registration error: $e',
          tag: 'AuthRemoteDataSource');
      throw AuthException(e.toString());
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(
        supa.OAuthProvider.google,
        redirectTo: 'io.supabase.kirana://login-callback/',
      );
    } on supa.AuthException catch (e) {
      AppLogger.e('Google OAuth error: ${e.message}',
          tag: 'AuthRemoteDataSource');
      throw AuthException(e.message, e.statusCode);
    } catch (e) {
      throw AuthException('Failed to initiate Google sign in: $e');
    }
  }

  Future<void> resendVerificationEmail({required String email}) async {
    try {
      await _supabase.auth.resend(
        type: supa.OtpType.signup,
        email: email.trim(),
      );
    } on supa.AuthException catch (e) {
      AppLogger.e('Resend verification email error: ${e.message}',
          tag: 'AuthRemoteDataSource');
      if (e.message.toLowerCase().contains('rate limit') ||
          e.statusCode == '429') {
        throw const AuthException(
          'Email rate limit exceeded. Please wait a few minutes before requesting another email.',
        );
      }
      throw AuthException(e.message, e.statusCode);
    } catch (e) {
      throw AuthException('Failed to resend verification email: $e');
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: 'io.supabase.kirana://reset-password/',
      );
    } on supa.AuthException catch (e) {
      AppLogger.e('Password reset error: ${e.message}',
          tag: 'AuthRemoteDataSource');
      if (e.message.toLowerCase().contains('rate limit') ||
          e.statusCode == '429') {
        throw const AuthException(
          'Email rate limit exceeded. Please wait a few minutes before requesting another reset link.',
        );
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

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null || user.email == null) {
        throw const AuthException('No active session. Please sign in again.');
      }

      await _supabase.auth.signInWithPassword(
        email: user.email!,
        password: currentPassword,
      );

      await _supabase.auth.updateUser(
        supa.UserAttributes(password: newPassword),
      );
    } on supa.AuthException catch (e) {
      AppLogger.e('Change password error: ${e.message}',
          tag: 'AuthRemoteDataSource');
      if (e.message.toLowerCase().contains('invalid login credentials')) {
        throw const AuthException('Current password is incorrect.');
      }
      throw AuthException(e.message, e.statusCode);
    } catch (e) {
      throw AuthException('Failed to change password: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      AppLogger.e('SignOut error: $e', tag: 'AuthRemoteDataSource');
    }
  }

  Future<void> requestAccountDeletion({
    required String currentPassword,
    String? reason,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null || user.email == null) {
        throw const AuthException('No active session. Please sign in again.');
      }

      // Re-authenticate user
      await _supabase.auth.signInWithPassword(
        email: user.email!,
        password: currentPassword,
      );

      // Record deletion request in metadata safely without destroying shop financial ledgers
      await _supabase.auth.updateUser(
        supa.UserAttributes(
          data: {
            'deletion_requested': true,
            'deletion_requested_at': DateTime.now().toUtc().toIso8601String(),
            if (reason != null && reason.isNotEmpty)
              'deletion_reason': reason.trim(),
          },
        ),
      );

      try {
        await _supabase
            .from('shop_users')
            .update({'status': 'deletion_requested'}).eq('user_id', user.id);
      } catch (e) {
        AppLogger.w(
            'Notice: Could not update shop_users status to deletion_requested: $e',
            tag: 'AuthRemoteDataSource');
      }

      // Sign out cleanly
      await signOut();
    } on supa.AuthException catch (e) {
      AppLogger.e('Delete account request error: ${e.message}',
          tag: 'AuthRemoteDataSource');
      if (e.message.toLowerCase().contains('invalid login credentials')) {
        throw const AuthException('Current password is incorrect.');
      }
      throw AuthException(e.message, e.statusCode);
    } catch (e) {
      throw AuthException('Failed to process account deletion request: $e');
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
    Map<String, dynamic>? profileData;

    // 1. Query public.profiles table
    try {
      profileData = await _supabase
          .from('profiles')
          .select('full_name, email, phone, avatar_url')
          .eq('id', user.id)
          .maybeSingle();

      if (profileData == null) {
        // Upsert if missing
        final name = user.userMetadata?['full_name'] as String? ??
            user.userMetadata?['display_name'] as String? ??
            user.userMetadata?['name'] as String? ??
            user.email?.split('@').first ??
            'User';
        final phone = user.phone ?? user.userMetadata?['phone'] as String?;
        final avatar = user.userMetadata?['avatar_url'] as String?;

        await _supabase.from('profiles').upsert({
          'id': user.id,
          'full_name': name,
          'email': user.email ?? '',
          'phone': phone,
          'avatar_url': avatar,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });

        profileData = {
          'full_name': name,
          'email': user.email ?? '',
          'phone': phone,
          'avatar_url': avatar,
        };
      }
    } catch (e) {
      AppLogger.w('Notice: Could not fetch public.profiles: $e',
          tag: 'AuthRemoteDataSource');
    }

    // 2. Query shop_users membership table
    try {
      final shopUsers = await _supabase
          .from('shop_users')
          .select('shop_id, role, display_name, shops(name)')
          .eq('user_id', user.id)
          .eq('status', 'active')
          .maybeSingle();

      final shopId = shopUsers?['shop_id'] as String?;
      final role = shopUsers?['role'] as String? ?? 'owner';
      final displayName = profileData?['full_name'] as String? ??
          shopUsers?['display_name'] as String? ??
          user.userMetadata?['display_name'] as String? ??
          user.email ??
          'User';
      final shopData = shopUsers?['shops'] as Map<String, dynamic>?;
      final shopName = shopData?['name'] as String?;
      final avatarUrl = profileData?['avatar_url'] as String? ??
          user.userMetadata?['avatar_url'] as String?;
      final phone = profileData?['phone'] as String? ??
          user.phone ??
          user.userMetadata?['phone'] as String?;

      return UserModel(
        id: user.id,
        email: profileData?['email'] as String? ?? user.email ?? '',
        phone: phone,
        displayName: displayName,
        role: role,
        avatarUrl: avatarUrl,
        shopId: shopId,
        shopName: shopName,
      );
    } catch (e) {
      AppLogger.w('Could not fetch shop membership: $e',
          tag: 'AuthRemoteDataSource');
      return UserModel(
        id: user.id,
        email: profileData?['email'] as String? ?? user.email ?? '',
        phone: profileData?['phone'] as String? ?? user.phone,
        displayName: profileData?['full_name'] as String? ??
            user.email?.split('@').first ??
            'User',
        role: 'owner',
        avatarUrl: profileData?['avatar_url'] as String? ??
            user.userMetadata?['avatar_url'] as String?,
        shopId: null,
        shopName: null,
      );
    }
  }
}
