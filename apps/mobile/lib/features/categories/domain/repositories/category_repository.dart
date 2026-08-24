import 'package:kirana_mobile/core/errors/failure.dart';
import 'package:kirana_mobile/core/errors/result.dart';
import '../models/category_model.dart';

abstract interface class CategoryRepository {
  /// Create new category with duplicate check and sync queue
  Future<Result<CategoryModel, Failure>> createCategory({
    required String name,
    String? description,
    String? iconUrl,
    int sortOrder = 0,
  });

  /// Update existing category details
  Future<Result<CategoryModel, Failure>> updateCategory({
    required String id,
    required String name,
    String? description,
    String? iconUrl,
    int? sortOrder,
  });

  /// Archive/soft-delete category with product check
  Future<Result<void, Failure>> archiveCategory(String id);

  /// Fetch all active categories
  Future<Result<List<CategoryModel>, Failure>> getCategories({
    bool refreshFromRemote = true,
  });

  /// Real-time stream of categories for current shop, optionally filtered
  Stream<List<CategoryModel>> watchCategories({String? searchQuery});

  /// Search categories with fast local query
  Future<Result<List<CategoryModel>, Failure>> searchCategories(String query);

  /// Get active product count for category
  Future<Result<int, Failure>> getProductCountForCategory(String categoryId);
}
