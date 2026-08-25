import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/app_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/profile_remote_data_source.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/usecases/update_profile_usecase.dart';

final profileRemoteDataSourceProvider =
    Provider<ProfileRemoteDataSource>((ref) {
  return ProfileRemoteDataSource();
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final remote = ref.watch(profileRemoteDataSourceProvider);
  final imageService = ref.watch(productImageServiceProvider);
  return ProfileRepositoryImpl(
    remoteDataSource: remote,
    imageService: imageService,
  );
});

final updateProfileUseCaseProvider = Provider<UpdateProfileUseCase>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return UpdateProfileUseCase(repository);
});

class ProfileState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const ProfileState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final UpdateProfileUseCase _updateProfileUseCase;
  final ProfileRepository _repository;
  final Ref _ref;

  ProfileNotifier(
    this._updateProfileUseCase,
    this._repository,
    this._ref,
  ) : super(const ProfileState());

  Future<bool> updateProfile({
    required String fullName,
    required String phone,
  }) async {
    if (state.isLoading) return false;

    state = const ProfileState(isLoading: true);

    final result = await _updateProfileUseCase.execute(
      fullName: fullName,
      phone: phone,
    );

    return result.fold(
      (updatedUser) {
        state = const ProfileState(
          isLoading: false,
          successMessage: 'Profile updated successfully!',
        );

        final currentUser = _ref.read(authNotifierProvider).user;
        if (currentUser != null) {
          if (_ref.read(authNotifierProvider).hasActiveShop) {
            _ref.read(authNotifierProvider.notifier).updateActiveShop(
                  shopId: _ref.read(authNotifierProvider).activeShopId!,
                  shopName:
                      _ref.read(authNotifierProvider).activeShopName ?? '',
                );
          }
          // Directly update authNotifier user session
          _ref.read(authNotifierProvider.notifier).restoreSession();
        }
        return true;
      },
      (failure) {
        state = ProfileState(
          isLoading: false,
          errorMessage: failure.message,
        );
        return false;
      },
    );
  }

  Future<bool> uploadProfilePhoto({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (state.isLoading) return false;

    state = const ProfileState(isLoading: true);

    final result = await _repository.uploadProfilePhoto(
      imageBytes: bytes,
      fileName: fileName,
    );

    return result.fold(
      (avatarUrl) {
        state = const ProfileState(
          isLoading: false,
          successMessage: 'Profile photo updated successfully!',
        );

        _ref.read(authNotifierProvider.notifier).restoreSession();
        return true;
      },
      (failure) {
        state = ProfileState(
          isLoading: false,
          errorMessage: failure.message,
        );
        return false;
      },
    );
  }

  Future<bool> removeProfilePhoto() async {
    if (state.isLoading) return false;

    state = const ProfileState(isLoading: true);

    final result = await _repository.removeProfilePhoto();

    return result.fold(
      (_) {
        state = const ProfileState(
          isLoading: false,
          successMessage: 'Profile photo removed.',
        );

        _ref.read(authNotifierProvider.notifier).restoreSession();
        return true;
      },
      (failure) {
        state = ProfileState(
          isLoading: false,
          errorMessage: failure.message,
        );
        return false;
      },
    );
  }

  void clearMessages() {
    state = const ProfileState();
  }
}

final profileNotifierProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final useCase = ref.watch(updateProfileUseCaseProvider);
  final repository = ref.watch(profileRepositoryProvider);
  return ProfileNotifier(useCase, repository, ref);
});
