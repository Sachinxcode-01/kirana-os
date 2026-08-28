import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../database/drift/database.dart';

abstract interface class CreditRepository {
  /// Stream of credit ledger transactions for a specific customer
  Stream<List<CreditTransactionData>> watchCreditTransactions(
      String customerId);

  /// Stream of indebted customers sorted by highest debt
  Stream<List<CustomerData>> watchIndebtedCustomers([String query = '']);

  /// Record Khata payment received from a customer (reduces debt)
  Future<Result<void, Failure>> recordCreditPayment({
    required String customerId,
    required int amountPaise,
    String? paymentMethod,
    String? notes,
  });

  /// Record Udhaar credit sale given to a customer (increases debt)
  Future<Result<void, Failure>> recordCreditSale({
    required String customerId,
    required int amountPaise,
    String? billId,
    String? notes,
  });

  /// Get shop-wide credit summary metrics (total debt paise, count of indebted customers)
  Future<Result<({int totalDebtPaise, int indebtedCount}), Failure>>
      getShopCreditSummary();
}
