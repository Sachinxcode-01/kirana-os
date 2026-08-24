import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_mobile/core/errors/failure.dart';
import 'package:kirana_mobile/core/errors/result.dart';
import 'package:kirana_mobile/features/barcodes/domain/models/barcode_model.dart';
import 'package:kirana_mobile/features/barcodes/domain/repositories/barcode_repository.dart';
import 'package:kirana_mobile/features/barcodes/presentation/providers/barcode_provider.dart';
import 'package:kirana_mobile/features/products/domain/models/product_model.dart';

class MockBarcodeRepository implements BarcodeRepository {
  bool shouldFail = false;
  String failureMessage = 'Operation failed';

  @override
  Future<Result<BarcodeModel, Failure>> addBarcode({
    required String productId,
    required String barcode,
    String? barcodeType,
    bool isPrimary = false,
  }) async {
    if (shouldFail) {
      return ErrorResult(ValidationFailure(failureMessage));
    }
    return Success(
      BarcodeModel(
        id: 'bc_1',
        shopId: 'shop_1',
        productId: productId,
        barcode: barcode,
        barcodeType: barcodeType ?? 'EAN_13',
        isPrimary: isPrimary,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<Result<BarcodeModel, Failure>> updateBarcode({
    required String id,
    required String newBarcode,
    String? barcodeType,
    bool? isPrimary,
  }) async {
    if (shouldFail) {
      return ErrorResult(ValidationFailure(failureMessage));
    }
    return Success(
      BarcodeModel(
        id: id,
        shopId: 'shop_1',
        productId: 'prod_1',
        barcode: newBarcode,
        barcodeType: barcodeType ?? 'EAN_13',
        isPrimary: isPrimary ?? true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<Result<void, Failure>> removeBarcode(String id) async {
    if (shouldFail) {
      return ErrorResult(ValidationFailure(failureMessage));
    }
    return const Success(null);
  }

  @override
  Future<Result<List<BarcodeModel>, Failure>> getBarcodesForProduct(
      String productId) async {
    return const Success([]);
  }

  @override
  Stream<List<BarcodeModel>> watchBarcodesForProduct(String productId) {
    return Stream.value([]);
  }

  @override
  Future<Result<ProductModel?, Failure>> searchProductByBarcode(
      String barcode) async {
    if (shouldFail) {
      return ErrorResult(ValidationFailure(failureMessage));
    }
    return Success(
      ProductModel(
        id: 'prod_1',
        shopId: 'shop_1',
        name: 'Test Product',
        sellingPricePaise: 10000,
        mrpPaise: 10000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }
}

void main() {
  late MockBarcodeRepository mockRepo;
  late BarcodeNotifier notifier;

  setUp(() {
    mockRepo = MockBarcodeRepository();
    notifier = BarcodeNotifier(mockRepo);
  });

  group('BarcodeNotifier State Machine Tests', () {
    test('addBarcode success sets successMessage', () async {
      final success = await notifier.addBarcode(
        productId: 'prod_1',
        barcode: '8901030383742',
      );

      expect(success, isTrue);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.errorMessage, isNull);
      expect(notifier.state.successMessage,
          'Barcode "8901030383742" added successfully.');
    });

    test('addBarcode failure sets errorMessage', () async {
      mockRepo.shouldFail = true;
      mockRepo.failureMessage =
          'Barcode "8901030383742" is already assigned to another product.';

      final success = await notifier.addBarcode(
        productId: 'prod_1',
        barcode: '8901030383742',
      );

      expect(success, isFalse);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.errorMessage,
          'Barcode "8901030383742" is already assigned to another product.');
    });

    test('updateBarcode success sets successMessage', () async {
      final success = await notifier.updateBarcode(
        id: 'bc_1',
        newBarcode: '8901030383799',
      );

      expect(success, isTrue);
      expect(notifier.state.successMessage,
          'Barcode "8901030383799" updated successfully.');
    });

    test('removeBarcode success sets successMessage', () async {
      final success = await notifier.removeBarcode('bc_1');

      expect(success, isTrue);
      expect(notifier.state.successMessage, 'Barcode removed.');
    });

    test('searchProductByBarcode returns product and updates state', () async {
      final product = await notifier.searchProductByBarcode('8901030383742');

      expect(product, isNotNull);
      expect(product!.name, 'Test Product');
      expect(notifier.state.searchedProduct, isNotNull);
    });
  });
}
