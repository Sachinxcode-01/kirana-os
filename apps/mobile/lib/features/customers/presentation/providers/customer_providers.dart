import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/app_providers.dart';
import '../../../../database/drift/database.dart';
import '../../data/datasources/customer_local_data_source.dart';
import '../../data/datasources/customer_remote_data_source.dart';
import '../../data/repositories/customer_repository_impl.dart';
import '../../domain/models/customer_purchase_summary.dart';
import '../../domain/repositories/customer_repository.dart';

final customerLocalDataSourceProvider =
    Provider<CustomerLocalDataSource>((ref) {
  final db = ref.watch(databaseProvider);
  return CustomerLocalDataSource(db);
});

final customerRemoteDataSourceProvider =
    Provider<CustomerRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CustomerRemoteDataSource(apiClient.supabase);
});

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final local = ref.watch(customerLocalDataSourceProvider);
  final remote = ref.watch(customerRemoteDataSourceProvider);
  final shopId = ref.watch(activeShopIdProvider);

  return CustomerRepositoryImpl(
    localDataSource: local,
    remoteDataSource: remote,
    shopId: shopId,
  );
});

final customerSearchQueryProvider = StateProvider<String>((ref) => '');

final customersStreamProvider =
    StreamProvider.autoDispose<List<CustomerData>>((ref) {
  final repository = ref.watch(customerRepositoryProvider);
  final query = ref.watch(customerSearchQueryProvider);
  return repository.watchCustomers(query);
});

final customerDetailProvider = FutureProvider.family
    .autoDispose<CustomerData?, String>((ref, customerId) async {
  final repository = ref.watch(customerRepositoryProvider);
  final result = await repository.getCustomerById(customerId);
  return result.dataOrNull;
});

final customerSalesHistoryProvider = FutureProvider.family
    .autoDispose<List<BillData>, String>((ref, customerId) async {
  final repository = ref.watch(customerRepositoryProvider);
  final result = await repository.getCustomerSalesHistory(customerId);
  return result.dataOrNull ?? [];
});

final customerPurchaseSummaryProvider = FutureProvider.family
    .autoDispose<CustomerPurchaseSummary, String>((ref, customerId) async {
  final repository = ref.watch(customerRepositoryProvider);
  final result = await repository.getCustomerPurchaseSummary(customerId);
  return result.dataOrNull ??
      const CustomerPurchaseSummary(
        totalPurchasesPaise: 0,
        totalBillsCount: 0,
      );
});
