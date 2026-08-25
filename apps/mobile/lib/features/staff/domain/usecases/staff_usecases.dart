import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../models/staff_member_model.dart';
import '../repositories/staff_repository.dart';

class GetStaffListUseCase {
  final StaffRepository _repository;

  const GetStaffListUseCase(this._repository);

  Future<Result<List<StaffMemberModel>, Failure>> execute({
    required String shopId,
    bool forceRefresh = false,
  }) async {
    if (shopId.trim().isEmpty) {
      return const ErrorResult(ValidationFailure('Shop ID is required'));
    }
    return await _repository.getShopStaff(
      shopId: shopId.trim(),
      forceRefresh: forceRefresh,
    );
  }
}

class InviteStaffUseCase {
  final StaffRepository _repository;

  const InviteStaffUseCase(this._repository);

  Future<Result<StaffMemberModel, Failure>> execute({
    required String shopId,
    required String email,
    required StaffRole role,
  }) async {
    final cleanShopId = shopId.trim();
    final cleanEmail = email.trim().toLowerCase();

    if (cleanShopId.isEmpty) {
      return const ErrorResult(ValidationFailure('Shop ID is required'));
    }

    if (cleanEmail.isEmpty ||
        !cleanEmail.contains('@') ||
        !cleanEmail.contains('.')) {
      return const ErrorResult(
          ValidationFailure('Valid email address is required'));
    }

    if (role == StaffRole.owner) {
      return const ErrorResult(ValidationFailure(
          'Cannot invite staff as OWNER. Please select a valid staff role.'));
    }

    return await _repository.inviteStaff(
      shopId: cleanShopId,
      email: cleanEmail,
      role: role,
    );
  }
}

class UpdateStaffRoleUseCase {
  final StaffRepository _repository;

  const UpdateStaffRoleUseCase(this._repository);

  Future<Result<StaffMemberModel, Failure>> execute({
    required StaffMemberModel targetMember,
    required StaffRole newRole,
  }) async {
    if (targetMember.isOwner) {
      return const ErrorResult(
          AuthFailure('The OWNER role is protected and cannot be changed.'));
    }

    if (newRole == StaffRole.owner) {
      return const ErrorResult(
          ValidationFailure('Cannot assign OWNER role to staff members.'));
    }

    if (targetMember.role == newRole) {
      return Success(targetMember);
    }

    return await _repository.updateStaffRole(
      membershipId: targetMember.id,
      newRole: newRole,
    );
  }
}

class ToggleStaffStatusUseCase {
  final StaffRepository _repository;

  const ToggleStaffStatusUseCase(this._repository);

  Future<Result<StaffMemberModel, Failure>> execute({
    required StaffMemberModel targetMember,
    required StaffStatus newStatus,
  }) async {
    if (targetMember.isOwner) {
      return const ErrorResult(AuthFailure(
          'The OWNER membership is protected and cannot be deactivated.'));
    }

    if (targetMember.status == newStatus) {
      return Success(targetMember);
    }

    return await _repository.updateStaffStatus(
      membershipId: targetMember.id,
      newStatus: newStatus,
    );
  }
}
