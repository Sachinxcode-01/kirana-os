import 'package:uuid/uuid.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/network/connectivity_status.dart';
import '../../domain/models/bill_model.dart';
import '../../domain/repositories/billing_repository.dart';
import '../datasources/billing_local_data_source.dart';
import '../datasources/billing_remote_data_source.dart';

class BillingRepositoryImpl implements BillingRepository {
  final BillingLocalDataSource _localDataSource;
  final BillingRemoteDataSource _remoteDataSource;
  final ConnectivityService _connectivityService;
  final _uuid = const Uuid();

  BillingRepositoryImpl({
    required BillingLocalDataSource localDataSource,
    required BillingRemoteDataSource remoteDataSource,
    required ConnectivityService connectivityService,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        _connectivityService = connectivityService;

  @override
  Future<Result<BillModel, Failure>> createDraftBill({
    required String shopId,
    required String cashierId,
    String? billNumber,
  }) async {
    try {
      final now = DateTime.now();
      final billId =
          'draft_${now.millisecondsSinceEpoch}_${_uuid.v4().substring(0, 8)}';
      final generatedBillNumber = billNumber ??
          'DRAFT-${now.millisecondsSinceEpoch.toString().substring(5)}';

      final draft = BillModel(
        id: billId,
        shopId: shopId,
        cashierId: cashierId,
        billNumber: generatedBillNumber,
        status: 'draft',
        items: const [],
        subtotalPaise: 0,
        taxTotalPaise: 0,
        discountPaise: 0,
        totalPaise: 0,
        paymentStatus: 'unpaid',
        createdAt: now,
        updatedAt: now,
      );

      await _localDataSource.saveDraftBill(draft);
      return Success(draft);
    } catch (e) {
      return ErrorResult(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Result<BillModel, Failure>> saveDraftBill(BillModel bill) async {
    try {
      // 1. Always save locally to Drift/Cache
      await _localDataSource.saveDraftBill(bill);

      // 2. Sync to Supabase if online
      if (_connectivityService.currentStatus != ConnectivityStatus.offline) {
        try {
          await _remoteDataSource.saveDraftBill(bill);
        } catch (_) {
          // If background remote sync fails, local draft remains safe
        }
      }

      return Success(bill);
    } catch (e) {
      return ErrorResult(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Result<BillModel?, Failure>> getDraftBill(String billId) async {
    try {
      final local = await _localDataSource.getDraftBill(billId);
      if (local != null) {
        return Success(local);
      }

      if (_connectivityService.currentStatus != ConnectivityStatus.offline) {
        final remote = await _remoteDataSource.fetchDraftBill(billId);
        if (remote != null) {
          await _localDataSource.saveDraftBill(remote);
        }
        return Success(remote);
      }

      return const Success(null);
    } catch (e) {
      return ErrorResult(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Result<void, Failure>> deleteDraftBill(String billId) async {
    try {
      await _localDataSource.deleteDraftBill(billId);
      return const Success(null);
    } catch (e) {
      return ErrorResult(ErrorHandler.handle(e));
    }
  }

  @override
  Stream<List<BillModel>> watchShopDrafts(String shopId) async* {
    final drafts = await _localDataSource.getShopDrafts(shopId);
    yield drafts;
  }
}
