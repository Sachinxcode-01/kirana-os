import '../../../../core/errors/error_handler.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../products/data/datasources/product_local_data_source.dart';
import '../../../products/domain/models/product_model.dart';
import '../../domain/models/inventory_movement_model.dart';
import '../../domain/models/stock_adjustment_request.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../datasources/inventory_local_data_source.dart';
import '../datasources/inventory_remote_data_source.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryLocalDataSource _localDataSource;
  final InventoryRemoteDataSource _remoteDataSource;
  final ProductLocalDataSource _productLocalDataSource;

  InventoryRepositoryImpl({
    required InventoryLocalDataSource localDataSource,
    required InventoryRemoteDataSource remoteDataSource,
    required ProductLocalDataSource productLocalDataSource,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        _productLocalDataSource = productLocalDataSource;

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
    // 1. Validation
    if (request.quantity <= 0 &&
        request.adjustmentType != InventoryAdjustmentType.adjustment) {
      return const ErrorResult(
          ValidationFailure('Quantity must be greater than zero'));
    }

    if (request.productId.trim().isEmpty) {
      return const ErrorResult(ValidationFailure('Valid product is required'));
    }

    try {
      // Fetch current product state
      final productData =
          await _productLocalDataSource.getProductById(request.productId);
      if (productData == null) {
        return const ErrorResult(DatabaseFailure('Product not found'));
      }

      final currentStock = productData.currentStock;
      final delta = request.calculateDelta(currentStock);

      if (request.adjustmentType == InventoryAdjustmentType.stockOut &&
          currentStock + delta < 0) {
        AppLogger.w('Stock adjustment warning: insufficient stock available',
            tag: 'InventoryRepositoryImpl');
      }

      // 2. Perform local atomic update first (Offline-First)
      final localMovement = await _localDataSource.recordMovementAndStockUpdate(
        shopId: request.shopId,
        productId: request.productId,
        quantityDelta: delta,
        reason: request.adjustmentType.dbReason,
        performedBy: request.userId,
        note: request.note,
      );

      // 3. Attempt server-authoritative remote sync
      try {
        await _remoteDataSource.adjustStock(request);
      } catch (remoteError) {
        AppLogger.w(
            'Remote stock adjustment notice (queued locally): $remoteError',
            tag: 'InventoryRepositoryImpl');
      }

      return Success(localMovement);
    } catch (e) {
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
}
