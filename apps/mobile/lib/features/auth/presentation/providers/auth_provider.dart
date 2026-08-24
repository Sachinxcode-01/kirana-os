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
          state = AuthStateModel.authenticated(user, user.shopId);
        } else {
          state = AuthStateModel.unauthenticated();
        }
      },
      (failure) {
        state = AuthStateModel.unauthenticated();
      },
    );
  }

  Future<bool> login(String email, String password) async {
    state = const AuthStateModel(status: AuthStatus.authenticating);
    final result =
        await _repository.loginWithEmail(email: email, password: password);
    return result.fold(
      (user) {
        state = AuthStateModel.authenticated(user, user.shopId);
        return true;
      },
      (failure) {
        state = AuthStateModel.error(failure.message);
        return false;
      },
    );
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
