import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../repositories/auth_repository.dart';

class DeleteAccountRequestUseCase {
  final AuthRepository _repository;

  const DeleteAccountRequestUseCase(this._repository);

  Future<Result<void, Failure>> execute({
    required String currentPassword,
    String? reason,
  }) async {
    if (currentPassword.isEmpty) {
      return const ErrorResult(ValidationFailure(
          'Current password is required to confirm account deletion request'));
    }

    return await _repository.requestAccountDeletion(
      currentPassword: currentPassword,
      reason: reason,
    );
  }
}
