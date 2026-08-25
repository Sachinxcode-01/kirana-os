import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../models/bill_model.dart';
import '../models/payment_model.dart';

abstract interface class BillingRepository {
  Future<Result<BillModel, Failure>> createDraftBill({
    required String shopId,
    required String cashierId,
    String? billNumber,
  });

  Future<Result<BillModel, Failure>> saveDraftBill(BillModel bill);

  Future<Result<BillModel?, Failure>> getDraftBill(String billId);

  Future<Result<void, Failure>> deleteDraftBill(String billId);

  Future<Result<BillModel, Failure>> completeSaleCheckout({
    required BillModel bill,
    required PaymentModel payment,
    required String idempotencyKey,
  });

  Stream<List<BillModel>> watchShopDrafts(String shopId);
}
