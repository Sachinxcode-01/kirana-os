import 'package:flutter/foundation.dart';
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
    required String fullName,
    String? phone,
  });

  Future<Result<void, Failure>> signInWithGoogle();

  Future<Result<void, Failure>> resendVerificationEmail({
    required String email,
  });

  Future<Result<void, Failure>> sendPasswordResetEmail({
    required String email,
  });

  Future<Result<void, Failure>> updatePassword({
    required String newPassword,
  });

  Future<Result<void, Failure>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<Result<void, Failure>> logout();

  Future<Result<UserModel?, Failure>> restoreSession();

  void subscribeUserRealtime({
    required String userId,
    required VoidCallback onDataChanged,
  });

  void unsubscribeUserRealtime();

  Future<Result<bool, Failure>> verifyQuickPin(String pin);

  Future<Result<void, Failure>> setQuickPin(String pin);

  Future<Result<void, Failure>> requestAccountDeletion({
    required String currentPassword,
    String? reason,
  });
}
