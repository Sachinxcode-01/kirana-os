import '../../domain/models/supplier_model.dart';

class SupplierLocalDataSource {
  final Map<String, SupplierModel> _supplierStore = {};

  Future<SupplierModel?> getSupplierById(String id) async {
    return _supplierStore[id];
  }

  Future<List<SupplierModel>> getSuppliers(
    String shopId, {
    bool includeArchived = false,
    String? searchQuery,
  }) async {
    var list = _supplierStore.values
        .where((s) => s.shopId == shopId)
        .where((s) => includeArchived || !s.isArchived)
        .toList();

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      list = list.where((s) {
        final nameMatch = s.name.toLowerCase().contains(q);
        final phoneMatch = s.phone.contains(q);
        final gstinMatch =
            s.gstin != null && s.gstin!.toLowerCase().contains(q);
        final contactMatch = s.contactPerson != null &&
            s.contactPerson!.toLowerCase().contains(q);
        return nameMatch || phoneMatch || gstinMatch || contactMatch;
      }).toList();
    }

    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  Future<void> saveSupplier(SupplierModel supplier) async {
    _supplierStore[supplier.id] = supplier;
  }

  Future<void> saveSuppliers(List<SupplierModel> suppliers) async {
    for (final s in suppliers) {
      _supplierStore[s.id] = s;
    }
  }

  Future<void> deleteSupplier(String id) async {
    _supplierStore.remove(id);
  }
}
