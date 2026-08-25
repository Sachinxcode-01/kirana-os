import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_mobile/core/errors/failure.dart';
import 'package:kirana_mobile/core/errors/result.dart';
import 'package:kirana_mobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:kirana_mobile/features/auth/domain/models/auth_state_model.dart';
import 'package:kirana_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:kirana_mobile/features/auth/presentation/providers/auth_provider.dart';

class MockAuthRepository implements AuthRepository {
  UserModel? mockUser;
  bool shouldFail = false;

  @override
  Future<Result<UserModel, Failure>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    if (shouldFail) {
      return const ErrorResult(AuthFailure('Invalid email or password'));
    }
    return Success(
      mockUser ??
          UserModel(
            id: 'u_1',
            email: email,
            role: 'owner',
            shopId: 'shop_1',
            shopName: 'Super Store',
          ),
    );
  }

  @override
  Future<Result<UserModel, Failure>> registerWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    if (shouldFail) {
      return const ErrorResult(AuthFailure('User already registered'));
    }
    return Success(
      UserModel(
        id: 'u_new',
        email: email,
        displayName: fullName,
        phone: phone,
        role: 'owner',
        shopId: null,
        shopName: null,
      ),
    );
  }

  @override
  Future<Result<void, Failure>> resendVerificationEmail(
      {required String email}) async {
    if (shouldFail) {
      return const ErrorResult(AuthFailure('Email rate limit exceeded'));
    }
    return const Success(null);
  }

  @override
  Future<Result<void, Failure>> logout() async {
    mockUser = null;
    return const Success(null);
  }

  @override
  Future<Result<UserModel?, Failure>> restoreSession() async {
    if (shouldFail) {
      return const ErrorResult(AuthFailure('Session expired'));
    }
    return Success(mockUser);
  }

  @override
  Future<Result<void, Failure>> sendPasswordResetEmail(
      {required String email}) async {
    return const Success(null);
  }

  @override
  Future<Result<void, Failure>> updatePassword(
      {required String newPassword}) async {
    return const Success(null);
  }

  @override
  Future<Result<void, Failure>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (shouldFail) {
      return const ErrorResult(AuthFailure('Current password is incorrect.'));
    }
    return const Success(null);
  }

  @override
  Future<Result<bool, Failure>> verifyQuickPin(String pin) async {
    return Success(pin == '1234');
  }

  @override
  Future<Result<void, Failure>> setQuickPin(String pin) async {
    return const Success(null);
  }
}

class FakeAuthRemoteDataSource extends AuthRemoteDataSource {
  @override
  Stream<dynamic> get onAuthStateChange => const Stream.empty();
}

void main() {
  late MockAuthRepository mockRepo;
  late FakeAuthRemoteDataSource fakeRemoteDS;
  late AuthNotifier notifier;

  setUp(() {
    mockRepo = MockAuthRepository();
    fakeRemoteDS = FakeAuthRemoteDataSource();
  });

  group('AuthNotifier & State Machine Lifecycle Tests', () {
    test('Initializes with unauthenticated when no session exists', () async {
      mockRepo.mockUser = null;
      notifier = AuthNotifier(mockRepo, fakeRemoteDS);
      await notifier.restoreSession();

      expect(notifier.state.status, AuthStatus.unauthenticated);
      expect(notifier.state.isAuthenticated, isFalse);
      expect(notifier.state.hasActiveShop, isFalse);
    });

    test('Restores authenticated session with active shop', () async {
      mockRepo.mockUser = const UserModel(
        id: 'usr_owner_1',
        email: 'ramesh@kirana.com',
        displayName: 'Ramesh Gupta',
        role: 'owner',
        shopId: 'shop_xyz',
        shopName: 'Gupta Provision Store',
      );

      notifier = AuthNotifier(mockRepo, fakeRemoteDS);
      await notifier.restoreSession();

      expect(notifier.state.status, AuthStatus.authenticatedWithShop);
      expect(notifier.state.isAuthenticated, isTrue);
      expect(notifier.state.hasActiveShop, isTrue);
      expect(notifier.state.activeShopId, 'shop_xyz');
      expect(notifier.state.activeShopName, 'Gupta Provision Store');
    });

    test('Restores authenticated session without shop (requires onboarding)',
        () async {
      mockRepo.mockUser = const UserModel(
        id: 'usr_new_1',
        email: 'newowner@kirana.com',
        displayName: 'New Owner',
        role: 'owner',
        shopId: null,
        shopName: null,
      );

      notifier = AuthNotifier(mockRepo, fakeRemoteDS);
      await notifier.restoreSession();

      expect(notifier.state.status, AuthStatus.authenticatedWithoutShop);
      expect(notifier.state.isAuthenticated, isTrue);
      expect(notifier.state.hasActiveShop, isFalse);
    });

    test('Login success updates state and sets active shop', () async {
      notifier = AuthNotifier(mockRepo, fakeRemoteDS);
      final success = await notifier.login(
        email: 'owner@store.com',
        password: 'Password123!',
      );

      expect(success, isTrue);
      expect(notifier.state.status, AuthStatus.authenticatedWithShop);
      expect(notifier.state.user?.email, 'owner@store.com');
      expect(notifier.state.hasActiveShop, isTrue);
    });

    test('Login failure maps error message into state', () async {
      mockRepo.shouldFail = true;
      notifier = AuthNotifier(mockRepo, fakeRemoteDS);

      final success = await notifier.login(
        email: 'wrong@store.com',
        password: 'BadPassword',
      );

      expect(success, isFalse);
      expect(notifier.state.status, AuthStatus.error);
      expect(notifier.state.errorMessage, 'Invalid email or password');
    });

    test('Registration creates user without shop and prompts onboarding',
        () async {
      notifier = AuthNotifier(mockRepo, fakeRemoteDS);
      final success = await notifier.register(
        email: 'newuser@store.com',
        password: 'SecurePassword123',
        fullName: 'Suresh Kumar',
        phone: '9876543210',
      );

      expect(success, isTrue);
      expect(notifier.state.status, AuthStatus.authenticatedWithoutShop);
      expect(notifier.state.hasActiveShop, isFalse);
      expect(notifier.state.user?.displayName, 'Suresh Kumar');
    });

    test('Change password success returns true', () async {
      notifier = AuthNotifier(mockRepo, fakeRemoteDS);
      final success = await notifier.changePassword(
        currentPassword: 'OldPassword123',
        newPassword: 'NewPassword123',
      );
      expect(success, isTrue);
    });

    test('Logout clears user session and resets to unauthenticated', () async {
      mockRepo.mockUser = const UserModel(
        id: 'u_1',
        email: 'owner@store.com',
        role: 'owner',
        shopId: 'shop_1',
      );

      notifier = AuthNotifier(mockRepo, fakeRemoteDS);
      await notifier.restoreSession();
      expect(notifier.state.isAuthenticated, isTrue);

      await notifier.logout();
      expect(notifier.state.status, AuthStatus.unauthenticated);
      expect(notifier.state.user, isNull);
    });
  });
}
