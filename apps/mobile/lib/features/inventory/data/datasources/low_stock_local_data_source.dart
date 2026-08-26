import '../../domain/models/low_stock_alert_model.dart';

class LowStockLocalDataSource {
  final Map<String, LowStockAlertModel> _alertStore = {};
  DateTime? _lastSyncedAt;

  DateTime? get lastSyncedAt => _lastSyncedAt;

  Future<void> saveAlerts(List<LowStockAlertModel> alerts) async {
    for (final alert in alerts) {
      _alertStore[alert.id] = alert;
    }
    _lastSyncedAt = DateTime.now();
  }

  Future<void> saveAlert(LowStockAlertModel alert) async {
    _alertStore[alert.id] = alert;
    _lastSyncedAt = DateTime.now();
  }

  Future<void> removeAlertByProductId(String shopId, String productId) async {
    _alertStore.removeWhere(
        (id, alert) => alert.shopId == shopId && alert.productId == productId);
  }

  Future<List<LowStockAlertModel>> getLowStockAlerts(
    String shopId, {
    String? search,
  }) async {
    var alerts = _alertStore.values.where((a) => a.shopId == shopId).toList();

    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      alerts = alerts.where((a) {
        final nameMatch = a.productName.toLowerCase().contains(q);
        final barcodeMatch =
            a.barcode != null && a.barcode!.toLowerCase().contains(q);
        return nameMatch || barcodeMatch;
      }).toList();
    }

    // Urgency Sorting: OUT OF STOCK first -> then LOW STOCK by urgency ratio ASC
    alerts.sort((a, b) {
      if (a.isOutOfStock && !b.isOutOfStock) return -1;
      if (!a.isOutOfStock && b.isOutOfStock) return 1;
      return a.urgencyRatio.compareTo(b.urgencyRatio);
    });

    return alerts;
  }

  Future<void> markAsRead(String shopId, String alertId) async {
    final alert = _alertStore[alertId];
    if (alert != null && alert.shopId == shopId) {
      _alertStore[alertId] = alert.copyWith(isRead: true);
    }
  }

  Future<void> markAllAsRead(String shopId) async {
    for (final entry in _alertStore.entries.toList()) {
      if (entry.value.shopId == shopId) {
        _alertStore[entry.key] = entry.value.copyWith(isRead: true);
      }
    }
  }
}
