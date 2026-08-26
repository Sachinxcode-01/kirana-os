import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_mobile/core/errors/failure.dart';
import 'package:kirana_mobile/core/errors/result.dart';
import 'package:kirana_mobile/features/auth/domain/models/auth_state_model.dart';
import 'package:kirana_mobile/features/auth/domain/repositories/auth_repository.dart';

class MockHardenedAuthRepository implements AuthRepository {
  UserModel? _storedUser;
  String _currentPassword = 'OldPassword123!';
  bool isOffline = false;

  MockHardenedAuthRepository() {
    _storedUser = const UserModel(
      id: 'usr_hardened_99',
      email: 'owner@kirana.com',
      displayName: 'Ramesh Kumar',
      phone: '9845012345',
      role: 'owner',
      avatarUrl: 'https://cdn.kirana.app/avatars/u99.png',
      shopId: 'shop_hardened_01',
      shopName: 'Ramesh Kirana Store',
    );
  }

  @override
  Future<Result<UserModel, Failure>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    if (isOffline) {
      return const ErrorResult(
        NetworkFailure('Internet connection required to log in.'),
      );
    }
    if (password != _currentPassword) {
      return const ErrorResult(
        AuthFailure('Invalid email or password. Please try again.'),
      );
    }
    return Success(_storedUser!);
  }

  @override
  Future<Result<UserModel, Failure>> registerWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    if (isOffline) {
      return const ErrorResult(
        NetworkFailure('Internet connection required to register.'),
      );
    }
    _storedUser = UserModel(
      id: 'usr_new_reg_1',
      email: email,
      displayName: fullName,
      phone: phone,
      role: 'owner',
      shopId: null,
      shopName: null,
    );
    _currentPassword = password;
    return Success(_storedUser!);
  }

  @override
  Future<Result<void, Failure>> signInWithGoogle() async {
    if (isOffline) {
      return const ErrorResult(
        NetworkFailure('Internet connection required for Google sign-in.'),
      );
    }
    _storedUser = const UserModel(
      id: 'usr_google_77',
      email: 'google_user@gmail.com',
      displayName: 'Google User',
      role: 'owner',
      shopId: 'shop_google_1',
      shopName: 'Google Kirana',
    );
    return const Success(null);
  }

  @override
  Future<Result<void, Failure>> sendPasswordResetEmail({
    required String email,
  }) async {
    if (isOffline) {
      return const ErrorResult(
        NetworkFailure('Internet connection required to reset password.'),
      );
    }
    return const Success(null);
  }

  @override
  Future<Result<void, Failure>> updatePassword({
    required String newPassword,
  }) async {
    if (isOffline) {
      return const ErrorResult(
        NetworkFailure('Internet connection required to update password.'),
      );
    }
    _currentPassword = newPassword;
    return const Success(null);
  }

  @override
  Future<Result<void, Failure>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (isOffline) {
      return const ErrorResult(
        NetworkFailure('Internet connection required to change password.'),
      );
    }
    if (currentPassword != _currentPassword) {
      return const ErrorResult(AuthFailure('Current password is incorrect.'));
    }
    _currentPassword = newPassword;
    return const Success(null);
  }

  @override
  Future<Result<void, Failure>> resendVerificationEmail({
    required String email,
  }) async {
    return const Success(null);
  }

  @override
  Future<Result<void, Failure>> logout() async {
    return const Success(null);
  }

  @override
  Future<Result<UserModel?, Failure>> restoreSession() async {
    return Success(_storedUser);
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
    return const Success(null);
  }
}

void main() {
  group('KIRANAOS AUTH HARDENING & ACCOUNT RECOVERY TESTS', () {
    late MockHardenedAuthRepository mockRepo;

    setUp(() {
      mockRepo = MockHardenedAuthRepository();
    });

    test('1. Registration creates user profile and returns clean UserModel',
        () async {
      final result = await mockRepo.registerWithEmail(
        email: 'newowner@kirana.com',
        password: 'NewPassword123!',
        fullName: 'Anita Sharma',
        phone: '9876543210',
      );

      expect(result.isSuccess, isTrue);
      final user = result.dataOrNull!;
      expect(user.displayName, 'Anita Sharma');
      expect(user.email, 'newowner@kirana.com');
      expect(user.phone, '9876543210');
      expect(user.role, 'owner');
    });

    test(
        '2. Login succeeds with correct password and restores full profile & shop',
        () async {
      final result = await mockRepo.loginWithEmail(
        email: 'owner@kirana.com',
        password: 'OldPassword123!',
      );

      expect(result.isSuccess, isTrue);
      final user = result.dataOrNull!;
      expect(user.id, 'usr_hardened_99');
      expect(user.displayName, 'Ramesh Kumar');
      expect(user.shopId, 'shop_hardened_01');
      expect(user.shopName, 'Ramesh Kirana Store');
    });

    test(
        '3. Password update invalidates old password and enforces new password',
        () async {
      // Step A: Update password
      final updateResult =
          await mockRepo.updatePassword(newPassword: 'BrandNewPassword456!');
      expect(updateResult.isSuccess, isTrue);

      // Step B: Attempt login with OLD password -> MUST FAIL
      final oldLoginResult = await mockRepo.loginWithEmail(
        email: 'owner@kirana.com',
        password: 'OldPassword123!',
      );
      expect(oldLoginResult.isError, isTrue);
      expect(oldLoginResult.failureOrNull?.message,
          contains('Invalid email or password'));

      // Step C: Attempt login with NEW password -> MUST SUCCEED
      final newLoginResult = await mockRepo.loginWithEmail(
        email: 'owner@kirana.com',
        password: 'BrandNewPassword456!',
      );
      expect(newLoginResult.isSuccess, isTrue);
      expect(newLoginResult.dataOrNull?.displayName, 'Ramesh Kumar');
    });

    test('4. Forgot password email send succeeds', () async {
      final result =
          await mockRepo.sendPasswordResetEmail(email: 'owner@kirana.com');
      expect(result.isSuccess, isTrue);
    });

    test(
        '5. Offline state blocks password updates and registration with network errors',
        () async {
      mockRepo.isOffline = true;

      final regResult = await mockRepo.registerWithEmail(
        email: 'offline@kirana.com',
        password: 'Password123!',
        fullName: 'Offline User',
      );
      expect(regResult.isError, isTrue);
      expect(regResult.failureOrNull?.message,
          contains('Internet connection required'));

      final resetResult =
          await mockRepo.sendPasswordResetEmail(email: 'offline@kirana.com');
      expect(resetResult.isError, isTrue);
      expect(resetResult.failureOrNull?.message,
          contains('Internet connection required'));

      final updateResult =
          await mockRepo.updatePassword(newPassword: 'OfflinePassword123!');
      expect(updateResult.isError, isTrue);
      expect(updateResult.failureOrNull?.message,
          contains('Internet connection required'));
    });

    test(
        '6. Session restoration restores active profile and shop details cleanly',
        () async {
      final result = await mockRepo.restoreSession();
      expect(result.isSuccess, isTrue);
      final user = result.dataOrNull;
      expect(user, isNotNull);
      expect(user!.displayName, 'Ramesh Kumar');
      expect(user.shopId, 'shop_hardened_01');
    });
  });
}
