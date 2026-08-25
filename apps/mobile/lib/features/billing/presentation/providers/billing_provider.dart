import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/network/connectivity_status.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../products/domain/models/product_model.dart';
import '../../../settings/presentation/providers/shop_settings_provider.dart';
import '../../data/datasources/billing_local_data_source.dart';
import '../../data/datasources/billing_remote_data_source.dart';
import '../../data/repositories/billing_repository_impl.dart';
import '../../domain/models/bill_model.dart';
import '../../domain/repositories/billing_repository.dart';
import '../../domain/usecases/billing_usecases.dart';

class BillingState {
  final BillModel? activeDraft;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final bool isOffline;

  const BillingState({
    this.activeDraft,
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.isOffline = false,
  });

  BillingState copyWith({
    BillModel? activeDraft,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool? isOffline,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearDraft = false,
  }) {
    return BillingState(
      activeDraft: clearDraft ? null : (activeDraft ?? this.activeDraft),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
      isOffline: isOffline ?? this.isOffline,
    );
  }
}

final billingLocalDataSourceProvider = Provider<BillingLocalDataSource>((ref) {
  return BillingLocalDataSource();
});

final billingRemoteDataSourceProvider =
    Provider<BillingRemoteDataSource>((ref) {
  return BillingRemoteDataSource();
});

final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  final local = ref.watch(billingLocalDataSourceProvider);
  final remote = ref.watch(billingRemoteDataSourceProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  return BillingRepositoryImpl(
    localDataSource: local,
    remoteDataSource: remote,
    connectivityService: connectivity,
  );
});

final calculateBillTotalsUseCaseProvider =
    Provider<CalculateBillTotalsUseCase>((ref) {
  return CalculateBillTotalsUseCase();
});

final createDraftBillUseCaseProvider = Provider<CreateDraftBillUseCase>((ref) {
  final repo = ref.watch(billingRepositoryProvider);
  return CreateDraftBillUseCase(repo);
});

final addProductToBillUseCaseProvider =
    Provider<AddProductToBillUseCase>((ref) {
  final calc = ref.watch(calculateBillTotalsUseCaseProvider);
  return AddProductToBillUseCase(calc);
});

final updateBillItemQuantityUseCaseProvider =
    Provider<UpdateBillItemQuantityUseCase>((ref) {
  final calc = ref.watch(calculateBillTotalsUseCaseProvider);
  return UpdateBillItemQuantityUseCase(calc);
});

final removeBillItemUseCaseProvider = Provider<RemoveBillItemUseCase>((ref) {
  final calc = ref.watch(calculateBillTotalsUseCaseProvider);
  return RemoveBillItemUseCase(calc);
});

final saveDraftBillUseCaseProvider = Provider<SaveDraftBillUseCase>((ref) {
  final repo = ref.watch(billingRepositoryProvider);
  return SaveDraftBillUseCase(repo);
});

class BillingNotifier extends StateNotifier<BillingState> {
  final CreateDraftBillUseCase _createDraftUseCase;
  final AddProductToBillUseCase _addProductUseCase;
  final UpdateBillItemQuantityUseCase _updateQuantityUseCase;
  final RemoveBillItemUseCase _removeItemUseCase;
  final SaveDraftBillUseCase _saveDraftUseCase;
  final Ref _ref;

  BillingNotifier({
    required CreateDraftBillUseCase createDraftUseCase,
    required AddProductToBillUseCase addProductUseCase,
    required UpdateBillItemQuantityUseCase updateQuantityUseCase,
    required RemoveBillItemUseCase removeItemUseCase,
    required SaveDraftBillUseCase saveDraftUseCase,
    required Ref ref,
  })  : _createDraftUseCase = createDraftUseCase,
        _addProductUseCase = addProductUseCase,
        _updateQuantityUseCase = updateQuantityUseCase,
        _removeItemUseCase = removeItemUseCase,
        _saveDraftUseCase = saveDraftUseCase,
        _ref = ref,
        super(const BillingState());

