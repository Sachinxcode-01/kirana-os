import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../database/drift/database.dart';

import '../models/customer_purchase_summary.dart';

abstract interface class CustomerRepository {
  /// Stream of customers for shop filtered by search query (Name or Phone)
  Stream<List<CustomerData>> watchCustomers([String query = '']);

  /// Single customer by ID
  Future<Result<CustomerData?, Failure>> getCustomerById(String id);

  /// Create new customer record locally & enqueue for cloud sync
  Future<Result<String, Failure>> createCustomer({
    required String name,
    required String phone,
    String? email,
    String? address,
    String? notes,
    int creditLimitPaise = 500000,
  });

  /// Update existing customer details (without altering completed bill snapshots)
  Future<Result<void, Failure>> updateCustomer({
    required String id,
    required String name,
    required String phone,
    String? email,
    String? address,
    String? notes,
  });

  /// Archive customer (soft delete)
  Future<Result<void, Failure>> archiveCustomer(String id);

  /// Get completed sales history for a specific customer
  Future<Result<List<BillData>, Failure>> getCustomerSalesHistory(
      String customerId);

  /// Get aggregated customer purchase summary (Total Purchases, Bill Count, Last Purchase)
  Future<Result<CustomerPurchaseSummary, Failure>> getCustomerPurchaseSummary(
      String customerId);

  /// Record Khata debt settlement / payment received
  Future<Result<void, Failure>> recordCreditPayment({
    required String customerId,
    required int amountPaise,
    String? notes,
  });
}
