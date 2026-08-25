import 'dart:typed_data';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/storage/product_image_service.dart';
import '../../../auth/domain/models/auth_state_model.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;
  final ProductImageService _imageService;

  ProfileRepositoryImpl({
    required ProfileRemoteDataSource remoteDataSource,
    required ProductImageService imageService,
  })  : _remoteDataSource = remoteDataSource,
        _imageService = imageService;

  @override
  Future<Result<UserModel, Failure>> updateProfile({
    required String fullName,
    required String phone,
  }) async {
    if (fullName.trim().isEmpty) {
      return const ErrorResult(ValidationFailure('Full name is required'));
    }
    if (phone.trim().length < 10) {
      return const ErrorResult(
          ValidationFailure('Valid 10-digit phone number is required'));
    }

    try {
      final user = await _remoteDataSource.updateProfile(
        fullName: fullName,
        phone: phone,
      );
      return Success(user);
    } catch (e) {
      return ErrorResult(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Result<String, Failure>> uploadProfilePhoto({
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    final validation = _imageService.validateImage(
      bytes: imageBytes,
      fileName: fileName,
    );
    if (validation.isError) {
      return ErrorResult(validation.failureOrNull!);
    }

    try {
      final avatarUrl = await _remoteDataSource.uploadProfilePhoto(
        bytes: imageBytes,
        fileName: fileName,
      );
      return Success(avatarUrl);
    } catch (e) {
      return ErrorResult(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Result<void, Failure>> removeProfilePhoto() async {
    try {
      await _remoteDataSource.removeProfilePhoto();
      return const Success(null);
    } catch (e) {
      return ErrorResult(ErrorHandler.handle(e));
    }
  }
}
