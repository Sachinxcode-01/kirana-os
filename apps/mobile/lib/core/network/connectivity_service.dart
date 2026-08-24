import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'connectivity_status.dart';

/// Monitors active network connectivity changes in real time.
class ConnectivityService {
  final Connectivity _connectivity;
  final StreamController<ConnectivityStatus> _statusController =
      StreamController<ConnectivityStatus>.broadcast();

  ConnectivityStatus _currentStatus = ConnectivityStatus.online;

  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity() {
    _init();
  }

  ConnectivityStatus get currentStatus => _currentStatus;
  Stream<ConnectivityStatus> get statusStream => _statusController.stream;

  Future<bool> isOnline() async {
    final status = await checkConnectivity();
    return status == ConnectivityStatus.online;
  }

  void _init() {
    _connectivity.onConnectivityChanged.listen(_handleConnectivityChange);
    checkConnectivity();
  }

  Future<ConnectivityStatus> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _handleConnectivityChange(results);
      return _currentStatus;
    } catch (_) {
      _currentStatus = ConnectivityStatus.offline;
      _statusController.add(_currentStatus);
      return _currentStatus;
    }
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final isConnected = results.any(
      (r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet,
    );

    _currentStatus =
        isConnected ? ConnectivityStatus.online : ConnectivityStatus.offline;
    _statusController.add(_currentStatus);
  }

  void updateSyncStatus(ConnectivityStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  void dispose() {
    _statusController.close();
  }
}
