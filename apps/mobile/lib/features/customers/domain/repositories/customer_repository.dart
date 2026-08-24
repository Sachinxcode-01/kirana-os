import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../database/drift/database.dart';

abstract interface class CustomerRepository {
  /// Stream of customers filtered by search query
  Stream<List<CustomerData>> watchCustomers([String query = '']);

  /// Single customer by ID
  Future<Result<CustomerData?, Failure>> getCustomerById(String id);

  /// Create new customer record locally & enqueue for cloud sync
  Future<Result<String, Failure>> createCustomer({
    required String name,
    required String phone,
    String? address,
    int creditLimitPaise = 500000,
  });

  /// Record Khata debt settlement / payment received
  Future<Result<void, Failure>> recordCreditPayment({
    required String customerId,
    required int amountPaise,
    String? notes,
  });
}
