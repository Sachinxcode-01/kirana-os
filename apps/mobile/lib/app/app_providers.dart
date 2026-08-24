import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../core/network/connectivity_service.dart';
import '../core/network/connectivity_status.dart';
import '../core/storage/secure_storage_service.dart';
import '../database/drift/database.dart';
import 'app_config.dart';

/// App configuration provider
final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.dev();
});

/// Local Drift SQLite Database singleton provider
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// Secure storage provider
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

/// Real-time connectivity monitor provider
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Stream provider for global connectivity status
final connectivityStatusStreamProvider = StreamProvider<ConnectivityStatus>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.statusStream;
});

/// Supabase API Client provider
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

/// Current active shop ID provider (persisted across sessions)
final activeShopIdProvider = StateProvider<String?>((ref) => 'shop_demo_1');

/// Authentication state holder provider (true if logged in)
final authStateProvider = StateProvider<bool>((ref) => true);

/// Pending sync count stream provider
final pendingSyncCountProvider = StreamProvider<int>((ref) {
  final db = ref.watch(databaseProvider);
  return db.syncDao.watchPendingCount();
});
