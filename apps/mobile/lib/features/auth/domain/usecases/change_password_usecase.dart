import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../repositories/auth_repository.dart';

class ChangePasswordUseCase {
  final AuthRepository _repository;

  const ChangePasswordUseCase(this._repository);

  Future<Result<void, Failure>> execute({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (currentPassword.isEmpty) {
      return const ErrorResult(
          ValidationFailure('Current password is required'));
    }

    if (newPassword.length < 6) {
      return const ErrorResult(
          ValidationFailure('New password must be at least 6 characters'));
    }

    if (newPassword == currentPassword) {
      return const ErrorResult(ValidationFailure(
          'New password must be different from current password'));
    }

    if (newPassword != confirmPassword) {
      return const ErrorResult(
          ValidationFailure('New password and confirmation do not match'));
    }

    return await _repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}
