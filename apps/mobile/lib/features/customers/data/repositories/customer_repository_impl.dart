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

  static String normalizePhone(String rawPhone) {
    final digitsOnly = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length == 12 && digitsOnly.startsWith('91')) {
      return digitsOnly.substring(2);
    }
    if (digitsOnly.length == 11 && digitsOnly.startsWith('0')) {
      return digitsOnly.substring(1);
    }
    return digitsOnly;
  }

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
    String? email,
    String? address,
    String? notes,
    int creditLimitPaise = 500000,
  }) async {
    try {
      final trimmedName = name.trim();
      final normalizedPhone = normalizePhone(phone);

      if (trimmedName.isEmpty) {
        return const ErrorResult(
            ValidationFailure('Customer name is required'));
      }
      if (normalizedPhone.length < 10) {
        return const ErrorResult(
            ValidationFailure('Please enter a valid 10-digit phone number'));
      }

      // Check for duplicate phone in active shop
      final existing =
          await _localDataSource.findCustomerByPhone(_shopId, normalizedPhone);
      if (existing != null) {
        return ErrorResult(ValidationFailure(
            'Customer "${existing.name}" with phone $normalizedPhone already exists in this shop'));
      }

      final customerId = const Uuid().v4();
      final now = DateTime.now();

      // 1. Save to local SQLite
      await _localDataSource.upsertCustomer(
        CustomersTableCompanion(
          id: Value(customerId),
          shopId: Value(_shopId),
          name: Value(trimmedName),
          phone: Value(normalizedPhone),
          email: Value(email?.trim().isEmpty ?? true ? null : email!.trim()),
          address:
              Value(address?.trim().isEmpty ?? true ? null : address!.trim()),
          notes: Value(notes?.trim().isEmpty ?? true ? null : notes!.trim()),
          creditLimitPaise: Value(BigInt.from(creditLimitPaise)),
          currentDebtPaise: Value(BigInt.zero),
          isArchived: const Value(false),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      // 2. Enlist in sync queue for cloud sync
      final opId = const Uuid().v4();
      final payload = {
        'id': customerId,
        'shop_id': _shopId,
        'name': trimmedName,
        'phone': normalizedPhone,
        'email': email?.trim().isEmpty ?? true ? null : email!.trim(),
        'address': address?.trim().isEmpty ?? true ? null : address!.trim(),
        'notes': notes?.trim().isEmpty ?? true ? null : notes!.trim(),
        'credit_limit_paise': creditLimitPaise,
        'current_debt_paise': 0,
        'is_archived': false,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
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

      // 3. Opportunistic cloud push if online
      try {
        await _remoteDataSource.pushCustomer(payload);
      } catch (_) {
        // Enqueued in sync queue for background retry
      }

      return Success(customerId);
    } catch (e) {
      return ErrorResult(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Result<void, Failure>> updateCustomer({
    required String id,
    required String name,
    required String phone,
    String? email,
    String? address,
    String? notes,
  }) async {
    try {
      final trimmedName = name.trim();
      final normalizedPhone = normalizePhone(phone);

      if (trimmedName.isEmpty) {
        return const ErrorResult(
            ValidationFailure('Customer name is required'));
      }
      if (normalizedPhone.length < 10) {
        return const ErrorResult(
            ValidationFailure('Please enter a valid 10-digit phone number'));
      }

      final existing =
          await _localDataSource.findCustomerByPhone(_shopId, normalizedPhone);
      if (existing != null && existing.id != id) {
        return ErrorResult(ValidationFailure(
            'Another customer (${existing.name}) already uses phone $normalizedPhone'));
      }

      final current = await _localDataSource.getCustomerById(id);
      if (current == null) {
        return const ErrorResult(DatabaseFailure('Customer not found'));
      }

      final now = DateTime.now();

      await _localDataSource.upsertCustomer(
        CustomersTableCompanion(
          id: Value(id),
          shopId: Value(_shopId),
          name: Value(trimmedName),
          phone: Value(normalizedPhone),
          email: Value(email?.trim().isEmpty ?? true ? null : email!.trim()),
          address:
              Value(address?.trim().isEmpty ?? true ? null : address!.trim()),
          notes: Value(notes?.trim().isEmpty ?? true ? null : notes!.trim()),
          creditLimitPaise: Value(current.creditLimitPaise),
          currentDebtPaise: Value(current.currentDebtPaise),
          isArchived: Value(current.isArchived),
          createdAt: Value(current.createdAt),
          updatedAt: Value(now),
        ),
      );

      final opId = const Uuid().v4();
      final payload = {
        'id': id,
        'shop_id': _shopId,
        'name': trimmedName,
        'phone': normalizedPhone,
        'email': email?.trim().isEmpty ?? true ? null : email!.trim(),
        'address': address?.trim().isEmpty ?? true ? null : address!.trim(),
        'notes': notes?.trim().isEmpty ?? true ? null : notes!.trim(),
        'updated_at': now.toIso8601String(),
      };

      await _localDataSource.enqueueSyncOperation(
        SyncQueueTableCompanion(
          operationId: Value(opId),
          shopId: Value(_shopId),
          entityType: const Value('customer'),
          entityId: Value(id),
          operationType: const Value('UPDATE'),
          payload: Value(jsonEncode(payload)),
          createdAt: Value(now),
          status: const Value('PENDING'),
        ),
      );

      try {
        await _remoteDataSource.pushCustomer(payload);
      } catch (_) {}

      return const Success(null);
    } catch (e) {
      return ErrorResult(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Result<void, Failure>> archiveCustomer(String id) async {
    try {
      await _localDataSource.archiveCustomer(id);

      final opId = const Uuid().v4();
      final now = DateTime.now();
      final payload = {
        'id': id,
        'shop_id': _shopId,
        'is_archived': true,
        'updated_at': now.toIso8601String(),
      };

      await _localDataSource.enqueueSyncOperation(
        SyncQueueTableCompanion(
          operationId: Value(opId),
          shopId: Value(_shopId),
          entityType: const Value('customer'),
          entityId: Value(id),
          operationType: const Value('UPDATE'),
          payload: Value(jsonEncode(payload)),
          createdAt: Value(now),
          status: const Value('PENDING'),
        ),
      );

      try {
        await _remoteDataSource.pushCustomer(payload);
      } catch (_) {}

      return const Success(null);
    } catch (e) {
      return ErrorResult(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Result<List<BillData>, Failure>> getCustomerSalesHistory(
      String customerId) async {
    try {
      final bills =
          await _localDataSource.getCustomerSalesHistory(_shopId, customerId);
      return Success(bills);
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
            email: Value(raw['email'] as String?),
            address: Value(raw['address'] as String?),
            notes: Value(raw['notes'] as String?),
            creditLimitPaise: Value(BigInt.from(
                (raw['credit_limit_paise'] as num? ?? 500000).toInt())),
            currentDebtPaise: Value(
                BigInt.from((raw['current_debt_paise'] as num? ?? 0).toInt())),
            isArchived: Value(raw['is_archived'] as bool? ?? false),
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
