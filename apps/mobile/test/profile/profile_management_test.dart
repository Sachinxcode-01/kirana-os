import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_mobile/core/errors/failure.dart';
import 'package:kirana_mobile/core/errors/result.dart';
import 'package:kirana_mobile/features/auth/domain/models/auth_state_model.dart';
import 'package:kirana_mobile/features/profile/domain/repositories/profile_repository.dart';
import 'package:kirana_mobile/features/profile/domain/usecases/update_profile_usecase.dart';

class MockProfileRepositorySuccess implements ProfileRepository {
  UserModel currentUser = const UserModel(
    id: 'user_123',
    email: 'owner@kirana.com',
    displayName: 'Ramesh Kumar',
    phone: '9845012345',
    role: 'owner',
    avatarUrl: 'https://example.com/avatar.jpg',
    shopId: 'shop_123',
    shopName: 'Ramesh Store',
  );

  @override
  Future<Result<UserModel, Failure>> updateProfile({
    required String fullName,
    required String phone,
  }) async {
    currentUser = currentUser.copyWith(
      displayName: fullName,
      phone: phone,
    );
    return Success(currentUser);
  }

  @override
  Future<Result<String, Failure>> uploadProfilePhoto({
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    const newAvatar = 'https://example.com/new_avatar.jpg';
    currentUser = currentUser.copyWith(avatarUrl: newAvatar);
    return const Success(newAvatar);
  }

  @override
  Future<Result<void, Failure>> removeProfilePhoto() async {
    currentUser = currentUser.copyWith(clearAvatarUrl: true);
    return const Success(null);
  }
}

class MockProfileRepositoryOffline implements ProfileRepository {
  @override
  Future<Result<UserModel, Failure>> updateProfile({
    required String fullName,
    required String phone,
  }) async {
    return const ErrorResult(
      NetworkFailure('Network connection unavailable.'),
    );
  }

  @override
  Future<Result<String, Failure>> uploadProfilePhoto({
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    return const ErrorResult(
      NetworkFailure('Network connection unavailable.'),
    );
  }

  @override
  Future<Result<void, Failure>> removeProfilePhoto() async {
    return const ErrorResult(
      NetworkFailure('Network connection unavailable.'),
    );
  }
}

void main() {
  group('KIRANAOS AUTH 4 — Profile Management Tests', () {
    late MockProfileRepositorySuccess repositorySuccess;
    late UpdateProfileUseCase useCaseSuccess;

    setUp(() {
      repositorySuccess = MockProfileRepositorySuccess();
      useCaseSuccess = UpdateProfileUseCase(repositorySuccess);
    });

    test('1. Loads profile values from UserModel correctly', () {
      final user = repositorySuccess.currentUser;
      expect(user.displayName, 'Ramesh Kumar');
      expect(user.email, 'owner@kirana.com');
      expect(user.phone, '9845012345');
      expect(user.role, 'owner');
      expect(user.avatarUrl, 'https://example.com/avatar.jpg');
    });

    test('2. Updates profile with valid full name and phone number', () async {
      final result = await useCaseSuccess.execute(
        fullName: 'Suresh Kumar',
        phone: '9876543210',
      );

      expect(result.isSuccess, isTrue);
      final updated = result.dataOrNull!;
      expect(updated.displayName, 'Suresh Kumar');
      expect(updated.phone, '9876543210');
    });

    test('3. Rejects empty full name with ValidationFailure', () async {
      final result = await useCaseSuccess.execute(
        fullName: '   ',
        phone: '9845012345',
      );

      expect(result.isError, isTrue);
      expect(result.failureOrNull?.message, 'Full name is required');
    });

    test('4. Rejects invalid or short phone number with ValidationFailure',
        () async {
      final result = await useCaseSuccess.execute(
        fullName: 'Ramesh Kumar',
        phone: '12345', // Short phone
      );

      expect(result.isError, isTrue);
      expect(result.failureOrNull?.message,
          'Valid 10-digit phone number is required');
    });

    test('5. Uploads profile photo and updates avatar reference', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final result = await repositorySuccess.uploadProfilePhoto(
        imageBytes: bytes,
        fileName: 'my_photo.jpg',
      );

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, 'https://example.com/new_avatar.jpg');
      expect(repositorySuccess.currentUser.avatarUrl,
          'https://example.com/new_avatar.jpg');
    });

    test('6. Removes profile photo and clears avatar URL', () async {
      final result = await repositorySuccess.removeProfilePhoto();

      expect(result.isSuccess, isTrue);
      expect(repositorySuccess.currentUser.avatarUrl, isNull);
    });

    test('7. Handles offline update failure gracefully without raw tracebacks',
        () async {
      final repositoryOffline = MockProfileRepositoryOffline();
      final useCaseOffline = UpdateProfileUseCase(repositoryOffline);

      final result = await useCaseOffline.execute(
        fullName: 'Ramesh Kumar',
        phone: '9845012345',
      );

      expect(result.isError, isTrue);
      expect(result.failureOrNull, isA<NetworkFailure>());
      expect(result.failureOrNull?.message, 'Network connection unavailable.');
    });

    test('8. Logout resets auth state to unauthenticated', () {
      var authState = AuthStateModel.authenticatedWithShop(
        user: repositorySuccess.currentUser,
        shopId: 'shop_123',
        shopName: 'Ramesh Store',
      );

      expect(authState.isAuthenticated, isTrue);
      expect(authState.hasActiveShop, isTrue);

      // Perform logout transition
      authState = AuthStateModel.unauthenticated();

      expect(authState.isAuthenticated, isFalse);
      expect(authState.hasActiveShop, isFalse);
      expect(authState.user, isNull);
    });
  });
}
