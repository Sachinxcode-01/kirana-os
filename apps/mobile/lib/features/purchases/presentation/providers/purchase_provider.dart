import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../products/domain/models/product_model.dart';
import '../../../suppliers/domain/models/supplier_model.dart';
import '../../data/datasources/purchase_local_data_source.dart';

import '../../data/datasources/purchase_remote_data_source.dart';
import '../../data/repositories/purchase_repository_impl.dart';
import '../../domain/models/purchase_item_model.dart';
import '../../domain/models/purchase_model.dart';
import '../../domain/repositories/purchase_repository.dart';

final purchaseLocalDataSourceProvider =
    Provider<PurchaseLocalDataSource>((ref) {
  return PurchaseLocalDataSource();
});

final purchaseRemoteDataSourceProvider =
    Provider<PurchaseRemoteDataSource>((ref) {
  return PurchaseRemoteDataSource();
});

final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  final local = ref.watch(purchaseLocalDataSourceProvider);
  final remote = ref.watch(purchaseRemoteDataSourceProvider);
  final conn = ConnectivityService();
  return PurchaseRepositoryImpl(
    localDataSource: local,
    remoteDataSource: remote,
    connectivityService: conn,
  );
});

class PurchasesListState {
  final List<PurchaseModel> purchases;
  final bool isLoading;
  final String? errorMessage;

