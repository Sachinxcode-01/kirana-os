import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../models/staff_member_model.dart';

abstract interface class StaffRepository {
  Future<Result<List<StaffMemberModel>, Failure>> getShopStaff({
    required String shopId,
    bool forceRefresh = false,
  });

  Future<Result<StaffMemberModel, Failure>> inviteStaff({
    required String shopId,
    required String email,
    required StaffRole role,
  });

  Future<Result<StaffMemberModel, Failure>> updateStaffRole({
    required String membershipId,
    required StaffRole newRole,
  });

  Future<Result<StaffMemberModel, Failure>> updateStaffStatus({
    required String membershipId,
    required StaffStatus newStatus,
  });
}
