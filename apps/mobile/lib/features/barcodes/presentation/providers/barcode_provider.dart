import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kirana_mobile/app/app_providers.dart';
import 'package:kirana_mobile/features/products/domain/models/product_model.dart';
import 'package:kirana_mobile/features/products/presentation/providers/product_provider.dart';
import '../../domain/models/barcode_model.dart';
import '../../domain/repositories/barcode_repository.dart';
import '../../data/datasources/barcode_local_data_source.dart';
import '../../data/datasources/barcode_remote_data_source.dart';
import '../../data/repositories/barcode_repository_impl.dart';

final barcodeLocalDataSourceProvider = Provider<BarcodeLocalDataSource>((ref) {
  final db = ref.watch(databaseProvider);
  return BarcodeLocalDataSource(db);
});

final barcodeRemoteDataSourceProvider =
    Provider<BarcodeRemoteDataSource>((ref) {
  return BarcodeRemoteDataSource();
});

final barcodeRepositoryProvider = Provider<BarcodeRepository>((ref) {
  final local = ref.watch(barcodeLocalDataSourceProvider);
  final remote = ref.watch(barcodeRemoteDataSourceProvider);
  final productLocal = ref.watch(productLocalDataSourceProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  final shopId = ref.watch(activeShopIdProvider);

  return BarcodeRepositoryImpl(
    localDataSource: local,
    remoteDataSource: remote,
    productLocalDataSource: productLocal,
    connectivityService: connectivity,
    shopId: shopId,
  );
});

final productBarcodesStreamProvider = StreamProvider.family
    .autoDispose<List<BarcodeModel>, String>((ref, productId) {
  final repository = ref.watch(barcodeRepositoryProvider);
  return repository.watchBarcodesForProduct(productId);
});

class BarcodeActionState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final ProductModel? searchedProduct;

  const BarcodeActionState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.searchedProduct,
  });
}

class BarcodeNotifier extends StateNotifier<BarcodeActionState> {
  final BarcodeRepository _repository;

  BarcodeNotifier(this._repository) : super(const BarcodeActionState());

  Future<bool> addBarcode({
    required String productId,
    required String barcode,
    String? barcodeType,
    bool isPrimary = false,
  }) async {
    if (state.isLoading) return false;
    state = const BarcodeActionState(isLoading: true);

    final result = await _repository.addBarcode(
      productId: productId,
      barcode: barcode,
      barcodeType: barcodeType,
      isPrimary: isPrimary,
    );

    return result.fold(
      (model) {
        state = BarcodeActionState(
          isLoading: false,
          successMessage: 'Barcode "${model.barcode}" added successfully.',
        );
        return true;
      },
      (failure) {
        state = BarcodeActionState(
          isLoading: false,
          errorMessage: failure.message,
        );
        return false;
      },
    );
  }

  Future<bool> updateBarcode({
    required String id,
    required String newBarcode,
    String? barcodeType,
    bool? isPrimary,
  }) async {
    if (state.isLoading) return false;
    state = const BarcodeActionState(isLoading: true);

    final result = await _repository.updateBarcode(
      id: id,
      newBarcode: newBarcode,
      barcodeType: barcodeType,
      isPrimary: isPrimary,
    );

    return result.fold(
      (model) {
        state = BarcodeActionState(
          isLoading: false,
          successMessage: 'Barcode "${model.barcode}" updated successfully.',
        );
        return true;
      },
      (failure) {
        state = BarcodeActionState(
          isLoading: false,
          errorMessage: failure.message,
        );
        return false;
      },
    );
  }

  Future<bool> removeBarcode(String id) async {
    if (state.isLoading) return false;
    state = const BarcodeActionState(isLoading: true);

    final result = await _repository.removeBarcode(id);

    return result.fold(
      (_) {
        state = const BarcodeActionState(
          isLoading: false,
          successMessage: 'Barcode removed.',
        );
        return true;
      },
      (failure) {
        state = BarcodeActionState(
          isLoading: false,
          errorMessage: failure.message,
        );
        return false;
      },
    );
  }

  Future<ProductModel?> searchProductByBarcode(String barcode) async {
    state = const BarcodeActionState(isLoading: true);

    final result = await _repository.searchProductByBarcode(barcode);

    return result.fold(
      (product) {
        state = BarcodeActionState(
          isLoading: false,
          searchedProduct: product,
          errorMessage: product == null
              ? 'No product found for barcode "$barcode"'
              : null,
        );
        return product;
      },
      (failure) {
        state = BarcodeActionState(
          isLoading: false,
          errorMessage: failure.message,
        );
        return null;
      },
    );
  }

  void clearMessages() {
    state = const BarcodeActionState();
  }
}

final barcodeNotifierProvider =
    StateNotifierProvider<BarcodeNotifier, BarcodeActionState>((ref) {
  final repository = ref.watch(barcodeRepositoryProvider);
  return BarcodeNotifier(repository);
});
