import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kirana_mobile/app/app_providers.dart';
import '../../domain/models/category_model.dart';
import '../../domain/repositories/category_repository.dart';
import '../../data/datasources/category_local_data_source.dart';
import '../../data/datasources/category_remote_data_source.dart';
import '../../data/repositories/category_repository_impl.dart';

final categoryLocalDataSourceProvider =
    Provider<CategoryLocalDataSource>((ref) {
  final db = ref.watch(databaseProvider);
  return CategoryLocalDataSource(db);
});

final categoryRemoteDataSourceProvider =
    Provider<CategoryRemoteDataSource>((ref) {
  return CategoryRemoteDataSource();
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final local = ref.watch(categoryLocalDataSourceProvider);
  final remote = ref.watch(categoryRemoteDataSourceProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  final shopId = ref.watch(activeShopIdProvider);

  return CategoryRepositoryImpl(
    localDataSource: local,
    remoteDataSource: remote,
    connectivityService: connectivity,
    shopId: shopId,
  );
});

final categorySearchQueryProvider = StateProvider<String>((ref) => '');

final categoriesStreamProvider =
    StreamProvider.autoDispose<List<CategoryModel>>((ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  final searchQuery = ref.watch(categorySearchQueryProvider);
  return repository.watchCategories(searchQuery: searchQuery);
});

class CategoryActionState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const CategoryActionState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });
}

class CategoryNotifier extends StateNotifier<CategoryActionState> {
  final CategoryRepository _repository;

  CategoryNotifier(this._repository) : super(const CategoryActionState());

  Future<bool> createCategory({
    required String name,
    String? description,
    String? iconUrl,
    int sortOrder = 0,
  }) async {
    if (state.isLoading) return false;
    state = const CategoryActionState(isLoading: true);

    final result = await _repository.createCategory(
      name: name,
      description: description,
      iconUrl: iconUrl,
      sortOrder: sortOrder,
    );

    return result.fold(
      (category) {
        state = CategoryActionState(
          isLoading: false,
          successMessage: 'Category "${category.name}" created successfully.',
        );
        return true;
      },
      (failure) {
        state = CategoryActionState(
          isLoading: false,
          errorMessage: failure.message,
        );
        return false;
      },
    );
  }

  Future<bool> updateCategory({
    required String id,
    required String name,
    String? description,
    String? iconUrl,
    int? sortOrder,
  }) async {
    if (state.isLoading) return false;
    state = const CategoryActionState(isLoading: true);

    final result = await _repository.updateCategory(
      id: id,
      name: name,
      description: description,
      iconUrl: iconUrl,
      sortOrder: sortOrder,
    );

    return result.fold(
      (category) {
        state = CategoryActionState(
          isLoading: false,
          successMessage: 'Category "${category.name}" updated.',
        );
        return true;
      },
      (failure) {
        state = CategoryActionState(
          isLoading: false,
          errorMessage: failure.message,
        );
        return false;
      },
    );
  }

  Future<bool> archiveCategory(String id) async {
    if (state.isLoading) return false;
    state = const CategoryActionState(isLoading: true);

    final result = await _repository.archiveCategory(id);

    return result.fold(
      (_) {
        state = const CategoryActionState(
          isLoading: false,
          successMessage: 'Category archived successfully.',
        );
        return true;
      },
      (failure) {
        state = CategoryActionState(
          isLoading: false,
          errorMessage: failure.message,
        );
        return false;
      },
    );
  }

  void clearMessages() {
    state = const CategoryActionState();
  }
}

final categoryNotifierProvider =
    StateNotifierProvider<CategoryNotifier, CategoryActionState>((ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return CategoryNotifier(repository);
});
