import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../models/auth_state_model.dart';

abstract interface class AuthRepository {
  Future<Result<UserModel, Failure>> loginWithEmail({
    required String email,
    required String password,
  });

  Future<Result<UserModel, Failure>> registerWithEmail({
    required String email,
    required String password,
    required String shopName,
    required String phone,
  });

  Future<Result<void, Failure>> logout();

  Future<Result<UserModel?, Failure>> restoreSession();

  Future<Result<bool, Failure>> verifyQuickPin(String pin);

  Future<Result<void, Failure>> setQuickPin(String pin);
}
