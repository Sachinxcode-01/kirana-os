import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/models/auth_state_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final SecureStorageService _secureStorage;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required SecureStorageService secureStorage,
  })  : _remoteDataSource = remoteDataSource,
        _secureStorage = secureStorage;

  @override
  Future<Result<UserModel, Failure>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final user =
          await _remoteDataSource.login(email: email, password: password);
      await _secureStorage.write(AppConstants.keyActiveShopId, user.shopId);
      return Success(user);
    } catch (e) {
      return ErrorResult(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Result<UserModel, Failure>> registerWithEmail({
    required String email,
    required String password,
    required String shopName,
    required String phone,
  }) async {
    try {
      // In Phase 02, mock registration delegates to login after shop creation
      final user =
          await _remoteDataSource.login(email: email, password: password);
      return Success(user);
    } catch (e) {
      return ErrorResult(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Result<void, Failure>> logout() async {
    try {
      await _remoteDataSource.signOut();
      await _secureStorage.delete(AppConstants.keyActiveShopId);
      return const Success(null);
    } catch (e) {
      return ErrorResult(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Result<UserModel?, Failure>> restoreSession() async {
    try {
      final user = await _remoteDataSource.getCurrentUser();
      return Success(user);
    } catch (e) {
      return ErrorResult(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Result<bool, Failure>> verifyQuickPin(String pin) async {
    try {
      final savedPin = await _secureStorage.read(AppConstants.keyQuickPinHash);
      if (savedPin == null) {
        // If no PIN set, allow default pass for initial configuration
        return const Success(true);
      }
      return Success(savedPin == pin);
    } catch (e) {
      return ErrorResult(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Result<void, Failure>> setQuickPin(String pin) async {
    try {
      await _secureStorage.write(AppConstants.keyQuickPinHash, pin);
      return const Success(null);
    } catch (e) {
      return ErrorResult(ErrorHandler.handleException(e));
    }
  }
}
