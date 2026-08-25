import '../../../../core/errors/error_handler.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../domain/models/staff_member_model.dart';
import '../../domain/repositories/staff_repository.dart';
import '../datasources/staff_remote_data_source.dart';

class StaffRepositoryImpl implements StaffRepository {
  final StaffRemoteDataSource _remoteDataSource;
  final List<StaffMemberModel> _memoryCache = [];
  String? _cachedShopId;

  StaffRepositoryImpl({
    required StaffRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<Result<List<StaffMemberModel>, Failure>> getShopStaff({
    required String shopId,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cachedShopId == shopId && _memoryCache.isNotEmpty) {
      return Success(List.unmodifiable(_memoryCache));
    }

    try {
      final remoteList = await _remoteDataSource.getShopStaff(shopId);
      _memoryCache.clear();
      _memoryCache.addAll(remoteList);
      _cachedShopId = shopId;
      return Success(List.unmodifiable(_memoryCache));
    } catch (e) {
      // If offline error occurred but cache exists, return cached data
      if (_cachedShopId == shopId && _memoryCache.isNotEmpty) {
        return Success(List.unmodifiable(_memoryCache));
      }
      return ErrorResult(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Result<StaffMemberModel, Failure>> inviteStaff({
    required String shopId,
    required String email,
    required StaffRole role,
  }) async {
    try {
      final invited = await _remoteDataSource.inviteStaff(
        shopId: shopId,
        email: email,
        role: role,
      );

      _memoryCache.removeWhere(
          (item) => item.id == invited.id || item.email == invited.email);
      _memoryCache.insert(0, invited);

      return Success(invited);
    } catch (e) {
      return ErrorResult(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Result<StaffMemberModel, Failure>> updateStaffRole({
    required String membershipId,
    required StaffRole newRole,
  }) async {
    try {
      final updated = await _remoteDataSource.updateStaffRole(
        membershipId: membershipId,
        newRole: newRole,
      );

      final idx = _memoryCache.indexWhere((item) => item.id == membershipId);
      if (idx != -1) {
        _memoryCache[idx] = updated;
      }

      return Success(updated);
    } catch (e) {
      return ErrorResult(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Result<StaffMemberModel, Failure>> updateStaffStatus({
    required String membershipId,
    required StaffStatus newStatus,
  }) async {
    try {
      final updated = await _remoteDataSource.updateStaffStatus(
        membershipId: membershipId,
        newStatus: newStatus,
      );

      final idx = _memoryCache.indexWhere((item) => item.id == membershipId);
      if (idx != -1) {
        _memoryCache[idx] = updated;
      }

      return Success(updated);
    } catch (e) {
      return ErrorResult(ErrorHandler.handle(e));
    }
  }
}
