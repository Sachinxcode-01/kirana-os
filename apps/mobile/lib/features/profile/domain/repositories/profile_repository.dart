import 'dart:typed_data';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../auth/domain/models/auth_state_model.dart';

abstract interface class ProfileRepository {
  Future<Result<UserModel, Failure>> updateProfile({
    required String fullName,
    required String phone,
  });

  Future<Result<String, Failure>> uploadProfilePhoto({
    required Uint8List imageBytes,
    required String fileName,
  });

  Future<Result<void, Failure>> removeProfilePhoto();
}
