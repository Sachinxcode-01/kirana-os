import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/errors/result.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/low_stock_local_data_source.dart';
import '../../data/datasources/low_stock_remote_data_source.dart';
import '../../data/repositories/low_stock_repository_impl.dart';
import '../../domain/models/low_stock_alert_model.dart';
import '../../domain/repositories/low_stock_repository.dart';

final lowStockLocalDataSourceProvider =
    Provider<LowStockLocalDataSource>((ref) {
  return LowStockLocalDataSource();
});

final lowStockRemoteDataSourceProvider =
    Provider<LowStockRemoteDataSource>((ref) {
  return LowStockRemoteDataSource();
});

final lowStockRepositoryProvider = Provider<LowStockRepository>((ref) {
  final local = ref.watch(lowStockLocalDataSourceProvider);
  final remote = ref.watch(lowStockRemoteDataSourceProvider);
  final conn = ref.watch(connectivityServiceProvider);
  return LowStockRepositoryImpl(
    localDataSource: local,
    remoteDataSource: remote,
    connectivityService: conn,
  );
});

class LowStockState {
  final List<LowStockAlertModel> alerts;
  final String search;
  final bool isLoading;
  final int lowStockCount;
  final int outOfStockCount;
  final int unreadCount;
  final bool isOffline;
  final DateTime? lastSyncedAt;
  final String? errorMessage;

  const LowStockState({
    this.alerts = const [],
    this.search = '',
    this.isLoading = false,
    this.lowStockCount = 0,
    this.outOfStockCount = 0,
    this.unreadCount = 0,
    this.isOffline = false,
    this.lastSyncedAt,
    this.errorMessage,
  });

  LowStockState copyWith({
    List<LowStockAlertModel>? alerts,
    String? search,
    bool? isLoading,
    int? lowStockCount,
    int? outOfStockCount,
    int? unreadCount,
    bool? isOffline,
    DateTime? lastSyncedAt,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return LowStockState(
      alerts: alerts ?? this.alerts,
      search: search ?? this.search,
      isLoading: isLoading ?? this.isLoading,
      lowStockCount: lowStockCount ?? this.lowStockCount,
      outOfStockCount: outOfStockCount ?? this.outOfStockCount,
      unreadCount: unreadCount ?? this.unreadCount,
      isOffline: isOffline ?? this.isOffline,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class LowStockNotifier extends StateNotifier<LowStockState> {
  final Ref _ref;
  StreamSubscription<List<LowStockAlertModel>>? _realtimeSubscription;

  LowStockNotifier(this._ref) : super(const LowStockState()) {
    loadAlerts();
    _initRealtimeSubscription();
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }

  void _initRealtimeSubscription() {
    final authState = _ref.read(authNotifierProvider);
    final shopId = authState.activeShopId ?? 'shop_demo';
    final repo = _ref.read(lowStockRepositoryProvider);

    _realtimeSubscription =
        repo.subscribeToLowStockAlerts(shopId).listen((alerts) {
      _processAlerts(alerts);
    });
  }

  Future<void> loadAlerts() async {
    final authState = _ref.read(authNotifierProvider);
    final shopId = authState.activeShopId ?? 'shop_demo';
    final repo = _ref.read(lowStockRepositoryProvider);

    state = state.copyWith(isLoading: true, clearErrorMessage: true);

    final res = await repo.getLowStockAlerts(
      shopId: shopId,
      search: state.search.isEmpty ? null : state.search,
    );

    switch (res) {
      case Success(:final data):
        _processAlerts(data);
      case ErrorResult(:final failure):
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
    }
  }

  void _processAlerts(List<LowStockAlertModel> alertList) {
    final outOfStockCount = alertList.where((a) => a.isOutOfStock).length;
    final lowStockCount = alertList.where((a) => a.isLowStock).length;
    final unreadCount = alertList.where((a) => !a.isRead).length;

    state = state.copyWith(
      alerts: alertList,
      lowStockCount: lowStockCount,
      outOfStockCount: outOfStockCount,
      unreadCount: unreadCount,
      isLoading: false,
    );
  }

  void setSearchQuery(String query) {
    state = state.copyWith(search: query);
    loadAlerts();
  }

  Future<void> markAlertAsRead(String alertId) async {
    final authState = _ref.read(authNotifierProvider);
    final shopId = authState.activeShopId ?? 'shop_demo';
    final repo = _ref.read(lowStockRepositoryProvider);

    await repo.markAlertAsRead(shopId: shopId, alertId: alertId);
    loadAlerts();
  }

  Future<void> markAllAsRead() async {
    final authState = _ref.read(authNotifierProvider);
    final shopId = authState.activeShopId ?? 'shop_demo';
    final repo = _ref.read(lowStockRepositoryProvider);

    await repo.markAllAlertsAsRead(shopId: shopId);
    loadAlerts();
  }
}

final lowStockNotifierProvider =
    StateNotifierProvider<LowStockNotifier, LowStockState>(
  (ref) => LowStockNotifier(ref),
);
