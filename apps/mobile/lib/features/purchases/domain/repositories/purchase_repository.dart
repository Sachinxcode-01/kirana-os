import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../models/purchase_history_filter.dart';
import '../models/purchase_model.dart';

abstract interface class PurchaseRepository {
  Future<Result<PurchaseModel, Failure>> createDraft({
    required String shopId,
    required String cashierId,
    String? supplierReference,
  });

  Future<Result<PurchaseModel, Failure>> saveDraft(PurchaseModel purchase);

  Future<Result<PurchaseModel?, Failure>> getPurchaseById(String id);

  Future<Result<List<PurchaseModel>, Failure>> getShopPurchases(String shopId);

  Future<Result<PurchaseHistoryResult, Failure>> getPurchaseHistory({
    required String shopId,
    PurchaseHistoryFilter filter = const PurchaseHistoryFilter(),
  });

  Future<Result<void, Failure>> deleteDraft(String id);

  Future<Result<PurchaseModel, Failure>> confirmPurchaseStockIn({
    required String shopId,
    required String userRole,
    required String currentUserId,
    required PurchaseModel purchase,
    required String idempotencyKey,
  });
}
