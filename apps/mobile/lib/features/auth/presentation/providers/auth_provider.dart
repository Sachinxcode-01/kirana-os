import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/app_providers.dart';
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

  AuthNotifier(this._repository) : super(AuthStateModel.initializing()) {
    restoreSession();
  }

  Future<void> restoreSession() async {
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

  Future<bool> sendPasswordReset(String email) async {
    final result = await _repository.sendPasswordResetEmail(email: email);
    return result.isSuccess;
  }

  Future<bool> updatePassword(String newPassword) async {
    final result = await _repository.updatePassword(newPassword: newPassword);
    return result.isSuccess;
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
  return AuthNotifier(repository);
});
