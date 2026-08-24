import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../database/drift/database.dart';
import '../../domain/repositories/customer_repository.dart';
import '../datasources/customer_local_data_source.dart';
import '../datasources/customer_remote_data_source.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerLocalDataSource _localDataSource;
  final CustomerRemoteDataSource _remoteDataSource;
  final String _shopId;

  CustomerRepositoryImpl({
    required CustomerLocalDataSource localDataSource,
    required CustomerRemoteDataSource remoteDataSource,
    required String shopId,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        _shopId = shopId;

  @override
  Stream<List<CustomerData>> watchCustomers([String query = '']) {
    return _localDataSource.watchCustomers(_shopId, query);
  }

  @override
  Future<Result<CustomerData?, Failure>> getCustomerById(String id) async {
    try {
      final customer = await _localDataSource.getCustomerById(id);
      return Success(customer);
    } catch (e) {
      return ErrorResult(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Result<String, Failure>> createCustomer({
    required String name,
    required String phone,
    String? address,
    int creditLimitPaise = 500000,
  }) async {
    try {
      final customerId = const Uuid().v4();
      final now = DateTime.now();

      // 1. Save to local SQLite
      await _localDataSource.upsertCustomer(
        CustomersTableCompanion(
          id: Value(customerId),
          shopId: Value(_shopId),
          name: Value(name),
          phone: Value(phone),
          address: Value(address),
          creditLimitPaise: Value(BigInt.from(creditLimitPaise)),
          currentDebtPaise: Value(BigInt.zero),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      // 2. Enlist sync operation
      final opId = const Uuid().v4();
      final payload = {
        'id': customerId,
        'shop_id': _shopId,
        'name': name,
        'phone': phone,
        'address': address,
        'credit_limit_paise': creditLimitPaise,
        'current_debt_paise': 0,
        'created_at': now.toIso8601String(),
      };

      await _localDataSource.enqueueSyncOperation(
        SyncQueueTableCompanion(
          operationId: Value(opId),
          shopId: Value(_shopId),
          entityType: const Value('customer'),
          entityId: Value(customerId),
          operationType: const Value('CREATE'),
          payload: Value(jsonEncode(payload)),
          createdAt: Value(now),
          status: const Value('PENDING'),
        ),
      );

      return Success(customerId);
    } catch (e) {
      return ErrorResult(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Result<void, Failure>> recordCreditPayment({
    required String customerId,
    required int amountPaise,
    String? notes,
  }) async {
    try {
      final now = DateTime.now();
      final txnId = const Uuid().v4();
      final opId = const Uuid().v4();

      final txnRecord = CreditTransactionsTableCompanion(
        id: Value(txnId),
        shopId: Value(_shopId),
        customerId: Value(customerId),
        amountPaise: Value(BigInt.from(amountPaise)),
        type: const Value('payment_received'),
        notes: Value(notes),
        recordedBy: const Value('local_cashier'),
        createdAt: Value(now),
      );

      final payload = {
        'transaction_id': txnId,
        'customer_id': customerId,
        'shop_id': _shopId,
        'amount_paise': amountPaise,
        'type': 'payment_received',
        'notes': notes,
        'created_at': now.toIso8601String(),
      };

      final syncOp = SyncQueueTableCompanion(
        operationId: Value(opId),
        shopId: Value(_shopId),
        entityType: const Value('credit_transaction'),
        entityId: Value(txnId),
        operationType: const Value('CREATE'),
        payload: Value(jsonEncode(payload)),
        createdAt: Value(now),
        status: const Value('PENDING'),
      );

      await _localDataSource.recordCreditPayment(
        customerId: customerId,
        amountPaise: amountPaise,
        transactionRecord: txnRecord,
        syncOp: syncOp,
      );

      return const Success(null);
    } catch (e) {
      return ErrorResult(ErrorHandler.handleException(e));
    }
  }

  Future<Result<int, Failure>> syncRemoteCustomers() async {
    try {
      final remoteCustomers = await _remoteDataSource.fetchCustomers(_shopId);
      int count = 0;
      for (final raw in remoteCustomers) {
        await _localDataSource.upsertCustomer(
          CustomersTableCompanion(
            id: Value(raw['id'] as String),
            shopId: Value(_shopId),
            name: Value(raw['name'] as String),
            phone: Value(raw['phone'] as String),
            address: Value(raw['address'] as String?),
            creditLimitPaise:
                Value(BigInt.from((raw['credit_limit_paise'] as num).toInt())),
            currentDebtPaise:
                Value(BigInt.from((raw['current_debt_paise'] as num).toInt())),
            createdAt: Value(DateTime.parse(raw['created_at'] as String)),
            updatedAt: Value(DateTime.parse(raw['updated_at'] as String)),
          ),
        );
        count++;
      }
      return Success(count);
    } catch (e) {
      return ErrorResult(ErrorHandler.handleException(e));
    }
  }
}
