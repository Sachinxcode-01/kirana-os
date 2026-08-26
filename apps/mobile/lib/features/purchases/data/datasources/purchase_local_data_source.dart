import '../../domain/models/purchase_model.dart';

class PurchaseLocalDataSource {
  final Map<String, PurchaseModel> _purchaseStore = {};

  Future<PurchaseModel?> getPurchaseById(String id) async {
    return _purchaseStore[id];
  }

  Future<List<PurchaseModel>> getShopPurchases(String shopId) async {
    final list =
        _purchaseStore.values.where((p) => p.shopId == shopId).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> saveDraft(PurchaseModel purchase) async {
    _purchaseStore[purchase.id] = purchase;
  }

  Future<void> deleteDraft(String id) async {
    _purchaseStore.remove(id);
  }
}
