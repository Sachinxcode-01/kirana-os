import 'package:flutter/foundation.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/models/auth_state_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource? _localDataSource;
  final SecureStorageService _secureStorage;

  static const String _quickPinKey = 'user_quick_pin';

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    AuthLocalDataSource? localDataSource,
    required SecureStorageService secureStorage,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _secureStorage = secureStorage;

  @override
  Future<Result<UserModel, Failure>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _remoteDataSource.login(
        email: email,
        password: password,
      );
      await _localDataSource?.saveUserProfile(user, syncStatus: 'SYNCED');
      return Success(user);
    } catch (e) {
      return ErrorResult(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Result<UserModel, Failure>> registerWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      final user = await _remoteDataSource.register(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
      await _localDataSource?.saveUserProfile(user, syncStatus: 'SYNCED');
      return Success(user);
    } catch (e) {
      return ErrorResult(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Result<void, Failure>> signInWithGoogle() async {
    try {
      await _remoteDataSource.signInWithGoogle();
      return const Success(null);
    } catch (e) {
      return ErrorResult(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Result<void, Failure>> resendVerificationEmail({
    required String email,
  }) async {
    try {
      await _remoteDataSource.resendVerificationEmail(email: email);
      return const Success(null);
    } catch (e) {
      return ErrorResult(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Result<void, Failure>> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      await _remoteDataSource.sendPasswordResetEmail(email: email);
      return const Success(null);
    } catch (e) {
      return ErrorResult(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Result<void, Failure>> updatePassword({
    required String newPassword,
  }) async {
    try {
      await _remoteDataSource.updatePassword(newPassword: newPassword);
      return const Success(null);
    } catch (e) {
      return ErrorResult(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Result<void, Failure>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _remoteDataSource.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return const Success(null);
    } catch (e) {
      return ErrorResult(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Result<void, Failure>> logout() async {
    try {
      await _remoteDataSource.signOut();
      await _localDataSource?.clearAllUserProfiles();
      _remoteDataSource.unsubscribeUserRealtime();
      return const Success(null);
    } catch (e) {
      return ErrorResult(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Result<UserModel?, Failure>> restoreSession() async {
    try {
      final remoteUser = await _remoteDataSource.getCurrentUser();
      if (remoteUser != null) {
        await _localDataSource?.saveUserProfile(remoteUser,
            syncStatus: 'SYNCED');
        return Success(remoteUser);
      }
    } catch (_) {
      // Remote restoration failed or device is offline: fallback to local cache
    }

    // Fallback or Recovery from Local Cache
    try {
      // If we have an active user ID from Supabase auth state or local storage
      final cachedUser = await _localDataSource?.getUserProfile('current');
      if (cachedUser != null) {
        return Success(cachedUser);
      }
    } catch (_) {}

    return const Success(null);
  }

  @override
  void subscribeUserRealtime({
    required String userId,
    required VoidCallback onDataChanged,
  }) {
    _remoteDataSource.subscribeUserRealtime(
      userId: userId,
      onDataChanged: onDataChanged,
    );
  }

  @override
  void unsubscribeUserRealtime() {
    _remoteDataSource.unsubscribeUserRealtime();
  }

  @override
  Future<Result<bool, Failure>> verifyQuickPin(String pin) async {
    try {
      final savedPin = await _secureStorage.read(_quickPinKey);
      if (savedPin == null) {
        return const Success(false);
      }
      return Success(savedPin == pin);
    } catch (e) {
      return ErrorResult(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Result<void, Failure>> setQuickPin(String pin) async {
    try {
      await _secureStorage.write(_quickPinKey, pin);
      return const Success(null);
    } catch (e) {
      return ErrorResult(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Result<void, Failure>> requestAccountDeletion({
    required String currentPassword,
    String? reason,
  }) async {
    try {
      await _remoteDataSource.requestAccountDeletion(
        currentPassword: currentPassword,
        reason: reason,
      );
      await _localDataSource?.clearAllUserProfiles();
      _remoteDataSource.unsubscribeUserRealtime();
      return const Success(null);
    } catch (e) {
      return ErrorResult(ErrorHandler.handle(e));
    }
  }
}
