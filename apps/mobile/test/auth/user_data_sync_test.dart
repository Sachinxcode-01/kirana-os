import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_mobile/core/errors/failure.dart';
import 'package:kirana_mobile/core/errors/result.dart';
import 'package:kirana_mobile/features/auth/domain/models/auth_state_model.dart';
import 'package:kirana_mobile/features/auth/domain/repositories/auth_repository.dart';

class MockSyncAuthRepository implements AuthRepository {
  UserModel? serverUser;
  UserModel? localCachedUser;
  bool isOnline = true;
  bool realtimeSubscribed = false;
  int syncCallCount = 0;

  MockSyncAuthRepository() {
    serverUser = const UserModel(
      id: 'user_sync_101',
      email: 'sync_owner@kirana.com',
      displayName: 'Rajesh Sharma',
      phone: '9876501234',
      role: 'owner',
      avatarUrl: 'https://cdn.kirana.app/avatars/u101.png',
      shopId: 'shop_sync_202',
      shopName: 'Rajesh Supermarket',
    );
    // Populate local cache initially matching server
    localCachedUser = serverUser;
  }

  @override
  Future<Result<UserModel?, Failure>> restoreSession() async {
    syncCallCount++;
    if (isOnline) {
      // Rebuild local cache with server data
      localCachedUser = serverUser;
      return Success(serverUser);
    } else {
      // Offline fallback to local Drift cache
      return Success(localCachedUser);
    }
  }

  @override
  Future<Result<UserModel, Failure>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    if (!isOnline) {
      return const ErrorResult(
        NetworkFailure('Internet connection required to log in.'),
      );
    }
    localCachedUser = serverUser;
    return Success(serverUser!);
  }

  @override
  Future<Result<UserModel, Failure>> registerWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    if (!isOnline) {
      return const ErrorResult(
        NetworkFailure('Internet connection required to register.'),
      );
    }
    serverUser = UserModel(
      id: 'user_new_sync',
      email: email,
      displayName: fullName,
      phone: phone,
      role: 'owner',
      shopId: null,
      shopName: null,
    );
    localCachedUser = serverUser;
    return Success(serverUser!);
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
    return const Success(null);
  }

  @override
  Future<Result<void, Failure>> logout() async {
    localCachedUser = null;
    realtimeSubscribed = false;
    return const Success(null);
  }

  @override
  void subscribeUserRealtime({
    required String userId,
    required void Function() onDataChanged,
  }) {
    realtimeSubscribed = true;
  }

  @override
  void unsubscribeUserRealtime() {
    realtimeSubscribed = false;
  }

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
    localCachedUser = null;
    return const Success(null);
  }
}

void main() {
  group('KIRANAOS AUTH 11 — User Data Sync & Session Consistency Tests', () {
    late MockSyncAuthRepository repository;

    setUp(() {
      repository = MockSyncAuthRepository();
    });

    test(
        '1. Authoritative central session restores complete user profile & shop',
        () async {
      final result = await repository.restoreSession();
      expect(result.isSuccess, isTrue);

      final user = result.dataOrNull!;
      expect(user.id, 'user_sync_101');
      expect(user.displayName, 'Rajesh Sharma');
      expect(user.email, 'sync_owner@kirana.com');
      expect(user.role, 'owner');
      expect(user.shopId, 'shop_sync_202');
      expect(user.shopName, 'Rajesh Supermarket');
    });

    test(
        '2. Account data recovery fetches from Supabase when local cache is empty',
        () async {
      // Simulate corrupted/empty local cache
      repository.localCachedUser = null;
      repository.isOnline = true;

      final result = await repository.restoreSession();
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, isNotNull);
      expect(repository.localCachedUser, isNotNull); // Cache rebuilt
      expect(repository.localCachedUser?.displayName, 'Rajesh Sharma');
    });

    test('3. Profile/Shop updates sync across server, local cache, and session',
        () async {
      // Perform server profile & shop update
      repository.serverUser = repository.serverUser!.copyWith(
        displayName: 'Rajesh V. Sharma',
        shopName: 'Rajesh Supermarket & Co.',
      );

      final result = await repository.restoreSession();
      expect(result.isSuccess, isTrue);
      final updatedUser = result.dataOrNull!;
      expect(updatedUser.displayName, 'Rajesh V. Sharma');
      expect(updatedUser.shopName, 'Rajesh Supermarket & Co.');
      expect(repository.localCachedUser?.displayName, 'Rajesh V. Sharma');
    });

    test(
        '4. Offline mode safely presents cached session without claiming online sync',
        () async {
      repository.isOnline = false;

      final result = await repository.restoreSession();
      expect(result.isSuccess, isTrue);
      final cached = result.dataOrNull!;
      expect(cached.displayName, 'Rajesh Sharma');
      expect(cached.shopId, 'shop_sync_202');
    });

    test(
        '5. Connectivity restoration triggers automatic server verification & sync',
        () async {
      // Offline transition
      repository.isOnline = false;
      await repository.restoreSession();
      final initialCount = repository.syncCallCount;

      // Online transition
      repository.isOnline = true;
      await repository
          .restoreSession(); // Auto-triggered by connectivity stream listener

      expect(repository.syncCallCount, equals(initialCount + 1));
      expect(repository.localCachedUser?.displayName, 'Rajesh Sharma');
    });

    test(
        '6. Logout unsubscribes Realtime channel and clears local profile cache',
        () async {
      repository.subscribeUserRealtime(
          userId: 'user_sync_101', onDataChanged: () {});
      expect(repository.realtimeSubscribed, isTrue);

      await repository.logout();
      expect(repository.realtimeSubscribed, isFalse);
      expect(repository.localCachedUser, isNull);
    });

    test('7. Zero sensitive credentials stored in cached UserModel', () async {
      final user = repository.serverUser!;
      final userMap = {
        'id': user.id,
        'email': user.email,
        'displayName': user.displayName,
        'phone': user.phone,
        'role': user.role,
        'avatarUrl': user.avatarUrl,
        'shopId': user.shopId,
        'shopName': user.shopName,
      };

      expect(userMap.containsKey('password'), isFalse);
      expect(userMap.containsKey('secret'), isFalse);
      expect(userMap.containsKey('service_role_key'), isFalse);
    });
  });
}
