import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../../../app/app_providers.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/models/auth_state_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return AuthRepositoryImpl(
    remoteDataSource: remoteDataSource,
    secureStorage: secureStorage,
  );
});

class AuthNotifier extends StateNotifier<AuthStateModel> {
  final AuthRepository _repository;
  final AuthRemoteDataSource _remoteDataSource;
  StreamSubscription<supa.AuthState>? _authSubscription;

  AuthNotifier(this._repository, this._remoteDataSource)
      : super(AuthStateModel.initializing()) {
    _initAuthListener();
  }

  void _initAuthListener() {
    restoreSession();
    try {
      _authSubscription = _remoteDataSource.onAuthStateChange.listen(
        (data) async {
          final event = data.event;
          AppLogger.d('Auth state change event: $event', tag: 'AuthNotifier');

          switch (event) {
            case supa.AuthChangeEvent.signedIn:
            case supa.AuthChangeEvent.tokenRefreshed:
            case supa.AuthChangeEvent.userUpdated:
              await restoreSession();
              break;
            case supa.AuthChangeEvent.signedOut:
              state = AuthStateModel.unauthenticated();
              break;
            case supa.AuthChangeEvent.passwordRecovery:
              // Keep authenticated or prompt reset screen
              break;
            case supa.AuthChangeEvent.initialSession:
              // Handled by restoreSession()
              break;
            default:
              break;
          }
        },
        onError: (error) {
          AppLogger.e('Auth subscription error: $error', tag: 'AuthNotifier');
        },
      );
    } catch (e) {
      AppLogger.w('Failed to listen to auth state changes: $e',
          tag: 'AuthNotifier');
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> restoreSession() async {
    try {
      final result = await _repository.restoreSession();
      result.fold(
        (user) {
          if (user != null) {
            if (user.shopId != null && user.shopId!.isNotEmpty) {
              state = AuthStateModel.authenticatedWithShop(
                user: user,
                shopId: user.shopId!,
                shopName: user.shopName ?? 'My Kirana Store',
              );
            } else {
              state = AuthStateModel.authenticatedWithoutShop(user);
            }
          } else {
            state = AuthStateModel.unauthenticated();
          }
        },
        (failure) {
          state = AuthStateModel.unauthenticated();
        },
      );
    } catch (_) {
      state = AuthStateModel.unauthenticated();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = const AuthStateModel(status: AuthStatus.authenticating);
    final result =
        await _repository.loginWithEmail(email: email, password: password);
    return result.fold(
      (user) {
        if (user.shopId != null && user.shopId!.isNotEmpty) {
          state = AuthStateModel.authenticatedWithShop(
            user: user,
            shopId: user.shopId!,
            shopName: user.shopName ?? 'My Kirana Store',
          );
        } else {
          state = AuthStateModel.authenticatedWithoutShop(user);
        }
        return true;
      },
      (failure) {
        state = AuthStateModel.error(failure.message);
        return false;
      },
    );
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    state = const AuthStateModel(status: AuthStatus.authenticating);
    final result = await _repository.registerWithEmail(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
    );
    return result.fold(
      (user) {
        state = AuthStateModel.authenticatedWithoutShop(user);
        return true;
      },
      (failure) {
        state = AuthStateModel.error(failure.message);
        return false;
      },
    );
  }

  Future<bool> resendVerificationEmail(String email) async {
    final result = await _repository.resendVerificationEmail(email: email);
    return result.fold(
      (_) => true,
      (failure) {
        state = AuthStateModel.error(failure.message);
        return false;
      },
    );
  }

  Future<bool> sendPasswordReset(String email) async {
    final result = await _repository.sendPasswordResetEmail(email: email);
    return result.fold(
      (_) => true,
      (failure) {
        state = AuthStateModel.error(failure.message);
        return false;
      },
    );
  }

  Future<bool> updatePassword(String newPassword) async {
    final result = await _repository.updatePassword(newPassword: newPassword);
    return result.fold(
      (_) => true,
      (failure) {
        state = AuthStateModel.error(failure.message);
        return false;
      },
    );
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final result = await _repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    return result.fold(
      (_) => true,
      (failure) {
        state = AuthStateModel.error(failure.message);
        return false;
      },
    );
  }

  Future<bool> requestAccountDeletion({
    required String currentPassword,
    String? reason,
  }) async {
    final result = await _repository.requestAccountDeletion(
      currentPassword: currentPassword,
      reason: reason,
    );
    return result.fold(
      (_) {
        state = AuthStateModel.unauthenticated();
        return true;
      },
      (failure) {
        state = AuthStateModel.error(failure.message);
        return false;
      },
    );
  }

  void updateActiveShop({
    required String shopId,
    required String shopName,
  }) {
    if (state.user != null) {
      final updatedUser = state.user!.copyWith(
        shopId: shopId,
        shopName: shopName,
      );
      state = AuthStateModel.authenticatedWithShop(
        user: updatedUser,
        shopId: shopId,
        shopName: shopName,
      );
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = AuthStateModel.unauthenticated();
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthStateModel>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  return AuthNotifier(repository, remoteDataSource);
});
