import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_mobile/core/errors/failure.dart';
import 'package:kirana_mobile/core/errors/result.dart';
import 'package:kirana_mobile/features/auth/domain/models/auth_state_model.dart';
import 'package:kirana_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:kirana_mobile/features/auth/domain/usecases/change_password_usecase.dart';
import 'package:kirana_mobile/features/auth/domain/usecases/delete_account_request_usecase.dart';

class MockAccountSecurityAuthRepository implements AuthRepository {
  UserModel? currentUser = const UserModel(
    id: 'user_security_123',
    email: 'security_owner@kirana.com',
    displayName: 'Vikram Singh',
    phone: '9812345678',
    role: 'owner',
    shopId: 'shop_sec_1',
    shopName: 'Vikram Stores',
  );

  bool shouldFailCurrentPassword = false;
  bool isOffline = false;
  bool isRateLimited = false;

  @override
  Future<Result<UserModel, Failure>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    if (isOffline) {
      return const ErrorResult(
        NetworkFailure("You're offline. Please reconnect and try again."),
      );
    }
    if (isRateLimited) {
      return const ErrorResult(
        AuthFailure("Too many attempts. Please wait and try again."),
      );
    }
    return Success(currentUser!);
  }

  @override
  Future<Result<UserModel, Failure>> registerWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    return Success(currentUser!);
  }

  @override
  Future<Result<void, Failure>> signInWithGoogle() async {
    return const Success(null);
  }

  @override
  Future<Result<void, Failure>> resendVerificationEmail({
    required String email,
  }) async {
    return const Success(null);
  }

  @override
  Future<Result<void, Failure>> sendPasswordResetEmail({
    required String email,
  }) async {
    return const Success(null);
  }

  @override
  Future<Result<void, Failure>> updatePassword({
    required String newPassword,
  }) async {
    return const Success(null);
  }

  @override
  Future<Result<void, Failure>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (isOffline) {
      return const ErrorResult(
        NetworkFailure("You're offline. Please reconnect and try again."),
      );
    }
    if (isRateLimited) {
      return const ErrorResult(
        AuthFailure("Too many attempts. Please wait and try again."),
      );
    }
    if (shouldFailCurrentPassword || currentPassword != 'CorrectPassword123!') {
      return const ErrorResult(
        AuthFailure("Current password is incorrect. Please try again."),
      );
    }
    return const Success(null);
  }

  @override
  Future<Result<void, Failure>> logout() async {
    currentUser = null;
    return const Success(null);
  }

  @override
  Future<Result<UserModel?, Failure>> restoreSession() async {
    if (isOffline) {
      return const ErrorResult(
        NetworkFailure("You're offline. Please reconnect and try again."),
      );
    }
    return Success(currentUser);
  }

  @override
  void subscribeUserRealtime({
    required String userId,
    required void Function() onDataChanged,
  }) {}

  @override
  void unsubscribeUserRealtime() {}

  @override
  Future<Result<bool, Failure>> verifyQuickPin(String pin) async {
    return const Success(true);
  }

  @override
  Future<Result<void, Failure>> setQuickPin(String pin) async {
    return const Success(null);
  }

  @override
  Future<Result<void, Failure>> requestAccountDeletion({
    required String currentPassword,
    String? reason,
  }) async {
    if (isOffline) {
      return const ErrorResult(
        NetworkFailure("You're offline. Please reconnect and try again."),
      );
    }
    if (shouldFailCurrentPassword || currentPassword != 'CorrectPassword123!') {
      return const ErrorResult(
        AuthFailure("Current password is incorrect. Please try again."),
      );
    }

    // Records deletion requested status and signs out
    currentUser = null;
    return const Success(null);
  }
}

