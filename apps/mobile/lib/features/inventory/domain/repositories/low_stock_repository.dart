import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../models/low_stock_alert_model.dart';

abstract interface class LowStockRepository {
  Future<Result<List<LowStockAlertModel>, Failure>> getLowStockAlerts({
    required String shopId,
    String? search,
  });

  Future<Result<void, Failure>> markAlertAsRead({
    required String shopId,
    required String alertId,
  });

  Future<Result<void, Failure>> markAllAlertsAsRead({
    required String shopId,
  });

  Stream<List<LowStockAlertModel>> subscribeToLowStockAlerts(String shopId);
}
