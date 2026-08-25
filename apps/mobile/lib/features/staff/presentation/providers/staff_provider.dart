import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/staff_remote_data_source.dart';
import '../../data/repositories/staff_repository_impl.dart';
import '../../domain/models/staff_member_model.dart';
import '../../domain/repositories/staff_repository.dart';
import '../../domain/usecases/staff_usecases.dart';

final staffRemoteDataSourceProvider = Provider<StaffRemoteDataSource>((ref) {
  return StaffRemoteDataSource();
});

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  final remoteDataSource = ref.watch(staffRemoteDataSourceProvider);
  return StaffRepositoryImpl(remoteDataSource: remoteDataSource);
});

final getStaffListUseCaseProvider = Provider<GetStaffListUseCase>((ref) {
  final repository = ref.watch(staffRepositoryProvider);
  return GetStaffListUseCase(repository);
});

final inviteStaffUseCaseProvider = Provider<InviteStaffUseCase>((ref) {
  final repository = ref.watch(staffRepositoryProvider);
  return InviteStaffUseCase(repository);
});

final updateStaffRoleUseCaseProvider = Provider<UpdateStaffRoleUseCase>((ref) {
  final repository = ref.watch(staffRepositoryProvider);
  return UpdateStaffRoleUseCase(repository);
});

final toggleStaffStatusUseCaseProvider =
    Provider<ToggleStaffStatusUseCase>((ref) {
  final repository = ref.watch(staffRepositoryProvider);
  return ToggleStaffStatusUseCase(repository);
});

class StaffState {
  final bool isLoading;
  final List<StaffMemberModel> staffList;
  final String? errorMessage;
  final String? successMessage;
  final StaffStatus? filterStatus;

  const StaffState({
    this.isLoading = false,
    this.staffList = const [],
    this.errorMessage,
    this.successMessage,
    this.filterStatus,
  });

  List<StaffMemberModel> get filteredStaffList {
    if (filterStatus == null) return staffList;
    return staffList.where((member) => member.status == filterStatus).toList();
  }

  StaffState copyWith({
    bool? isLoading,
    List<StaffMemberModel>? staffList,
    String? errorMessage,
    String? successMessage,
    StaffStatus? filterStatus,
    bool clearFilter = false,
  }) {
    return StaffState(
      isLoading: isLoading ?? this.isLoading,
      staffList: staffList ?? this.staffList,
      errorMessage: errorMessage,
      successMessage: successMessage,
      filterStatus: clearFilter ? null : (filterStatus ?? this.filterStatus),
    );
  }
}

class StaffNotifier extends StateNotifier<StaffState> {
  final GetStaffListUseCase _getStaffListUseCase;
  final InviteStaffUseCase _inviteStaffUseCase;
  final UpdateStaffRoleUseCase _updateStaffRoleUseCase;
  final ToggleStaffStatusUseCase _toggleStaffStatusUseCase;
  final Ref _ref;

  StaffNotifier({
    required GetStaffListUseCase getStaffListUseCase,
    required InviteStaffUseCase inviteStaffUseCase,
    required UpdateStaffRoleUseCase updateStaffRoleUseCase,
    required ToggleStaffStatusUseCase toggleStaffStatusUseCase,
    required Ref ref,
  })  : _getStaffListUseCase = getStaffListUseCase,
        _inviteStaffUseCase = inviteStaffUseCase,
        _updateStaffRoleUseCase = updateStaffRoleUseCase,
        _toggleStaffStatusUseCase = toggleStaffStatusUseCase,
        _ref = ref,
        super(const StaffState());

  Future<void> loadStaff({bool forceRefresh = false}) async {
    final shopId = _ref.read(authNotifierProvider).activeShopId;
    if (shopId == null || shopId.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No active shop selected.',
      );
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _getStaffListUseCase.execute(
      shopId: shopId,
      forceRefresh: forceRefresh,
    );

    result.fold(
      (list) {
        state = state.copyWith(
          isLoading: false,
          staffList: list,
        );
      },
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
      },
    );
  }

  Future<bool> inviteStaff({
    required String email,
    required StaffRole role,
  }) async {
    final shopId = _ref.read(authNotifierProvider).activeShopId;
    if (shopId == null || shopId.isEmpty) {
      state = state.copyWith(errorMessage: 'No active shop selected.');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _inviteStaffUseCase.execute(
      shopId: shopId,
      email: email,
      role: role,
    );

    return result.fold(
      (invitedMember) {
        final updatedList = [invitedMember, ...state.staffList];
        state = state.copyWith(
          isLoading: false,
          staffList: updatedList,
          successMessage: 'Invitation sent successfully to $email!',
        );
        return true;
      },
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
        return false;
      },
    );
  }

  Future<bool> updateRole({
    required StaffMemberModel targetMember,
    required StaffRole newRole,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _updateStaffRoleUseCase.execute(
      targetMember: targetMember,
      newRole: newRole,
    );

    return result.fold(
      (updatedMember) {
        final newList = state.staffList.map((item) {
          return item.id == updatedMember.id ? updatedMember : item;
        }).toList();

        state = state.copyWith(
          isLoading: false,
          staffList: newList,
          successMessage:
              'Role updated to ${newRole.label} for ${updatedMember.email}!',
        );
        return true;
      },
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
        return false;
      },
    );
  }

  Future<bool> toggleStatus({
    required StaffMemberModel targetMember,
    required StaffStatus newStatus,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _toggleStaffStatusUseCase.execute(
      targetMember: targetMember,
      newStatus: newStatus,
    );

    return result.fold(
      (updatedMember) {
        final newList = state.staffList.map((item) {
          return item.id == updatedMember.id ? updatedMember : item;
        }).toList();

        state = state.copyWith(
          isLoading: false,
          staffList: newList,
          successMessage:
              'Status updated to ${newStatus.label} for ${updatedMember.email}!',
        );
        return true;
      },
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
        return false;
      },
    );
  }

  void setFilterStatus(StaffStatus? status) {
    if (status == null) {
      state = state.copyWith(clearFilter: true);
    } else {
      state = state.copyWith(filterStatus: status);
    }
  }

  void clearMessages() {
    state = state.copyWith();
  }
}

final staffNotifierProvider =
    StateNotifierProvider<StaffNotifier, StaffState>((ref) {
  final getStaffListUseCase = ref.watch(getStaffListUseCaseProvider);
  final inviteStaffUseCase = ref.watch(inviteStaffUseCaseProvider);
  final updateStaffRoleUseCase = ref.watch(updateStaffRoleUseCaseProvider);
  final toggleStaffStatusUseCase = ref.watch(toggleStaffStatusUseCaseProvider);

  final notifier = StaffNotifier(
    getStaffListUseCase: getStaffListUseCase,
    inviteStaffUseCase: inviteStaffUseCase,
    updateStaffRoleUseCase: updateStaffRoleUseCase,
    toggleStaffStatusUseCase: toggleStaffStatusUseCase,
    ref: ref,
  );

  notifier.loadStaff();
  return notifier;
});