void main() {
  group('KIRANAOS AUTH 5 — Account Security Tests', () {
    late MockAccountSecurityAuthRepository repository;
    late ChangePasswordUseCase changePasswordUseCase;
    late DeleteAccountRequestUseCase deleteAccountRequestUseCase;

    setUp(() {
      repository = MockAccountSecurityAuthRepository();
      changePasswordUseCase = ChangePasswordUseCase(repository);
      deleteAccountRequestUseCase = DeleteAccountRequestUseCase(repository);
    });

    test('1. Validates change password requires current password', () async {
      final result = await changePasswordUseCase.execute(
        currentPassword: '',
        newPassword: 'NewSecurePassword1!',
        confirmPassword: 'NewSecurePassword1!',
      );

      expect(result.isError, isTrue);
      expect(result.failureOrNull?.message, 'Current password is required');
    });

    test('2. Validates change password minimum length requirement (6 chars)',
        () async {
      final result = await changePasswordUseCase.execute(
        currentPassword: 'CorrectPassword123!',
        newPassword: '123',
        confirmPassword: '123',
      );

      expect(result.isError, isTrue);
      expect(result.failureOrNull?.message,
          'New password must be at least 6 characters');
    });

    test('3. Validates new password must be different from current password',
        () async {
      final result = await changePasswordUseCase.execute(
        currentPassword: 'CorrectPassword123!',
        newPassword: 'CorrectPassword123!',
        confirmPassword: 'CorrectPassword123!',
      );

      expect(result.isError, isTrue);
      expect(result.failureOrNull?.message,
          'New password must be different from current password');
    });

    test('4. Validates new password and confirmation mismatch', () async {
      final result = await changePasswordUseCase.execute(
        currentPassword: 'CorrectPassword123!',
        newPassword: 'NewSecurePassword1!',
        confirmPassword: 'DifferentPassword1!',
      );

      expect(result.isError, isTrue);
      expect(result.failureOrNull?.message,
          'New password and confirmation do not match');
    });

    test('5. Successfully changes password when all inputs are valid',
        () async {
      final result = await changePasswordUseCase.execute(
        currentPassword: 'CorrectPassword123!',
        newPassword: 'NewSecurePassword1!',
        confirmPassword: 'NewSecurePassword1!',
      );

      expect(result.isSuccess, isTrue);
    });

    test('6. Rejects change password with wrong current password', () async {
      final result = await changePasswordUseCase.execute(
        currentPassword: 'WrongPassword!',
        newPassword: 'NewSecurePassword1!',
        confirmPassword: 'NewSecurePassword1!',
      );

      expect(result.isError, isTrue);
      expect(result.failureOrNull?.message,
          'Current password is incorrect. Please try again.');
    });

    test(
        '7. Rejects account deletion request without re-authentication password',
        () async {
      final result = await deleteAccountRequestUseCase.execute(
        currentPassword: '',
      );

      expect(result.isError, isTrue);
      expect(result.failureOrNull?.message,
          'Current password is required to confirm account deletion request');
    });

    test(
        '8. Processes account deletion request safely with valid re-authentication',
        () async {
      final result = await deleteAccountRequestUseCase.execute(
        currentPassword: 'CorrectPassword123!',
        reason: 'Closing branch',
      );

      expect(result.isSuccess, isTrue);
      expect(repository.currentUser, isNull);
    });

    test(
        '9. Offline state returns clear friendly network error without faking operations',
        () async {
      repository.isOffline = true;

      final changeResult = await changePasswordUseCase.execute(
        currentPassword: 'CorrectPassword123!',
        newPassword: 'NewSecurePassword1!',
        confirmPassword: 'NewSecurePassword1!',
      );

      expect(changeResult.isError, isTrue);
      expect(changeResult.failureOrNull?.message,
          "You're offline. Please reconnect and try again.");

      final deleteResult = await deleteAccountRequestUseCase.execute(
        currentPassword: 'CorrectPassword123!',
      );

      expect(deleteResult.isError, isTrue);
      expect(deleteResult.failureOrNull?.message,
          "You're offline. Please reconnect and try again.");
    });

    test('10. Rate limiting returns friendly rate limit error message',
        () async {
      repository.isRateLimited = true;

      final result = await changePasswordUseCase.execute(
        currentPassword: 'CorrectPassword123!',
        newPassword: 'NewSecurePassword1!',
        confirmPassword: 'NewSecurePassword1!',
      );

      expect(result.isError, isTrue);
      expect(result.failureOrNull?.message,
          "Too many attempts. Please wait and try again.");
    });

    test('11. Session state resets to unauthenticated post-logout/deletion',
        () {
      var state = AuthStateModel.authenticatedWithShop(
        user: repository.currentUser!,
        shopId: 'shop_sec_1',
        shopName: 'Vikram Stores',
      );

      expect(state.isAuthenticated, isTrue);

      // Perform state transition
      state = AuthStateModel.unauthenticated();

      expect(state.isAuthenticated, isFalse);
      expect(state.hasActiveShop, isFalse);
      expect(state.user, isNull);
    });
  });
}
