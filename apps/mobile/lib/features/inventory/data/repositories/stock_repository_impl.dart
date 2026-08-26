import 'dart:async';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/network/connectivity_status.dart';
import '../../../products/domain/models/product_model.dart';
import '../../domain/models/stock_overview_model.dart';
import '../../domain/repositories/stock_repository.dart';
import '../datasources/stock_local_data_source.dart';
import '../datasources/stock_remote_data_source.dart';

class StockRepositoryImpl implements StockRepository {
  final StockLocalDataSource _localDataSource;
  final StockRemoteDataSource _remoteDataSource;
  final ConnectivityService _connectivityService;

  StockRepositoryImpl({
    required StockLocalDataSource localDataSource,
    required StockRemoteDataSource remoteDataSource,
    required ConnectivityService connectivityService,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        _connectivityService = connectivityService;

  @override
  Future<Result<StockOverviewResult, Failure>> getStockOverview({
    required String shopId,
    StockOverviewFilter filter = const StockOverviewFilter(),
  }) async {
    try {
      if (shopId.trim().isEmpty) {
        return const ErrorResult(ValidationFailure('Shop ID is required.'));
      }

      if (_connectivityService.currentStatus != ConnectivityStatus.offline) {
        try {
          final remoteResult = await _remoteDataSource.fetchStockOverview(
            shopId,
            filter: filter,
          );
          await _localDataSource.saveProducts(remoteResult.products);
          return Success(remoteResult);
        } catch (_) {}
      }

      // Offline or remote fallback to local cache
      final localResult = await _localDataSource.getStockOverview(
        shopId,
        filter: filter,
      );
      return Success(localResult);
    } catch (e) {
      return ErrorResult(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Result<ProductModel?, Failure>> getProductStockDetails({
    required String shopId,
    required String productId,
  }) async {
    try {
      if (shopId.trim().isEmpty) {
        return const ErrorResult(ValidationFailure('Shop ID is required.'));
      }
      final product = await _localDataSource.getProductById(productId);
      return Success(product);
    } catch (e) {
      return ErrorResult(ErrorHandler.handle(e));
    }
  }

  @override
  Stream<ProductModel> subscribeToStockUpdates(String shopId) {
    final stream = _remoteDataSource.subscribeToStockUpdates(shopId);
    return stream.map((product) {
      _localDataSource.saveProduct(product);
      return product;
    });
  }
}
