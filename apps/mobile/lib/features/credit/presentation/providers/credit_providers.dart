import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/app_providers.dart';
import '../../../../database/drift/database.dart';
import '../../../customers/presentation/providers/customer_providers.dart';
import '../../data/repositories/credit_repository_impl.dart';
import '../../domain/repositories/credit_repository.dart';

final creditRepositoryProvider = Provider<CreditRepository>((ref) {
  final local = ref.watch(customerLocalDataSourceProvider);
  final remote = ref.watch(customerRemoteDataSourceProvider);
  final shopId = ref.watch(activeShopIdProvider);

  return CreditRepositoryImpl(
    localDataSource: local,
    remoteDataSource: remote,
    shopId: shopId,
  );
});

final customerLedgerStreamProvider = StreamProvider.family
    .autoDispose<List<CreditTransactionData>, String>((ref, customerId) {
  final repository = ref.watch(creditRepositoryProvider);
  return repository.watchCreditTransactions(customerId);
});

final indebtedCustomersQueryProvider = StateProvider<String>((ref) => '');

final indebtedCustomersStreamProvider =
    StreamProvider.autoDispose<List<CustomerData>>((ref) {
  final repository = ref.watch(creditRepositoryProvider);
  final query = ref.watch(indebtedCustomersQueryProvider);
  return repository.watchIndebtedCustomers(query);
});

final shopCreditSummaryProvider =
    FutureProvider.autoDispose<({int totalDebtPaise, int indebtedCount})>(
        (ref) async {
  final repository = ref.watch(creditRepositoryProvider);
  final result = await repository.getShopCreditSummary();
  return result.dataOrNull ?? (totalDebtPaise: 0, indebtedCount: 0);
});
