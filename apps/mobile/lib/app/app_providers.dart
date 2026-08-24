import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../core/network/connectivity_service.dart';
import '../core/network/connectivity_status.dart';
import '../core/storage/product_image_service.dart';
import '../core/storage/secure_storage_service.dart';
import '../core/sync/sync_engine.dart';
import '../database/drift/database.dart';
import '../features/customers/data/datasources/customer_local_data_source.dart';
import '../features/customers/data/datasources/customer_remote_data_source.dart';
import '../features/customers/data/repositories/customer_repository_impl.dart';
import '../features/customers/domain/repositories/customer_repository.dart';
import '../features/products/data/datasources/product_local_data_source.dart';
import '../features/products/data/datasources/product_remote_data_source.dart';
import '../features/products/data/repositories/product_repository_impl.dart';
import '../features/products/domain/repositories/product_repository.dart';
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

/// Product Image Service provider
final productImageServiceProvider = Provider<ProductImageService>((ref) {
  return ProductImageService();
});

/// Real-time connectivity monitor provider
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Stream provider for global connectivity status
final connectivityStatusStreamProvider =
    StreamProvider<ConnectivityStatus>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.statusStream;
});

/// Supabase API Client provider
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

/// Current active shop ID provider (persisted across sessions)
final activeShopIdProvider = StateProvider<String>((ref) => 'shop_demo_1');

/// Product repository provider
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final shopId = ref.watch(activeShopIdProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  return ProductRepositoryImpl(
    localDataSource: ProductLocalDataSource(db),
    remoteDataSource: ProductRemoteDataSource(),
    connectivityService: connectivity,
    shopId: shopId,
  );
});

/// Customer repository provider
final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final shopId = ref.watch(activeShopIdProvider);
  return CustomerRepositoryImpl(
    localDataSource: CustomerLocalDataSource(db),
    remoteDataSource: CustomerRemoteDataSource(),
    shopId: shopId,
  );
});

/// Sync Engine provider
final syncEngineProvider = Provider<SyncEngine>((ref) {
  final db = ref.watch(databaseProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  final engine = SyncEngine(
    db: db,
    connectivityService: connectivity,
  );
  engine.start();
  ref.onDispose(() => engine.dispose());
  return engine;
});

/// Pending sync count stream provider
final pendingSyncCountProvider = StreamProvider<int>((ref) {
  final db = ref.watch(databaseProvider);
  return db.syncDao.watchPendingCount();
});
