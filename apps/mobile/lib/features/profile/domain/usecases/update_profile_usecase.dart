import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../auth/domain/models/auth_state_model.dart';
import '../repositories/profile_repository.dart';

class UpdateProfileUseCase {
  final ProfileRepository _repository;

  const UpdateProfileUseCase(this._repository);

  Future<Result<UserModel, Failure>> execute({
    required String fullName,
    required String phone,
  }) async {
    final cleanName = fullName.trim();
    final cleanPhone = phone.trim();

    if (cleanName.isEmpty) {
      return const ErrorResult(ValidationFailure('Full name is required'));
    }

    if (cleanPhone.length < 10) {
      return const ErrorResult(
          ValidationFailure('Valid 10-digit phone number is required'));
    }

    return await _repository.updateProfile(
      fullName: cleanName,
      phone: cleanPhone,
    );
  }
}
