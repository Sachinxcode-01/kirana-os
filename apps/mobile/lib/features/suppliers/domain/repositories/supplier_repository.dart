import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../models/supplier_model.dart';

abstract interface class SupplierRepository {
  Future<Result<SupplierModel, Failure>> createSupplier({
    required String shopId,
    required String name,
    required String phone,
    String? contactPerson,
    String? email,
    String? address,
    String? gstin,
    String? notes,
  });

  Future<Result<SupplierModel, Failure>> updateSupplier(SupplierModel supplier);

  Future<Result<SupplierModel, Failure>> archiveSupplier({
    required String shopId,
    required String supplierId,
  });

  Future<Result<List<SupplierModel>, Failure>> getSuppliers({
    required String shopId,
    bool includeArchived = false,
    String? searchQuery,
    int limit = 50,
    int offset = 0,
  });

  Future<Result<SupplierModel?, Failure>> getSupplierById(String id);
}
