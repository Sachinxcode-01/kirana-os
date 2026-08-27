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
import '../../domain/models/payment_model.dart';
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

final applyBillDiscountUseCaseProvider =
    Provider<ApplyBillDiscountUseCase>((ref) {
  final calc = ref.watch(calculateBillTotalsUseCaseProvider);
  return ApplyBillDiscountUseCase(calc);
});

final attachCustomerToBillUseCaseProvider =
    Provider<AttachCustomerToBillUseCase>((ref) {
  return AttachCustomerToBillUseCase();
});

final removeCustomerFromBillUseCaseProvider =
    Provider<RemoveCustomerFromBillUseCase>((ref) {
  return RemoveCustomerFromBillUseCase();
});

final validateBillUseCaseProvider = Provider<ValidateBillUseCase>((ref) {
  return ValidateBillUseCase();
});

final saveDraftBillUseCaseProvider = Provider<SaveDraftBillUseCase>((ref) {
  final repo = ref.watch(billingRepositoryProvider);
  return SaveDraftBillUseCase(repo);
});

final completeSaleCheckoutUseCaseProvider =
    Provider<CompleteSaleCheckoutUseCase>((ref) {
  final repo = ref.watch(billingRepositoryProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  final validate = ref.watch(validateBillUseCaseProvider);
  return CompleteSaleCheckoutUseCase(
    repository: repo,
    connectivityService: connectivity,
    validateBillUseCase: validate,
  );
});

class BillingNotifier extends StateNotifier<BillingState> {
  final CreateDraftBillUseCase _createDraftUseCase;
  final AddProductToBillUseCase _addProductUseCase;
  final UpdateBillItemQuantityUseCase _updateQuantityUseCase;
  final RemoveBillItemUseCase _removeItemUseCase;
  final ApplyBillDiscountUseCase _applyDiscountUseCase;
  final AttachCustomerToBillUseCase _attachCustomerUseCase;
  final RemoveCustomerFromBillUseCase _removeCustomerUseCase;
  final ValidateBillUseCase _validateBillUseCase;
  final SaveDraftBillUseCase _saveDraftUseCase;
  final CompleteSaleCheckoutUseCase _completeCheckoutUseCase;
  final Ref _ref;

  BillingNotifier({
    required CreateDraftBillUseCase createDraftUseCase,
    required AddProductToBillUseCase addProductUseCase,
    required UpdateBillItemQuantityUseCase updateQuantityUseCase,
    required RemoveBillItemUseCase removeItemUseCase,
    required ApplyBillDiscountUseCase applyDiscountUseCase,
    required AttachCustomerToBillUseCase attachCustomerUseCase,
    required RemoveCustomerFromBillUseCase removeCustomerUseCase,
    required ValidateBillUseCase validateBillUseCase,
    required SaveDraftBillUseCase saveDraftUseCase,
    required CompleteSaleCheckoutUseCase completeCheckoutUseCase,
    required Ref ref,
  })  : _createDraftUseCase = createDraftUseCase,
        _addProductUseCase = addProductUseCase,
        _updateQuantityUseCase = updateQuantityUseCase,
        _removeItemUseCase = removeItemUseCase,
        _applyDiscountUseCase = applyDiscountUseCase,
        _attachCustomerUseCase = attachCustomerUseCase,
        _removeCustomerUseCase = removeCustomerUseCase,
        _validateBillUseCase = validateBillUseCase,
        _saveDraftUseCase = saveDraftUseCase,
        _completeCheckoutUseCase = completeCheckoutUseCase,
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

  bool applyDiscount({
    required String discountType, // 'none', 'percentage', 'fixed'
    required double discountValue,
  }) {
    if (state.activeDraft == null) return false;

    final settingsState = _ref.read(shopSettingsNotifierProvider);
    final isTaxEnabled = settingsState.settings?.isTaxEnabled ?? false;
    final defaultTax = settingsState.settings?.defaultTaxPercentage ?? 0.0;

    final result = _applyDiscountUseCase.execute(
      bill: state.activeDraft!,
      discountType: discountType,
      discountValue: discountValue,
      isTaxEnabled: isTaxEnabled,
      defaultTaxPercentage: defaultTax,
    );

    if (result.isSuccess) {
      final updated = result.dataOrNull!;
      state = state.copyWith(
        activeDraft: updated,
        successMessage: 'Discount applied successfully.',
        clearError: true,
      );
      _autoSave(updated);
      return true;
    } else {
      state = state.copyWith(errorMessage: result.failureOrNull?.message);
      return false;
    }
  }

  void attachCustomer({
    required String customerId,
    required String customerName,
    required String customerPhone,
  }) {
    if (state.activeDraft == null) return;

    final updated = _attachCustomerUseCase.execute(
      bill: state.activeDraft!,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
    );

    state = state.copyWith(
      activeDraft: updated,
      successMessage: 'Customer "$customerName" attached.',
      clearError: true,
    );

    _autoSave(updated);
  }

  void removeCustomer() {
    if (state.activeDraft == null) return;

    final updated = _removeCustomerUseCase.execute(state.activeDraft!);
    state = state.copyWith(
      activeDraft: updated,
      successMessage: 'Customer removed from bill.',
      clearError: true,
    );

    _autoSave(updated);
  }

  Future<bool> saveDraft() async {
    if (state.activeDraft == null) return false;

    final authState = _ref.read(authNotifierProvider);
    final activeShopId = authState.activeShopId ?? '';
    final userRole = authState.user?.role ?? 'cashier';

    final validation = _validateBillUseCase.execute(
      bill: state.activeDraft!,
      activeShopId: activeShopId,
      userRole: userRole,
    );

    if (validation.isError) {
      state = state.copyWith(errorMessage: validation.failureOrNull?.message);
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _saveDraftUseCase.execute(state.activeDraft!);

    if (result.isSuccess) {
      final saved = result.dataOrNull!;
      state = state.copyWith(
        isLoading: false,
        activeDraft: saved,
        successMessage: 'Draft bill ${saved.billNumber} saved successfully.',
      );
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.failureOrNull?.message,
      );
      return false;
    }
  }

  Future<bool> completeCheckout({
    required String paymentMode, // 'cash', 'upi_qr', 'card'
  }) async {
    if (state.activeDraft == null) return false;

    final authState = _ref.read(authNotifierProvider);
    final activeShopId = authState.activeShopId ?? '';
    final userRole = authState.user?.role ?? 'cashier';

    final bill = state.activeDraft!;
    final now = DateTime.now();
    final paymentId =
        'pay_${now.millisecondsSinceEpoch}_${bill.id.substring(0, 4)}';

    final payment = PaymentModel(
      id: paymentId,
      shopId: bill.shopId,
      billId: bill.id,
      mode: paymentMode,
      amountPaise: bill.totalPaise,
      status: 'pending',
      createdAt: now,
    );

    final idempotencyKey = 'checkout_${bill.id}_${now.millisecondsSinceEpoch}';

    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _completeCheckoutUseCase.execute(
      bill: bill,
      payment: payment,
      activeShopId: activeShopId,
      userRole: userRole,
      idempotencyKey: idempotencyKey,
    );

    if (result.isSuccess) {
      final completed = result.dataOrNull!;
      state = state.copyWith(
        isLoading: false,
        activeDraft: completed,
        successMessage: 'Sale completed successfully!',
      );
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.failureOrNull?.message,
      );
      return false;
    }
  }

  void resetDraft() {
    state = state.copyWith(activeDraft: null);
    initializeDraft();
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
    applyDiscountUseCase: ref.watch(applyBillDiscountUseCaseProvider),
    attachCustomerUseCase: ref.watch(attachCustomerToBillUseCaseProvider),
    removeCustomerUseCase: ref.watch(removeCustomerFromBillUseCaseProvider),
    validateBillUseCase: ref.watch(validateBillUseCaseProvider),
    saveDraftUseCase: ref.watch(saveDraftBillUseCaseProvider),
    completeCheckoutUseCase: ref.watch(completeSaleCheckoutUseCaseProvider),
    ref: ref,
  );
});
