import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_mobile/core/errors/failure.dart';
import 'package:kirana_mobile/core/errors/result.dart';
import 'package:kirana_mobile/features/staff/domain/models/staff_member_model.dart';
import 'package:kirana_mobile/features/staff/domain/repositories/staff_repository.dart';
import 'package:kirana_mobile/features/staff/domain/usecases/staff_usecases.dart';

class MockStaffRepository implements StaffRepository {
  final List<StaffMemberModel> _staffList = [
    StaffMemberModel(
      id: 'staff_owner_1',
      shopId: 'shop_100',
      userId: 'user_owner_1',
      email: 'owner@store.com',
      displayName: 'Shop Owner',
      phone: '9845011111',
      role: StaffRole.owner,
      status: StaffStatus.active,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    StaffMemberModel(
      id: 'staff_cashier_1',
      shopId: 'shop_100',
      userId: 'user_cashier_1',
      email: 'cashier@store.com',
      displayName: 'Rahul Cashier',
      phone: '9845022222',
      role: StaffRole.cashier,
      status: StaffStatus.active,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
  ];

  bool isOffline = false;

  @override
  Future<Result<List<StaffMemberModel>, Failure>> getShopStaff({
    required String shopId,
    bool forceRefresh = false,
  }) async {
    if (isOffline) {
      return Success(
        List.unmodifiable(_staffList.where((m) => m.shopId == shopId)),
      );
    }
    return Success(
      List.unmodifiable(_staffList.where((m) => m.shopId == shopId)),
    );
  }

  @override
  Future<Result<StaffMemberModel, Failure>> inviteStaff({
    required String shopId,
    required String email,
    required StaffRole role,
  }) async {
    if (isOffline) {
      return const ErrorResult(
        NetworkFailure("You're offline. Please reconnect and try again."),
      );
    }

    final exists = _staffList.any(
      (m) =>
          m.shopId == shopId &&
          m.email == email &&
          m.status != StaffStatus.deactivated,
    );

    if (exists) {
      return const ErrorResult(
        ValidationFailure(
            'An active or pending invitation already exists for this email.'),
      );
    }

    final newMember = StaffMemberModel(
      id: 'staff_inv_${_staffList.length + 1}',
      shopId: shopId,
      email: email,
      displayName: email.split('@').first,
      role: role,
      status: StaffStatus.pending,
      createdAt: DateTime.now(),
    );

    _staffList.insert(0, newMember);
    return Success(newMember);
  }

  @override
  Future<Result<StaffMemberModel, Failure>> updateStaffRole({
    required String membershipId,
    required StaffRole newRole,
  }) async {
    if (isOffline) {
      return const ErrorResult(
        NetworkFailure("You're offline. Please reconnect and try again."),
      );
    }

    final idx = _staffList.indexWhere((m) => m.id == membershipId);
    if (idx == -1) {
      return const ErrorResult(DatabaseFailure('Staff member not found'));
    }

    final updated = _staffList[idx].copyWith(role: newRole);
    _staffList[idx] = updated;
    return Success(updated);
  }

  @override
  Future<Result<StaffMemberModel, Failure>> updateStaffStatus({
    required String membershipId,
    required StaffStatus newStatus,
  }) async {
    if (isOffline) {
      return const ErrorResult(
        NetworkFailure("You're offline. Please reconnect and try again."),
      );
    }

    final idx = _staffList.indexWhere((m) => m.id == membershipId);
    if (idx == -1) {
      return const ErrorResult(DatabaseFailure('Staff member not found'));
    }

    final updated = _staffList[idx].copyWith(status: newStatus);
    _staffList[idx] = updated;
    return Success(updated);
  }
}

void main() {
  group('KIRANAOS AUTH 7 — Shop Staff Management Tests', () {
    late MockStaffRepository repository;
    late GetStaffListUseCase getStaffListUseCase;
    late InviteStaffUseCase inviteStaffUseCase;
    late UpdateStaffRoleUseCase updateStaffRoleUseCase;
    late ToggleStaffStatusUseCase toggleStaffStatusUseCase;

    setUp(() {
      repository = MockStaffRepository();
      getStaffListUseCase = GetStaffListUseCase(repository);
      inviteStaffUseCase = InviteStaffUseCase(repository);
      updateStaffRoleUseCase = UpdateStaffRoleUseCase(repository);
      toggleStaffStatusUseCase = ToggleStaffStatusUseCase(repository);
    });

    test('1. Loads shop staff list for active shop ID', () async {
      final result = await getStaffListUseCase.execute(shopId: 'shop_100');

      expect(result.isSuccess, isTrue);
      final list = result.dataOrNull!;
      expect(list.length, 2);
      expect(list.first.email, 'owner@store.com');
      expect(list.last.role, StaffRole.cashier);
    });

    test('2. Serves cached staff list when offline', () async {
      repository.isOffline = true;
      final result = await getStaffListUseCase.execute(shopId: 'shop_100');

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull!.length, 2);
    });

    test('3. Successfully invites a new staff member as CASHIER', () async {
      final result = await inviteStaffUseCase.execute(
        shopId: 'shop_100',
        email: 'newcashier@store.com',
        role: StaffRole.cashier,
      );

      expect(result.isSuccess, isTrue);
      final member = result.dataOrNull!;
      expect(member.email, 'newcashier@store.com');
      expect(member.role, StaffRole.cashier);
      expect(member.status, StaffStatus.pending);
    });

    test('4. Prevents duplicate active/pending invitations for same email',
        () async {
      final result = await inviteStaffUseCase.execute(
        shopId: 'shop_100',
        email: 'cashier@store.com',
        role: StaffRole.manager,
      );

      expect(result.isError, isTrue);
      expect(result.failureOrNull?.message,
          'An active or pending invitation already exists for this email.');
    });

    test('5. Validates required valid email format for invitation', () async {
      final result = await inviteStaffUseCase.execute(
        shopId: 'shop_100',
        email: 'invalidemail',
        role: StaffRole.cashier,
      );

      expect(result.isError, isTrue);
      expect(result.failureOrNull?.message, 'Valid email address is required');
    });

    test('6. Rejects inviting staff members with OWNER role', () async {
      final result = await inviteStaffUseCase.execute(
        shopId: 'shop_100',
        email: 'newowner@store.com',
        role: StaffRole.owner,
      );

      expect(result.isError, isTrue);
      expect(result.failureOrNull?.message,
          'Cannot invite staff as OWNER. Please select a valid staff role.');
    });

    test('7. Updates staff role to MANAGER for valid non-owner staff',
        () async {
      final roster =
          (await getStaffListUseCase.execute(shopId: 'shop_100')).dataOrNull!;
      final cashier = roster.firstWhere((m) => m.role == StaffRole.cashier);

      final result = await updateStaffRoleUseCase.execute(
        targetMember: cashier,
        newRole: StaffRole.manager,
      );

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull!.role, StaffRole.manager);
    });

    test('8. Protects OWNER membership from role modification', () async {
      final roster =
          (await getStaffListUseCase.execute(shopId: 'shop_100')).dataOrNull!;
      final owner = roster.firstWhere((m) => m.isOwner);

      final result = await updateStaffRoleUseCase.execute(
        targetMember: owner,
        newRole: StaffRole.cashier,
      );

      expect(result.isError, isTrue);
      expect(result.failureOrNull?.message,
          'The OWNER role is protected and cannot be changed.');
    });

    test('9. Toggles staff status to DEACTIVATED', () async {
      final roster =
          (await getStaffListUseCase.execute(shopId: 'shop_100')).dataOrNull!;
      final cashier = roster.firstWhere((m) => m.role == StaffRole.cashier);

      final result = await toggleStaffStatusUseCase.execute(
        targetMember: cashier,
        newStatus: StaffStatus.deactivated,
      );

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull!.isDeactivated, isTrue);
    });

    test('10. Protects OWNER membership from deactivation', () async {
      final roster =
          (await getStaffListUseCase.execute(shopId: 'shop_100')).dataOrNull!;
      final owner = roster.firstWhere((m) => m.isOwner);

      final result = await toggleStaffStatusUseCase.execute(
        targetMember: owner,
        newStatus: StaffStatus.deactivated,
      );

      expect(result.isError, isTrue);
      expect(result.failureOrNull?.message,
          'The OWNER membership is protected and cannot be deactivated.');
    });

    test(
        '11. Offline invitation attempt returns clear network error without faking',
        () async {
      repository.isOffline = true;

      final result = await inviteStaffUseCase.execute(
        shopId: 'shop_100',
        email: 'offline_staff@store.com',
        role: StaffRole.cashier,
      );

      expect(result.isError, isTrue);
      expect(result.failureOrNull?.message,
          "You're offline. Please reconnect and try again.");
    });
  });
}
