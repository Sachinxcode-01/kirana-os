import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kirana_mobile/app/app_providers.dart';
import '../../domain/models/product_model.dart';
import '../../domain/repositories/product_repository.dart';
import '../../data/datasources/product_local_data_source.dart';
import '../../data/datasources/product_remote_data_source.dart';
import '../../data/repositories/product_repository_impl.dart';

final productLocalDataSourceProvider = Provider<ProductLocalDataSource>((ref) {
  final db = ref.watch(databaseProvider);
  return ProductLocalDataSource(db);
});

final productRemoteDataSourceProvider =
    Provider<ProductRemoteDataSource>((ref) {
  return ProductRemoteDataSource();
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final local = ref.watch(productLocalDataSourceProvider);
  final remote = ref.watch(productRemoteDataSourceProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  final shopId = ref.watch(activeShopIdProvider);

  return ProductRepositoryImpl(
    localDataSource: local,
    remoteDataSource: remote,
    connectivityService: connectivity,
    shopId: shopId,
  );
});

final productSearchQueryProvider = StateProvider<String>((ref) => '');
final productCategoryFilterProvider = StateProvider<String?>((ref) => null);

final productsStreamProvider =
    StreamProvider.autoDispose<List<ProductModel>>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  final searchQuery = ref.watch(productSearchQueryProvider);
  final categoryId = ref.watch(productCategoryFilterProvider);

  return repository.watchProducts(
    searchQuery: searchQuery,
    categoryId: categoryId,
  );
});

class ProductActionState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const ProductActionState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });
}

class ProductNotifier extends StateNotifier<ProductActionState> {
  final ProductRepository _repository;

  ProductNotifier(this._repository) : super(const ProductActionState());

  Future<bool> createProduct({
    required String name,
    required String categoryId,
    String? sku,
    String? brand,
    String unit = 'PCS',
    required int sellingPricePaise,
    int purchasePricePaise = 0,
    int? mrpPaise,
    double minStockAlert = 5.0,
    String? description,
    String? barcode,
    double taxRate = 0.0,
    bool isActive = true,
  }) async {
    if (state.isLoading) return false;
    state = const ProductActionState(isLoading: true);

    final result = await _repository.createProduct(
      name: name,
      categoryId: categoryId,
      sku: sku,
      brand: brand,
      unit: unit,
      sellingPricePaise: sellingPricePaise,
      purchasePricePaise: purchasePricePaise,
      mrpPaise: mrpPaise,
      minStockAlert: minStockAlert,
      description: description,
      barcode: barcode,
      taxRate: taxRate,
      isActive: isActive,
    );

    return result.fold(
      (product) {
        state = ProductActionState(
          isLoading: false,
          successMessage: 'Product "${product.name}" created successfully.',
        );
        return true;
      },
      (failure) {
        state = ProductActionState(
          isLoading: false,
          errorMessage: failure.message,
        );
        return false;
      },
    );
  }

  Future<bool> updateProduct({
    required String id,
    required String name,
    required String categoryId,
    String? sku,
    String? brand,
    String unit = 'PCS',
    required int sellingPricePaise,
    int purchasePricePaise = 0,
    int? mrpPaise,
    double minStockAlert = 5.0,
    String? description,
    String? barcode,
    double taxRate = 0.0,
    bool isActive = true,
  }) async {
    if (state.isLoading) return false;
    state = const ProductActionState(isLoading: true);

    final result = await _repository.updateProduct(
      id: id,
      name: name,
      categoryId: categoryId,
      sku: sku,
      brand: brand,
      unit: unit,
      sellingPricePaise: sellingPricePaise,
      purchasePricePaise: purchasePricePaise,
      mrpPaise: mrpPaise,
      minStockAlert: minStockAlert,
      description: description,
      barcode: barcode,
      taxRate: taxRate,
      isActive: isActive,
    );

    return result.fold(
      (product) {
        state = ProductActionState(
          isLoading: false,
          successMessage: 'Product "${product.name}" updated successfully.',
        );
        return true;
      },
      (failure) {
        state = ProductActionState(
          isLoading: false,
          errorMessage: failure.message,
        );
        return false;
      },
    );
  }

  Future<bool> archiveProduct(String id) async {
    if (state.isLoading) return false;
    state = const ProductActionState(isLoading: true);

    final result = await _repository.archiveProduct(id);

    return result.fold(
      (_) {
        state = const ProductActionState(
          isLoading: false,
          successMessage: 'Product archived.',
        );
        return true;
      },
      (failure) {
        state = ProductActionState(
          isLoading: false,
          errorMessage: failure.message,
        );
        return false;
      },
    );
  }

  Future<String?> uploadProductImage({
    required String productId,
    required List<int> imageBytes,
    required String fileName,
  }) async {
    if (state.isLoading) return null;
    state = const ProductActionState(isLoading: true);

    final result = await _repository.uploadProductImage(
      productId: productId,
      imageBytes: imageBytes,
      fileName: fileName,
    );

    return result.fold(
      (imageUrl) {
        state = const ProductActionState(
          isLoading: false,
          successMessage: 'Product image uploaded successfully.',
        );
        return imageUrl;
      },
      (failure) {
        state = ProductActionState(
          isLoading: false,
          errorMessage: failure.message,
        );
        return null;
      },
    );
  }

  Future<bool> deleteProductImage(String productId) async {
    if (state.isLoading) return false;
    state = const ProductActionState(isLoading: true);

    final result = await _repository.deleteProductImage(productId: productId);

    return result.fold(
      (_) {
        state = const ProductActionState(
          isLoading: false,
          successMessage: 'Product image deleted.',
        );
        return true;
      },
      (failure) {
        state = ProductActionState(
          isLoading: false,
          errorMessage: failure.message,
        );
        return false;
      },
    );
  }

  void clearMessages() {
    state = const ProductActionState();
  }
}

final productNotifierProvider =
    StateNotifierProvider<ProductNotifier, ProductActionState>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return ProductNotifier(repository);
});
