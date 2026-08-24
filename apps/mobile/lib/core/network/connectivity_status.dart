/// Global network and sync connectivity state.
enum ConnectivityStatus {
  online('Online'),
  offline('Offline'),
  syncing('Syncing'),
  syncError('Sync Error');

  final String label;
  const ConnectivityStatus(this.label);

  bool get isOnline => this == ConnectivityStatus.online;
  bool get isOffline => this == ConnectivityStatus.offline;
  bool get isSyncing => this == ConnectivityStatus.syncing;
}
