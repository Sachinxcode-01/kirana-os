import '../../domain/models/bill_model.dart';

class BillingLocalDataSource {
  final Map<String, BillModel> _draftStore = {};

  Future<BillModel?> getDraftBill(String billId) async {
    return _draftStore[billId];
  }

  Future<List<BillModel>> getShopDrafts(String shopId) async {
    return _draftStore.values
        .where((b) => b.shopId == shopId && b.isDraft)
        .toList();
  }

  Future<void> saveDraftBill(BillModel bill) async {
    _draftStore[bill.id] = bill;
  }

  Future<void> deleteDraftBill(String billId) async {
    _draftStore.remove(billId);
  }
}
