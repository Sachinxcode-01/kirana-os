import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_mobile/core/errors/failure.dart';
import 'package:kirana_mobile/core/errors/result.dart';
import 'package:kirana_mobile/features/categories/domain/models/category_model.dart';
import 'package:kirana_mobile/features/categories/domain/repositories/category_repository.dart';
import 'package:kirana_mobile/features/categories/presentation/providers/category_provider.dart';

class MockCategoryRepository implements CategoryRepository {
  bool shouldFail = false;
  String failureMessage = 'Operation failed';

  @override
  Future<Result<CategoryModel, Failure>> createCategory({
    required String name,
    String? description,
    String? iconUrl,
    int sortOrder = 0,
  }) async {
    if (shouldFail) {
      return ErrorResult(ValidationFailure(failureMessage));
    }
    return Success(
      CategoryModel(
        id: 'cat_test_1',
        shopId: 'shop_1',
        name: name,
        description: description,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<Result<CategoryModel, Failure>> updateCategory({
    required String id,
    required String name,
    String? description,
    String? iconUrl,
    int? sortOrder,
  }) async {
    if (shouldFail) {
      return ErrorResult(ValidationFailure(failureMessage));
    }
    return Success(
      CategoryModel(
        id: id,
        shopId: 'shop_1',
        name: name,
        description: description,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<Result<void, Failure>> archiveCategory(String id) async {
    if (shouldFail) {
      return ErrorResult(ValidationFailure(failureMessage));
    }
    return const Success(null);
  }

  @override
  Future<Result<List<CategoryModel>, Failure>> getCategories({
    bool refreshFromRemote = true,
  }) async {
    return const Success([]);
  }

  @override
  Stream<List<CategoryModel>> watchCategories({String? searchQuery}) {
    return Stream.value([]);
  }

  @override
  Future<Result<List<CategoryModel>, Failure>> searchCategories(
      String query) async {
    return const Success([]);
  }

  @override
  Future<Result<int, Failure>> getProductCountForCategory(
      String categoryId) async {
    return const Success(0);
  }
}

void main() {
  late MockCategoryRepository mockRepo;
  late CategoryNotifier notifier;

  setUp(() {
    mockRepo = MockCategoryRepository();
    notifier = CategoryNotifier(mockRepo);
  });

  group('CategoryNotifier State Machine Tests', () {
    test('createCategory success sets successMessage and resets loading',
        () async {
      final success = await notifier.createCategory(
        name: 'Grains & Flours',
        description: 'Wheat, Rice',
      );

      expect(success, isTrue);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.errorMessage, isNull);
      expect(notifier.state.successMessage,
          'Category "Grains & Flours" created successfully.');
    });

    test('createCategory failure sets errorMessage', () async {
      mockRepo.shouldFail = true;
      mockRepo.failureMessage = 'A category with this name already exists.';

      final success = await notifier.createCategory(name: 'Duplicate Category');

      expect(success, isFalse);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.errorMessage,
          'A category with this name already exists.');
    });

    test('updateCategory success sets successMessage', () async {
      final success = await notifier.updateCategory(
        id: 'cat_1',
        name: 'Updated Name',
      );

      expect(success, isTrue);
      expect(notifier.state.successMessage, 'Category "Updated Name" updated.');
    });

    test('archiveCategory success sets successMessage', () async {
      final success = await notifier.archiveCategory('cat_1');

      expect(success, isTrue);
      expect(notifier.state.successMessage, 'Category archived successfully.');
    });

    test('archiveCategory failure sets warning message', () async {
      mockRepo.shouldFail = true;
      mockRepo.failureMessage =
          'Cannot archive category with 5 active products.';

      final success = await notifier.archiveCategory('cat_1');

      expect(success, isFalse);
      expect(notifier.state.errorMessage,
          'Cannot archive category with 5 active products.');
    });
  });
}