  const PurchasesListState({
    this.purchases = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  PurchasesListState copyWith({
    List<PurchaseModel>? purchases,
    bool? isLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return PurchasesListState(
      purchases: purchases ?? this.purchases,
      isLoading: isLoading ?? this.isLoading,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class PurchasesListNotifier extends StateNotifier<PurchasesListState> {
  final Ref _ref;

  PurchasesListNotifier(this._ref) : super(const PurchasesListState()) {
    loadPurchases();
  }

  Future<void> loadPurchases() async {
    final authState = _ref.read(authNotifierProvider);
    final shopId = authState.activeShopId;

    if (shopId == null || shopId.isEmpty) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'No active shop context.');
      return;
    }

    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    final repo = _ref.read(purchaseRepositoryProvider);
    final res = await repo.getShopPurchases(shopId);

    switch (res) {
      case Success(:final data):
        state = state.copyWith(purchases: data, isLoading: false);
      case ErrorResult(:final failure):
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
    }
  }
}

final purchasesListNotifierProvider =
    StateNotifierProvider<PurchasesListNotifier, PurchasesListState>((ref) {
  return PurchasesListNotifier(ref);
});

class PurchaseDraftState {
  final PurchaseModel? draft;
  final bool isSaving;
  final bool isConfirming;
  final String? errorMessage;
  final String? successMessage;

  const PurchaseDraftState({
    this.draft,
    this.isSaving = false,
    this.isConfirming = false,
    this.errorMessage,
    this.successMessage,
  });

  PurchaseDraftState copyWith({
    PurchaseModel? draft,
    bool clearDraft = false,
    bool? isSaving,
    bool? isConfirming,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? successMessage,
    bool clearSuccessMessage = false,
  }) {
    return PurchaseDraftState(
      draft: clearDraft ? null : (draft ?? this.draft),
      isSaving: isSaving ?? this.isSaving,
      isConfirming: isConfirming ?? this.isConfirming,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccessMessage ? null : (successMessage ?? this.successMessage),
    );
  }
}

class PurchaseDraftNotifier extends StateNotifier<PurchaseDraftState> {
  final Ref _ref;
  final _uuid = const Uuid();

  PurchaseDraftNotifier(this._ref) : super(const PurchaseDraftState());

  void initNewDraft({String? supplierReference}) {
    final authState = _ref.read(authNotifierProvider);
    final shopId = authState.activeShopId ?? 'shop_demo';
    final now = DateTime.now();

    final purchaseId =
        'purch_${now.millisecondsSinceEpoch}_${_uuid.v4().substring(0, 8)}';
    final purchaseNum =
        'PUR-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(8)}';

    final draft = PurchaseModel.create(
      id: purchaseId,
      shopId: shopId,
      purchaseNumber: purchaseNum,
      supplierReference: supplierReference,
      status: 'draft',
      items: const [],
      createdAt: now,
      updatedAt: now,
    );

    state = PurchaseDraftState(draft: draft);
  }

  void loadDraft(PurchaseModel draft) {
    state = PurchaseDraftState(draft: draft);
  }

  void setSupplierReference(String refText) {
    if (state.draft == null) return;
    final updated = state.draft!.copyWith(
      supplierReference: refText,
      clearSupplierReference: refText.trim().isEmpty,
    );
    state = state.copyWith(draft: updated);
  }

  void setSupplier(SupplierModel? supplier) {
    if (state.draft == null) return;
    final updated = state.draft!.copyWith(
      supplierId: supplier?.id,
      supplierName: supplier?.name,
      clearSupplier: supplier == null,
    );
    state = state.copyWith(draft: updated);
    saveDraft();
  }


  void addProductItem(
    ProductModel product, {
    double quantity = 1.0,
    int? customPurchasePricePaise,
  }) {
    if (state.draft == null) return;

    final currentDraft = state.draft!;
    final items = List<PurchaseItemModel>.from(currentDraft.items);

    final price = customPurchasePricePaise ?? product.purchasePricePaise;
    final existingIdx = items.indexWhere((i) => i.productId == product.id);

    if (existingIdx >= 0) {
      final existing = items[existingIdx];
      final newQty = existing.quantity + quantity;
      items[existingIdx] = existing.copyWith(
        quantity: newQty,
        purchasePricePaise: price,
      );
    } else {
      final newItem = PurchaseItemModel.create(
        id: 'pitem_${DateTime.now().millisecondsSinceEpoch}_${_uuid.v4().substring(0, 4)}',
        purchaseId: currentDraft.id,
        productId: product.id,
        productName: product.name,
        unit: product.unit,
        quantity: quantity,
        purchasePricePaise: price,
      );
      items.add(newItem);
    }

    final updated = currentDraft.copyWith(items: items);
    state = state.copyWith(draft: updated, clearErrorMessage: true);
    saveDraft();
  }

  void updateItemQuantity(String itemId, double newQuantity) {
    if (state.draft == null) return;
    if (newQuantity <= 0) {
      removeItem(itemId);
      return;
    }

    final currentDraft = state.draft!;
    final items = currentDraft.items.map((item) {
      if (item.id == itemId) {
        return item.copyWith(quantity: newQuantity);
      }
      return item;
    }).toList();

    final updated = currentDraft.copyWith(items: items);
    state = state.copyWith(draft: updated, clearErrorMessage: true);
    saveDraft();
  }

  void updateItemPrice(String itemId, int newPricePaise) {
    if (state.draft == null || newPricePaise < 0) return;

    final currentDraft = state.draft!;
    final items = currentDraft.items.map((item) {
      if (item.id == itemId) {
        return item.copyWith(purchasePricePaise: newPricePaise);
      }
      return item;
    }).toList();

    final updated = currentDraft.copyWith(items: items);
    state = state.copyWith(draft: updated, clearErrorMessage: true);
    saveDraft();
  }

  void removeItem(String itemId) {
    if (state.draft == null) return;

    final currentDraft = state.draft!;
    final items = currentDraft.items.where((i) => i.id != itemId).toList();
    final updated = currentDraft.copyWith(items: items);
    state = state.copyWith(draft: updated, clearErrorMessage: true);
    saveDraft();
  }

  Future<bool> saveDraft() async {
    if (state.draft == null) return false;

    state = state.copyWith(isSaving: true, clearErrorMessage: true);
    final repo = _ref.read(purchaseRepositoryProvider);
    final res = await repo.saveDraft(state.draft!);

    switch (res) {
      case Success(:final data):
        state = state.copyWith(draft: data, isSaving: false);
        _ref.read(purchasesListNotifierProvider.notifier).loadPurchases();
        return true;
      case ErrorResult(:final failure):
        state = state.copyWith(isSaving: false, errorMessage: failure.message);
        return false;
    }
  }

  Future<bool> confirmStockIn() async {
    if (state.draft == null) return false;

    final authState = _ref.read(authNotifierProvider);
    final shopId = authState.activeShopId;
    final user = authState.user;

    if (shopId == null || user == null) {
      state = state.copyWith(errorMessage: 'No active shop user context.');
      return false;
    }

    state = state.copyWith(isConfirming: true, clearErrorMessage: true);
    final repo = _ref.read(purchaseRepositoryProvider);
    final idempotencyKey =
        'idemp_stockin_${state.draft!.id}_${DateTime.now().millisecondsSinceEpoch}';

    final res = await repo.confirmPurchaseStockIn(
      shopId: shopId,
      userRole: user.role,
      currentUserId: user.id,
      purchase: state.draft!,
      idempotencyKey: idempotencyKey,
    );

    switch (res) {
      case Success(:final data):
        state = state.copyWith(
          draft: data,
          isConfirming: false,
          successMessage: 'Purchase confirmed & stock increased successfully!',
        );
        _ref.read(purchasesListNotifierProvider.notifier).loadPurchases();
        return true;
      case ErrorResult(:final failure):
        state =
            state.copyWith(isConfirming: false, errorMessage: failure.message);
        return false;
    }
  }
}

final purchaseDraftNotifierProvider =
    StateNotifierProvider<PurchaseDraftNotifier, PurchaseDraftState>((ref) {
  return PurchaseDraftNotifier(ref);
});
