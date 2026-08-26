import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/supplier_local_data_source.dart';
import '../../data/datasources/supplier_remote_data_source.dart';
import '../../data/repositories/supplier_repository_impl.dart';
import '../../domain/models/supplier_model.dart';
import '../../domain/repositories/supplier_repository.dart';

final supplierLocalDataSourceProvider =
    Provider<SupplierLocalDataSource>((ref) {
  return SupplierLocalDataSource();
});

final supplierRemoteDataSourceProvider =
    Provider<SupplierRemoteDataSource>((ref) {
  return SupplierRemoteDataSource();
});

final supplierRepositoryProvider = Provider<SupplierRepository>((ref) {
  final local = ref.watch(supplierLocalDataSourceProvider);
  final remote = ref.watch(supplierRemoteDataSourceProvider);
  final conn = ConnectivityService();
  return SupplierRepositoryImpl(
    localDataSource: local,
    remoteDataSource: remote,
    connectivityService: conn,
  );
});

class SuppliersListState {
  final List<SupplierModel> suppliers;
  final bool isLoading;
  final String searchQuery;
  final bool includeArchived;
  final String? errorMessage;

  const SuppliersListState({
    this.suppliers = const [],
    this.isLoading = false,
    this.searchQuery = '',
    this.includeArchived = false,
    this.errorMessage,
  });

  SuppliersListState copyWith({
    List<SupplierModel>? suppliers,
    bool? isLoading,
    String? searchQuery,
    bool? includeArchived,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return SuppliersListState(
      suppliers: suppliers ?? this.suppliers,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      includeArchived: includeArchived ?? this.includeArchived,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class SuppliersListNotifier extends StateNotifier<SuppliersListState> {
  final Ref _ref;

  SuppliersListNotifier(this._ref) : super(const SuppliersListState()) {
    loadSuppliers();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    loadSuppliers();
  }

  void setIncludeArchived(bool include) {
    state = state.copyWith(includeArchived: include);
    loadSuppliers();
  }

  Future<void> loadSuppliers() async {
    final authState = _ref.read(authNotifierProvider);
    final shopId = authState.activeShopId;

    if (shopId == null || shopId.isEmpty) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'No active shop context.');
      return;
    }

    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    final repo = _ref.read(supplierRepositoryProvider);
    final res = await repo.getSuppliers(
      shopId: shopId,
      includeArchived: state.includeArchived,
      searchQuery: state.searchQuery,
    );

    switch (res) {
      case Success(:final data):
        state = state.copyWith(suppliers: data, isLoading: false);
      case ErrorResult(:final failure):
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
    }
  }
}

final suppliersListNotifierProvider =
    StateNotifierProvider<SuppliersListNotifier, SuppliersListState>((ref) {
  return SuppliersListNotifier(ref);
});

class SupplierFormState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const SupplierFormState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  SupplierFormState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? successMessage,
    bool clearSuccessMessage = false,
  }) {
    return SupplierFormState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccessMessage ? null : (successMessage ?? this.successMessage),
    );
  }
}

class SupplierFormNotifier extends StateNotifier<SupplierFormState> {
  final Ref _ref;

  SupplierFormNotifier(this._ref) : super(const SupplierFormState());

  Future<bool> createSupplier({
    required String name,
    required String phone,
    String? contactPerson,
    String? email,
    String? address,
    String? gstin,
    String? notes,
  }) async {
    final authState = _ref.read(authNotifierProvider);
    final shopId = authState.activeShopId;

    if (shopId == null) {
      state = state.copyWith(errorMessage: 'No active shop context.');
      return false;
    }

    state = state.copyWith(
        isLoading: true, clearErrorMessage: true, clearSuccessMessage: true);
    final repo = _ref.read(supplierRepositoryProvider);

    final res = await repo.createSupplier(
      shopId: shopId,
      name: name,
      phone: phone,
      contactPerson: contactPerson,
      email: email,
      address: address,
      gstin: gstin,
      notes: notes,
    );

    switch (res) {
      case Success(:final data):
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Supplier "${data.name}" added successfully.',
        );
        _ref.read(suppliersListNotifierProvider.notifier).loadSuppliers();
        return true;
      case ErrorResult(:final failure):
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
    }
  }

  Future<bool> updateSupplier(SupplierModel supplier) async {
    state = state.copyWith(
        isLoading: true, clearErrorMessage: true, clearSuccessMessage: true);
    final repo = _ref.read(supplierRepositoryProvider);
    final res = await repo.updateSupplier(supplier);

    switch (res) {
      case Success(:final data):
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Supplier "${data.name}" updated successfully.',
        );
        _ref.read(suppliersListNotifierProvider.notifier).loadSuppliers();
        return true;
      case ErrorResult(:final failure):
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
    }
  }

  Future<bool> archiveSupplier(String supplierId) async {
    final authState = _ref.read(authNotifierProvider);
    final shopId = authState.activeShopId;

    if (shopId == null) {
      state = state.copyWith(errorMessage: 'No active shop context.');
      return false;
    }

    state = state.copyWith(
        isLoading: true, clearErrorMessage: true, clearSuccessMessage: true);
    final repo = _ref.read(supplierRepositoryProvider);
    final res =
        await repo.archiveSupplier(shopId: shopId, supplierId: supplierId);

    switch (res) {
      case Success(:final data):
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Supplier "${data.name}" archived.',
        );
        _ref.read(suppliersListNotifierProvider.notifier).loadSuppliers();
        return true;
      case ErrorResult(:final failure):
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
    }
  }

  void clearMessages() {
    state = const SupplierFormState();
  }
}

final supplierFormNotifierProvider =
    StateNotifierProvider<SupplierFormNotifier, SupplierFormState>((ref) {
  return SupplierFormNotifier(ref);
});
