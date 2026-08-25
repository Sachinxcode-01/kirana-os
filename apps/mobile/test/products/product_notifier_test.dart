import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_mobile/core/errors/failure.dart';
import 'package:kirana_mobile/core/errors/result.dart';
import 'package:kirana_mobile/database/drift/database.dart';
import 'package:kirana_mobile/features/products/domain/models/product_model.dart';
import 'package:kirana_mobile/features/products/domain/repositories/product_repository.dart';
import 'package:kirana_mobile/features/products/presentation/providers/product_provider.dart';

class MockProductRepository implements ProductRepository {
  bool shouldFail = false;
  String failureMessage = 'Operation failed';

  @override
  Future<Result<ProductModel, Failure>> createProduct({
    required String name,
    required String categoryId,
    String? brand,
    String unit = 'PCS',
    required int sellingPricePaise,
    int purchasePricePaise = 0,
    int? mrpPaise,
    double minStockAlert = 5.0,
    double initialStock = 0.0,
    String? description,
    String? barcode,
    double taxRate = 0.0,
  }) async {
    if (shouldFail) {
      return ErrorResult(ValidationFailure(failureMessage));
    }
    return Success(
      ProductModel(
        id: 'prod_test_1',
        shopId: 'shop_1',
        name: name,
        categoryId: categoryId,
        brand: brand,
        unit: unit,
        sellingPricePaise: sellingPricePaise,
        purchasePricePaise: purchasePricePaise,
        mrpPaise: mrpPaise ?? sellingPricePaise,
        minStockAlert: minStockAlert,
        currentStock: initialStock,
        description: description,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<Result<ProductModel, Failure>> updateProduct({
    required String id,
    required String name,
    required String categoryId,
    String? brand,
    String unit = 'PCS',
    required int sellingPricePaise,
    int purchasePricePaise = 0,
    int? mrpPaise,
    double minStockAlert = 5.0,
    String? description,
  }) async {
    if (shouldFail) {
      return ErrorResult(ValidationFailure(failureMessage));
    }
    return Success(
      ProductModel(
        id: id,
        shopId: 'shop_1',
        name: name,
        categoryId: categoryId,
        brand: brand,
        unit: unit,
        sellingPricePaise: sellingPricePaise,
        purchasePricePaise: purchasePricePaise,
        mrpPaise: mrpPaise ?? sellingPricePaise,
        minStockAlert: minStockAlert,
        description: description,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<Result<void, Failure>> archiveProduct(String id) async {
    if (shouldFail) {
      return ErrorResult(ValidationFailure(failureMessage));
    }
    return const Success(null);
  }

  @override
  Future<Result<ProductData?, Failure>> getProductByBarcode(
      String barcode) async {
    return const Success(null);
  }

  @override
  Future<Result<ProductModel?, Failure>> getProductById(String id) async {
    return const Success(null);
  }

  @override
  Future<Result<List<ProductModel>, Failure>> getProducts({
    String? categoryId,
    String? searchQuery,
    bool refreshFromRemote = true,
  }) async {
    return const Success([]);
  }

  @override
  Stream<List<ProductModel>> watchProducts({
    String? categoryId,
    String? searchQuery,
  }) {
    return Stream.value([]);
  }

  @override
  Future<Result<int, Failure>> syncRemoteProducts() async {
    return const Success(0);
  }

  @override
  Future<Result<String, Failure>> uploadProductImage({
    required String productId,
    required List<int> imageBytes,
    required String fileName,
  }) async {
    if (shouldFail) {
      return ErrorResult(ValidationFailure(failureMessage));
    }
    return const Success('https://example.com/test.jpg');
  }

  @override
  Future<Result<void, Failure>> deleteProductImage({
    required String productId,
  }) async {
    if (shouldFail) {
      return ErrorResult(ValidationFailure(failureMessage));
    }
    return const Success(null);
  }
}

void main() {
  late MockProductRepository mockRepo;
  late ProductNotifier notifier;

  setUp(() {
    mockRepo = MockProductRepository();
    notifier = ProductNotifier(mockRepo);
  });

  group('ProductNotifier State Machine Tests', () {
    test('createProduct success sets successMessage', () async {
      final success = await notifier.createProduct(
        name: 'Madhur Sugar 1kg',
        categoryId: 'cat_sugar_1',
        sellingPricePaise: 4800,
      );

      expect(success, isTrue);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.errorMessage, isNull);
      expect(notifier.state.successMessage,
          'Product "Madhur Sugar 1kg" created successfully.');
    });

    test('createProduct failure sets errorMessage', () async {
      mockRepo.shouldFail = true;
      mockRepo.failureMessage = 'A product with this name already exists.';

      final success = await notifier.createProduct(
        name: 'Duplicate Product',
        categoryId: 'cat_1',
        sellingPricePaise: 1000,
      );

      expect(success, isFalse);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.errorMessage,
          'A product with this name already exists.');
    });

    test('updateProduct success sets successMessage', () async {
      final success = await notifier.updateProduct(
        id: 'prod_1',
        name: 'Updated Product Name',
        categoryId: 'cat_1',
        sellingPricePaise: 5500,
      );

      expect(success, isTrue);
      expect(notifier.state.successMessage,
          'Product "Updated Product Name" updated successfully.');
    });

    test('archiveProduct success sets successMessage', () async {
      final success = await notifier.archiveProduct('prod_1');

      expect(success, isTrue);
      expect(notifier.state.successMessage, 'Product archived.');
    });
  });
}
