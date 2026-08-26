import 'package:drift/drift.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../database/drift/database.dart';
import '../../../products/data/datasources/product_local_data_source.dart';
import '../../../products/domain/models/product_model.dart';
import '../../domain/models/adjustment_reason.dart';
import '../../domain/models/inventory_movement_model.dart';
import '../../domain/models/stock_adjustment_request.dart';
import '../../domain/models/stock_status.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../datasources/inventory_local_data_source.dart';
import '../datasources/inventory_remote_data_source.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryLocalDataSource _localDataSource;
  final InventoryRemoteDataSource _remoteDataSource;
  final ProductLocalDataSource _productLocalDataSource;
  final ConnectivityService? _connectivityService;

  InventoryRepositoryImpl({
    required InventoryLocalDataSource localDataSource,
    required InventoryRemoteDataSource remoteDataSource,
    required ProductLocalDataSource productLocalDataSource,
    ConnectivityService? connectivityService,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        _productLocalDataSource = productLocalDataSource,
        _connectivityService = connectivityService;

  @override
  Future<Result<ProductModel, Failure>> getStockDetails(
      String shopId, String productId) async {
    try {
      final productData =
          await _productLocalDataSource.getProductById(productId);
      if (productData == null) {
        return const ErrorResult(DatabaseFailure('Product not found'));
      }
      return Success(ProductModel.fromDrift(productData));
    } catch (e) {
      return ErrorResult(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Result<InventoryMovementModel, Failure>> adjustStock(
      StockAdjustmentRequest request) async {
    // 1. Client-side Validation
    if (request.productId.trim().isEmpty) {
      return const ErrorResult(ValidationFailure('Valid product is required'));
    }

    if (request.quantity <= 0 &&
        request.adjustmentType != InventoryAdjustmentType.adjustment) {
      return const ErrorResult(
          ValidationFailure('Quantity must be greater than zero'));
    }

    final reasonStr = request.reason.trim();
    if (reasonStr.isEmpty) {
      return const ErrorResult(
          ValidationFailure('Adjustment reason is required'));
    }

    if (request.parsedReason == AdjustmentReason.other) {
      final note = request.note?.trim();
      if (note == null || note.isEmpty) {
        return const ErrorResult(ValidationFailure(
            'Reason "Other" requires a short explanation in notes'));
      }
    }

    // 2. OFFLINE CHECK - Stock adjustments require server connectivity
    if (_connectivityService != null) {
      final isOnline = await _connectivityService.isOnline();
      if (!isOnline) {
        return const ErrorResult(
            NetworkFailure('Internet connection required to adjust stock.'));
      }
    }

    try {
      // 3. Server-Authoritative Transaction via RPC
      final remoteMovement = await _remoteDataSource.adjustStock(request);

      // 4. Update local Drift cache on successful RPC
      try {
        await _localDataSource.recordMovementAndStockUpdate(
          movementId: remoteMovement.id,
          shopId: request.shopId,
          productId: request.productId,
          quantityDelta: remoteMovement.quantityDelta,
          reason: remoteMovement.reason,
          adjustmentReason: remoteMovement.adjustmentReason ?? request.reason,
          performedBy: request.userId,
          referenceId: remoteMovement.referenceId,
          note: request.note,
          idempotencyKey:
              remoteMovement.idempotencyKey ?? request.idempotencyKey,
          previousQuantity: remoteMovement.previousQuantity,
          newBalance: remoteMovement.balanceAfter,
        );
      } catch (localError) {
        AppLogger.w(
            'Failed to update local cache after stock adjustment RPC: $localError',
            tag: 'InventoryRepositoryImpl');
      }

      return Success(remoteMovement);
    } catch (e) {
      AppLogger.e('Stock adjustment error: $e', tag: 'InventoryRepositoryImpl');
      if (e is DatabaseException) {
        return ErrorResult(DatabaseFailure(e.message));
      }
      return ErrorResult(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Result<List<InventoryMovementModel>, Failure>> getInventoryHistory({
    required String shopId,
    String? productId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final localHistory = await _localDataSource.getInventoryHistory(
        shopId: shopId,
        productId: productId,
        limit: limit,
        offset: offset,
      );

      if (localHistory.isNotEmpty) {
        return Success(localHistory);
      }

      final remoteHistory = await _remoteDataSource.getInventoryHistory(
        shopId: shopId,
        productId: productId,
        limit: limit,
        offset: offset,
      );

      return Success(remoteHistory);
    } catch (e) {
      return ErrorResult(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Result<List<ProductModel>, Failure>> getLowStockProducts(
      String shopId) async {
    try {
      final rows = await _localDataSource.getLowStockProducts(shopId);
      final products = rows.map((r) => ProductModel.fromDrift(r)).toList();
      return Success(products);
    } catch (e) {
      return ErrorResult(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Result<List<ProductModel>, Failure>> getFilteredProducts(
    String shopId, {
    String? categoryId,
    String? searchQuery,
    StockStatusFilter? statusFilter,
  }) async {
    try {
      final products = await _productLocalDataSource.getProducts(
        shopId,
        categoryId: categoryId,
        searchQuery: searchQuery,
        statusFilter: statusFilter,
      );
      return Success(products);
    } catch (e) {
      return ErrorResult(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Result<ProductModel, Failure>> updateStockSettings({
    required String productId,
    required double minStockAlert,
    double? maxStockAlert,
  }) async {
    if (minStockAlert < 0) {
      return const ErrorResult(
          ValidationFailure('Minimum stock level cannot be negative'));
    }

    if (maxStockAlert != null && maxStockAlert < 0) {
      return const ErrorResult(
          ValidationFailure('Maximum stock level cannot be negative'));
    }

    if (maxStockAlert != null && maxStockAlert < minStockAlert) {
      return const ErrorResult(ValidationFailure(
          'Maximum stock level must be greater than or equal to minimum stock level'));
    }

    try {
      final current = await _productLocalDataSource.getProductById(productId);
      if (current == null) {
        return const ErrorResult(ValidationFailure('Product not found'));
      }

      final now = DateTime.now();
      final updated = current.copyWith(
        minStockAlert: minStockAlert,
        maxStockAlert: maxStockAlert,
        clearMaxStockAlert: maxStockAlert == null,
        updatedAt: now,
      );

      await _productLocalDataSource.upsertProduct(
        ProductsTableCompanion(
          id: Value(updated.id),
          shopId: Value(updated.shopId),
          categoryId: Value(updated.categoryId),
          name: Value(updated.name),
          brand: Value(updated.brand),
          imageUrl: Value(updated.imageUrl),
          unit: Value(updated.unit),
          mrpPaise: Value(BigInt.from(updated.mrpPaise)),
          sellingPricePaise: Value(BigInt.from(updated.sellingPricePaise)),
          purchasePricePaise: Value(BigInt.from(updated.purchasePricePaise)),
          currentStock: Value(updated.currentStock),
          minStockAlert: Value(updated.minStockAlert),
          maxStockAlert: Value(updated.maxStockAlert),
          description: Value(updated.description),
          taxRatePercentage: Value(updated.taxRatePercentage),
          isActive: Value(updated.isActive),
          createdAt: Value(updated.createdAt),
          updatedAt: Value(now),
        ),
      );

      return Success(updated);
    } catch (e) {
      return ErrorResult(ErrorHandler.handle(e));
    }
  }
}
