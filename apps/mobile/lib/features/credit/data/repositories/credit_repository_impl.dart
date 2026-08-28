import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../database/drift/database.dart';
import '../../../customers/data/datasources/customer_local_data_source.dart';
import '../../../customers/data/datasources/customer_remote_data_source.dart';
import '../../domain/repositories/credit_repository.dart';

class CreditRepositoryImpl implements CreditRepository {
  final CustomerLocalDataSource _localDataSource;
  final CustomerRemoteDataSource _remoteDataSource;
  final String _shopId;

  CreditRepositoryImpl({
    required CustomerLocalDataSource localDataSource,
    required CustomerRemoteDataSource remoteDataSource,
    required String shopId,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        _shopId = shopId;

  @override
  Stream<List<CreditTransactionData>> watchCreditTransactions(
      String customerId) {
    return _localDataSource.watchCustomers(_shopId).asyncExpand((_) {
      // Return stream from customersDao
      return _localDataSource.watchCreditTransactions(_shopId, customerId);
    });
  }

  @override
  Stream<List<CustomerData>> watchIndebtedCustomers([String query = '']) {
    return _localDataSource.watchIndebtedCustomers(_shopId, query);
  }

  @override
  Future<Result<void, Failure>> recordCreditPayment({
    required String customerId,
    required int amountPaise,
    String? paymentMethod,
    String? notes,
  }) async {
    try {
      if (amountPaise <= 0) {
        return const ErrorResult(ValidationFailure(
            'Please enter a valid payment amount greater than zero'));
      }

      final customer = await _localDataSource.getCustomerById(customerId);
      if (customer == null) {
        return const ErrorResult(DatabaseFailure('Customer not found'));
      }

      final currentDebt = customer.currentDebtPaise.toInt();
      if (amountPaise > currentDebt) {
        return ErrorResult(ValidationFailure(
            'Payment amount cannot exceed outstanding balance of ₹${(currentDebt / 100.0).toStringAsFixed(2)}'));
      }

      final methodLabel = paymentMethod != null && paymentMethod.isNotEmpty
          ? 'Via $paymentMethod'
          : null;
      final fullNotes = [methodLabel, notes?.trim()]
          .where((s) => s != null && s.isNotEmpty)
          .join(' • ');

      // 1. Invoke atomic cloud RPC (Server-Side Atomic Execution & Row Lock)
      Map<String, dynamic>? rpcResult;
      try {
        rpcResult = await _remoteDataSource.recordCreditTransactionAtomic(
          shopId: _shopId,
          customerId: customerId,
          amountPaise: amountPaise,
          type: 'payment_received',
          notes: fullNotes.isEmpty ? null : fullNotes,
        );
      } catch (e) {
        return ErrorResult(NetworkFailure(
            'Internet connection required to record payment. Cloud error: ${e.toString()}'));
      }

      final txnId =
          (rpcResult['transaction_id'] as String?) ?? const Uuid().v4();
      final now = DateTime.now();

      // 2. Sync local Drift SQLite database on cloud success
      final txnRecord = CreditTransactionsTableCompanion(
        id: Value(txnId),
        shopId: Value(_shopId),
        customerId: Value(customerId),
        amountPaise: Value(BigInt.from(amountPaise)),
        type: const Value('payment_received'),
        notes: Value(fullNotes.isEmpty ? null : fullNotes),
        recordedBy: Value(_shopId),
        createdAt: Value(now),
      );

      final syncOp = SyncQueueTableCompanion(
        operationId: Value(const Uuid().v4()),
        shopId: Value(_shopId),
        entityType: const Value('credit_transaction'),
        entityId: Value(txnId),
        operationType: const Value('CREATE'),
        payload: Value(jsonEncode({
          'id': txnId,
          'shop_id': _shopId,
          'customer_id': customerId,
          'amount_paise': amountPaise,
          'type': 'payment_received',
          'notes': fullNotes.isEmpty ? null : fullNotes,
          'recorded_by': _shopId,
          'created_at': now.toIso8601String(),
        })),
        createdAt: Value(now),
        status: const Value('SYNCED'),
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

  @override
  Future<Result<void, Failure>> recordCreditSale({
    required String customerId,
    required int amountPaise,
    String? billId,
    String? notes,
  }) async {
    try {
      if (amountPaise <= 0) {
        return const ErrorResult(
            ValidationFailure('Credit amount must be greater than zero'));
      }

      final customer = await _localDataSource.getCustomerById(customerId);
      if (customer == null || customer.shopId != _shopId) {
        return const ErrorResult(DatabaseFailure('Customer not found in shop'));
      }

      final now = DateTime.now();
      final txnId = const Uuid().v4();
      final opId = const Uuid().v4();

      final txnRecord = CreditTransactionsTableCompanion(
        id: Value(txnId),
        shopId: Value(_shopId),
        customerId: Value(customerId),
        billId: Value(billId),
        amountPaise: Value(BigInt.from(amountPaise)),
        type: const Value('credit_given'),
        notes: Value(notes?.trim().isEmpty ?? true ? null : notes!.trim()),
        recordedBy: Value(_shopId),
        createdAt: Value(now),
      );

      final payload = {
        'id': txnId,
        'shop_id': _shopId,
        'customer_id': customerId,
        'bill_id': billId,
        'amount_paise': amountPaise,
        'type': 'credit_given',
        'notes': notes?.trim().isEmpty ?? true ? null : notes!.trim(),
        'recorded_by': _shopId,
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

      await _localDataSource.recordCreditSale(
        customerId: customerId,
        amountPaise: amountPaise,
        transactionRecord: txnRecord,
        syncOp: syncOp,
      );

      try {
        await _remoteDataSource.pushCreditTransaction(payload);
      } catch (_) {}

      return const Success(null);
    } catch (e) {
      return ErrorResult(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Result<({int totalDebtPaise, int indebtedCount}), Failure>>
      getShopCreditSummary() async {
    try {
      final summary = await _localDataSource.getShopCreditSummary(_shopId);
      return Success(summary);
    } catch (e) {
      return ErrorResult(ErrorHandler.handleException(e));
    }
  }
}
