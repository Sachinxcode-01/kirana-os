import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../products/domain/models/product_model.dart';
import '../models/stock_overview_model.dart';

abstract interface class StockRepository {
  Future<Result<StockOverviewResult, Failure>> getStockOverview({
    required String shopId,
    StockOverviewFilter filter = const StockOverviewFilter(),
  });

  Future<Result<ProductModel?, Failure>> getProductStockDetails({
    required String shopId,
    required String productId,
  });

  Stream<ProductModel> subscribeToStockUpdates(String shopId);
}