  Future<void> initializeDraft() async {
    if (state.activeDraft != null) return;

    final authState = _ref.read(authNotifierProvider);
    final activeShopId = authState.activeShopId;
    final cashierId = authState.user?.id ?? 'cashier_unknown';
    final userRole = authState.user?.role ?? 'cashier';

    if (activeShopId == null) return;

    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _createDraftUseCase.execute(
      shopId: activeShopId,
      cashierId: cashierId,
      userRole: userRole,
    );

    if (result.isSuccess) {
      state = state.copyWith(
        isLoading: false,
        activeDraft: result.dataOrNull,
        isOffline: _ref.read(connectivityServiceProvider).currentStatus ==
            ConnectivityStatus.offline,
      );
    } else if (result.isError) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.failureOrNull?.message,
      );
    }
  }

  void addProduct(ProductModel product, {double quantity = 1.0}) {
    if (state.activeDraft == null) return;

    final settingsState = _ref.read(shopSettingsNotifierProvider);
    final isTaxEnabled = settingsState.settings?.isTaxEnabled ?? false;
    final defaultTax = settingsState.settings?.defaultTaxPercentage ?? 0.0;

    final updatedDraft = _addProductUseCase.execute(
      bill: state.activeDraft!,
      product: product,
      quantity: quantity,
      isTaxEnabled: isTaxEnabled,
      defaultTaxPercentage: defaultTax,
    );

    state = state.copyWith(
      activeDraft: updatedDraft,
      successMessage: '${product.name} added to bill.',
      clearError: true,
    );

    _autoSave(updatedDraft);
  }

  void updateQuantity(String itemId, double newQuantity) {
    if (state.activeDraft == null) return;

    final settingsState = _ref.read(shopSettingsNotifierProvider);
    final isTaxEnabled = settingsState.settings?.isTaxEnabled ?? false;
    final defaultTax = settingsState.settings?.defaultTaxPercentage ?? 0.0;

    final updatedDraft = _updateQuantityUseCase.execute(
      bill: state.activeDraft!,
      itemId: itemId,
      newQuantity: newQuantity,
      isTaxEnabled: isTaxEnabled,
      defaultTaxPercentage: defaultTax,
    );

    state = state.copyWith(activeDraft: updatedDraft, clearError: true);
    _autoSave(updatedDraft);
  }

  void removeItem(String itemId) {
    if (state.activeDraft == null) return;

    final settingsState = _ref.read(shopSettingsNotifierProvider);
    final isTaxEnabled = settingsState.settings?.isTaxEnabled ?? false;
    final defaultTax = settingsState.settings?.defaultTaxPercentage ?? 0.0;

    final updatedDraft = _removeItemUseCase.execute(
      bill: state.activeDraft!,
      itemId: itemId,
      isTaxEnabled: isTaxEnabled,
      defaultTaxPercentage: defaultTax,
    );

    state = state.copyWith(
      activeDraft: updatedDraft,
      successMessage: 'Item removed from bill.',
      clearError: true,
    );

    _autoSave(updatedDraft);
  }

  Future<void> saveDraft() async {
    if (state.activeDraft == null) return;

    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _saveDraftUseCase.execute(state.activeDraft!);

    if (result.isSuccess) {
      final saved = result.dataOrNull!;
      state = state.copyWith(
        isLoading: false,
        activeDraft: saved,
        successMessage: 'Draft bill ${saved.billNumber} saved successfully.',
      );
    } else if (result.isError) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.failureOrNull?.message,
      );
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  Future<void> _autoSave(BillModel bill) async {
    await _saveDraftUseCase.execute(bill);
  }
}

final billingNotifierProvider =
    StateNotifierProvider<BillingNotifier, BillingState>((ref) {
  return BillingNotifier(
    createDraftUseCase: ref.watch(createDraftBillUseCaseProvider),
    addProductUseCase: ref.watch(addProductToBillUseCaseProvider),
    updateQuantityUseCase: ref.watch(updateBillItemQuantityUseCaseProvider),
    removeItemUseCase: ref.watch(removeBillItemUseCaseProvider),
    saveDraftUseCase: ref.watch(saveDraftBillUseCaseProvider),
    ref: ref,
  );
});
