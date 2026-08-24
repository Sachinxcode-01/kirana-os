import 'package:uuid/uuid.dart';
import 'package:kirana_mobile/core/errors/error_handler.dart';
import 'package:kirana_mobile/core/errors/failure.dart';
import 'package:kirana_mobile/core/errors/result.dart';
import 'package:kirana_mobile/core/network/connectivity_service.dart';
import 'package:kirana_mobile/core/utils/app_logger.dart';
import '../../domain/models/category_model.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_local_data_source.dart';
import '../datasources/category_remote_data_source.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryLocalDataSource _localDataSource;
  final CategoryRemoteDataSource _remoteDataSource;
  final ConnectivityService _connectivityService;
  final String _shopId;
  final Uuid _uuid = const Uuid();

  CategoryRepositoryImpl({
    required CategoryLocalDataSource localDataSource,
    required CategoryRemoteDataSource remoteDataSource,
    required ConnectivityService connectivityService,
    required String shopId,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        _connectivityService = connectivityService,
        _shopId = shopId;

  @override
  Future<Result<CategoryModel, Failure>> createCategory({
    required String name,
    String? description,
    String? iconUrl,
    int sortOrder = 0,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      return const ErrorResult(ValidationFailure('Category name is required'));
    }

    try {
      // 1. Duplicate check in current shop
      final existing =
          await _localDataSource.getCategoryByName(_shopId, cleanName);
      if (existing != null && existing.isActive) {
        return ErrorResult(ValidationFailure(
            'A category with the name "$cleanName" already exists.'));
      }

      final now = DateTime.now();
      final category = CategoryModel(
        id: 'cat_${_uuid.v4()}',
        shopId: _shopId,
        name: cleanName,
        description:
            description?.trim().isEmpty == true ? null : description?.trim(),
        iconUrl: iconUrl,
        sortOrder: sortOrder,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      // 2. Persist to local Drift database (Offline First)
      await _localDataSource.saveCategory(category);

      // 3. Enqueue mutation in local sync queue
      final operationId = 'sync_cat_${_uuid.v4()}';
      await _localDataSource.enqueueSyncOperation(
        operationId: operationId,
        shopId: _shopId,
        entityId: category.id,
        operationType: 'INSERT',
        payload: category.toJson(),
      );

      // 4. Opportunistically sync with Supabase if online
      final isOnline = await _connectivityService.isOnline();
      if (isOnline) {
        try {
          await _remoteDataSource.createCategory(category);
        } catch (cloudErr) {
          AppLogger.w('Background cloud sync deferred: $cloudErr',
              tag: 'CategoryRepository');
        }
      }

      return Success(category);
    } catch (e) {
      return ErrorResult(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Result<CategoryModel, Failure>> updateCategory({
    required String id,
    required String name,
    String? description,
    String? iconUrl,
    int? sortOrder,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      return const ErrorResult(ValidationFailure('Category name is required'));
    }

    try {
      final current = await _localDataSource.getCategoryById(id);
      if (current == null) {
        return const ErrorResult(ValidationFailure('Category not found'));
      }

      // Check duplicate name if name changed
      if (current.name.toLowerCase() != cleanName.toLowerCase()) {
        final existing =
            await _localDataSource.getCategoryByName(_shopId, cleanName);
        if (existing != null && existing.id != id && existing.isActive) {
          return ErrorResult(ValidationFailure(
              'Another category with the name "$cleanName" already exists.'));
        }
      }

      final updated = current.copyWith(
        name: cleanName,
        description:
            description?.trim().isEmpty == true ? null : description?.trim(),
        iconUrl: iconUrl ?? current.iconUrl,
        sortOrder: sortOrder ?? current.sortOrder,
        updatedAt: DateTime.now(),
      );

      // Update locally
      await _localDataSource.saveCategory(updated);

      // Enqueue sync
      final operationId = 'sync_cat_upd_${_uuid.v4()}';
      await _localDataSource.enqueueSyncOperation(
        operationId: operationId,
        shopId: _shopId,
        entityId: updated.id,
        operationType: 'UPDATE',
        payload: updated.toJson(),
      );

      final isOnline = await _connectivityService.isOnline();
      if (isOnline) {
        try {
          await _remoteDataSource.updateCategory(updated);
        } catch (cloudErr) {
          AppLogger.w('Background cloud update deferred: $cloudErr',
              tag: 'CategoryRepository');
        }
      }

      return Success(updated);
    } catch (e) {
      return ErrorResult(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Result<void, Failure>> archiveCategory(String id) async {
    try {
      // Check active products associated
      final activeProductCount =
          await _localDataSource.countActiveProductsInCategory(id);
      if (activeProductCount > 0) {
        return ErrorResult(ValidationFailure(
          'Cannot archive category with $activeProductCount active products. Please reassign or delete products first.',
        ));
      }

      // Soft delete locally
      await _localDataSource.softDeleteCategory(id);

      // Enqueue sync operation
      final operationId = 'sync_cat_del_${_uuid.v4()}';
      await _localDataSource.enqueueSyncOperation(
        operationId: operationId,
        shopId: _shopId,
        entityId: id,
        operationType: 'DELETE',
        payload: {'id': id, 'shop_id': _shopId, 'is_active': false},
      );

      final isOnline = await _connectivityService.isOnline();
      if (isOnline) {
        try {
          await _remoteDataSource.archiveCategory(id, _shopId);
        } catch (cloudErr) {
          AppLogger.w('Background cloud archive deferred: $cloudErr',
              tag: 'CategoryRepository');
        }
      }

      return const Success(null);
    } catch (e) {
      return ErrorResult(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Result<List<CategoryModel>, Failure>> getCategories({
    bool refreshFromRemote = true,
  }) async {
    try {
      // 1. Fetch local cached categories
      final local = await _localDataSource.getCategories(_shopId);

      // 2. Refresh from cloud if online and requested
      if (refreshFromRemote) {
        final isOnline = await _connectivityService.isOnline();
        if (isOnline) {
          try {
            final remote = await _remoteDataSource.fetchCategories(_shopId);
            if (remote.isNotEmpty) {
              await _localDataSource.saveCategories(remote);
              return Success(await _localDataSource.getCategories(_shopId));
            }
          } catch (cloudErr) {
            AppLogger.w('Cloud fetch failed, using local cache: $cloudErr',
                tag: 'CategoryRepository');
          }
        }
      }

      return Success(local);
    } catch (e) {
      return ErrorResult(ErrorHandler.handle(e));
    }
  }

  @override
  Stream<List<CategoryModel>> watchCategories({String? searchQuery}) {
    return _localDataSource.watchCategories(_shopId, searchQuery: searchQuery);
  }

  @override
  Future<Result<List<CategoryModel>, Failure>> searchCategories(
      String query) async {
    try {
      final results = await _localDataSource.searchCategories(_shopId, query);
      return Success(results);
    } catch (e) {
      return ErrorResult(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Result<int, Failure>> getProductCountForCategory(
      String categoryId) async {
    try {
      final count =
          await _localDataSource.countActiveProductsInCategory(categoryId);
      return Success(count);
    } catch (e) {
      return ErrorResult(ErrorHandler.handle(e));
    }
  }
}
