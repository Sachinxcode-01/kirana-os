import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../database/drift/database.dart';
import '../../domain/models/product_model.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_local_data_source.dart';
import '../datasources/product_remote_data_source.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductLocalDataSource _localDataSource;
  final ProductRemoteDataSource _remoteDataSource;
  final ConnectivityService? _connectivityService;
  final String _shopId;
  final Uuid _uuid = const Uuid();

  ProductRepositoryImpl({
    required ProductLocalDataSource localDataSource,
    required ProductRemoteDataSource remoteDataSource,
    ConnectivityService? connectivityService,
    required String shopId,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        _connectivityService = connectivityService,
        _shopId = shopId;

  @override
  Future<Result<ProductData?, Failure>> getProductByBarcode(
      String barcode) async {
    try {
      final product =
          await _localDataSource.getProductByBarcode(_shopId, barcode);
      return Success(product);
    } catch (e) {
      return ErrorResult(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Result<ProductModel?, Failure>> getProductById(String id) async {
    try {
      final product = await _localDataSource.getProductById(id);
      return Success(product);
    } catch (e) {
      return ErrorResult(ErrorHandler.handleException(e));
    }
  }

  @override
  Stream<List<ProductModel>> watchProducts({
    String? categoryId,
    String? searchQuery,
  }) {
    return _localDataSource.watchProducts(
      _shopId,
      categoryId: categoryId,
      searchQuery: searchQuery,
    );
  }

  @override
  Future<Result<List<ProductModel>, Failure>> getProducts({
    String? categoryId,
    String? searchQuery,
    bool refreshFromRemote = true,
  }) async {
    try {
      final local = await _localDataSource.getProducts(
        _shopId,
        categoryId: categoryId,
        searchQuery: searchQuery,
      );

      if (refreshFromRemote && _connectivityService != null) {
        final isOnline = await _connectivityService.isOnline();
        if (isOnline) {
          try {
            await syncRemoteProducts();
            final refreshed = await _localDataSource.getProducts(
              _shopId,
              categoryId: categoryId,
              searchQuery: searchQuery,
            );
            return Success(refreshed);
          } catch (cloudErr) {
            AppLogger.w('Background cloud fetch deferred: $cloudErr',
                tag: 'ProductRepository');
          }
        }
      }

      return Success(local);
    } catch (e) {
      return ErrorResult(ErrorHandler.handleException(e));
    }
  }

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
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      return const ErrorResult(ValidationFailure('Product name is required'));
    }

    final cleanCategory = categoryId.trim();
    if (cleanCategory.isEmpty) {
      return const ErrorResult(ValidationFailure('Category is required'));
    }

    if (sellingPricePaise <= 0) {
      return const ErrorResult(
          ValidationFailure('Selling price must be greater than zero'));
    }

    if (purchasePricePaise < 0) {
      return const ErrorResult(
          ValidationFailure('Purchase price cannot be negative'));
    }

    if (minStockAlert < 0) {
      return const ErrorResult(
          ValidationFailure('Minimum stock alert cannot be negative'));
    }

    try {
      // 1. Check duplicate name in same shop
      final existing =
          await _localDataSource.getProductByName(_shopId, cleanName);
      if (existing != null && existing.isActive) {
        return ErrorResult(ValidationFailure(
            'A product with the name "$cleanName" already exists.'));
      }

      final productId = _uuid.v4();
      final now = DateTime.now();
      final actualMrp = mrpPaise ?? sellingPricePaise;

      final product = ProductModel(
        id: productId,
        shopId: _shopId,
        name: cleanName,
        categoryId: cleanCategory,
        brand: brand?.trim().isEmpty == true ? null : brand?.trim(),
        unit: unit.trim().isEmpty ? 'PCS' : unit.trim(),
        sellingPricePaise: sellingPricePaise,
        purchasePricePaise: purchasePricePaise,
        mrpPaise: actualMrp,
        currentStock: initialStock,
        minStockAlert: minStockAlert,
        description:
            description?.trim().isEmpty == true ? null : description?.trim(),
        taxRatePercentage: taxRate,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      // 2. Persist to local Drift SQLite (Offline First)
      await _localDataSource.upsertProduct(
        ProductsTableCompanion(
          id: Value(product.id),
          shopId: Value(_shopId),
          categoryId: Value(product.categoryId),
          name: Value(product.name),
          brand: Value(product.brand),
          imageUrl: Value(product.imageUrl),
          unit: Value(product.unit),
          mrpPaise: Value(BigInt.from(product.mrpPaise)),
          sellingPricePaise: Value(BigInt.from(product.sellingPricePaise)),
          purchasePricePaise: Value(BigInt.from(product.purchasePricePaise)),
          currentStock: Value(product.currentStock),
          minStockAlert: Value(product.minStockAlert),
          description: Value(product.description),
          taxRatePercentage: Value(product.taxRatePercentage),
          isActive: const Value(true),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      // 3. Link barcode if provided
      if (barcode != null && barcode.trim().isNotEmpty) {
        await _localDataSource.linkBarcode(
          ProductBarcodesTableCompanion(
            id: Value(_uuid.v4()),
            shopId: Value(_shopId),
            productId: Value(product.id),
            barcode: Value(barcode.trim()),
            isPrimary: const Value(true),
            createdAt: Value(now),
          ),
        );
      }

      // 4. Enlist in local sync queue
      final opId = _uuid.v4();
      await _localDataSource.enqueueSyncOperation(
        SyncQueueTableCompanion(
          operationId: Value(opId),
          shopId: Value(_shopId),
          entityType: const Value('product'),
          entityId: Value(product.id),
          operationType: const Value('CREATE'),
          payload: Value(jsonEncode(product.toJson())),
          createdAt: Value(now),
          status: const Value('PENDING'),
        ),
      );

      // 5. Opportunistically sync with cloud if online
      if (_connectivityService != null) {
        final isOnline = await _connectivityService.isOnline();
        if (isOnline) {
          try {
            await _remoteDataSource.createProduct(product);
          } catch (cloudErr) {
            AppLogger.w('Background cloud product creation deferred: $cloudErr',
                tag: 'ProductRepository');
          }
        }
      }

      return Success(product);
    } catch (e) {
      return ErrorResult(ErrorHandler.handleException(e));
    }
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
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      return const ErrorResult(ValidationFailure('Product name is required'));
    }

    final cleanCategory = categoryId.trim();
    if (cleanCategory.isEmpty) {
      return const ErrorResult(ValidationFailure('Category is required'));
    }

    if (sellingPricePaise <= 0) {
      return const ErrorResult(
          ValidationFailure('Selling price must be greater than zero'));
    }

    if (purchasePricePaise < 0) {
      return const ErrorResult(
          ValidationFailure('Purchase price cannot be negative'));
    }

    if (minStockAlert < 0) {
      return const ErrorResult(
          ValidationFailure('Minimum stock alert cannot be negative'));
    }

    try {
      final current = await _localDataSource.getProductById(id);
      if (current == null) {
        return const ErrorResult(ValidationFailure('Product not found'));
      }

      // Duplicate name check if name changed
      if (current.name.toLowerCase() != cleanName.toLowerCase()) {
        final existing =
            await _localDataSource.getProductByName(_shopId, cleanName);
        if (existing != null && existing.id != id && existing.isActive) {
          return ErrorResult(ValidationFailure(
              'Another product with the name "$cleanName" already exists.'));
        }
      }

      final now = DateTime.now();
      final updated = current.copyWith(
        name: cleanName,
        categoryId: cleanCategory,
        brand: brand?.trim().isEmpty == true ? null : brand?.trim(),
        unit: unit.trim().isEmpty ? 'PCS' : unit.trim(),
        sellingPricePaise: sellingPricePaise,
        purchasePricePaise: purchasePricePaise,
        mrpPaise: mrpPaise ?? current.mrpPaise,
        minStockAlert: minStockAlert,
        description:
            description?.trim().isEmpty == true ? null : description?.trim(),
        updatedAt: now,
      );

      // 1. Update Drift SQLite
      await _localDataSource.upsertProduct(
        ProductsTableCompanion(
          id: Value(updated.id),
          shopId: Value(_shopId),
          categoryId: Value(updated.categoryId),
          name: Value(updated.name),
          brand: Value(updated.brand),
          imageUrl: Value(updated.imageUrl),
          unit: Value(updated.unit),
          mrpPaise: Value(BigInt.from(updated.mrpPaise)),
          sellingPricePaise: Value(BigInt.from(updated.sellingPricePaise)),
          purchasePricePaise: Value(BigInt.from(updated.purchasePricePaise)),
          currentStock: Value(updated.currentStock),
          minStockAlert: Value(updated.minStockAlert),
          description: Value(updated.description),
          taxRatePercentage: Value(updated.taxRatePercentage),
          isActive: const Value(true),
          createdAt: Value(updated.createdAt),
          updatedAt: Value(now),
        ),
      );

      // 2. Enqueue sync UPDATE
      final opId = _uuid.v4();
      await _localDataSource.enqueueSyncOperation(
        SyncQueueTableCompanion(
          operationId: Value(opId),
          shopId: Value(_shopId),
          entityType: const Value('product'),
          entityId: Value(updated.id),
          operationType: const Value('UPDATE'),
          payload: Value(jsonEncode(updated.toJson())),
          createdAt: Value(now),
          status: const Value('PENDING'),
        ),
      );

      // 3. Cloud sync if online
      if (_connectivityService != null) {
        final isOnline = await _connectivityService.isOnline();
        if (isOnline) {
          try {
            await _remoteDataSource.updateProduct(updated);
          } catch (cloudErr) {
            AppLogger.w('Background cloud product update deferred: $cloudErr',
                tag: 'ProductRepository');
          }
        }
      }

      return Success(updated);
    } catch (e) {
      return ErrorResult(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Result<void, Failure>> archiveProduct(String id) async {
    try {
      await _localDataSource.softDeleteProduct(id);

      final now = DateTime.now();
      final opId = _uuid.v4();
      await _localDataSource.enqueueSyncOperation(
        SyncQueueTableCompanion(
          operationId: Value(opId),
          shopId: Value(_shopId),
          entityType: const Value('product'),
          entityId: Value(id),
          operationType: const Value('DELETE'),
          payload: Value(
              jsonEncode({'id': id, 'shop_id': _shopId, 'is_active': false})),
          createdAt: Value(now),
          status: const Value('PENDING'),
        ),
      );

      if (_connectivityService != null) {
        final isOnline = await _connectivityService.isOnline();
        if (isOnline) {
          try {
            await _remoteDataSource.archiveProduct(id, _shopId);
          } catch (cloudErr) {
            AppLogger.w('Background cloud archive deferred: $cloudErr',
                tag: 'ProductRepository');
          }
        }
      }

      return const Success(null);
    } catch (e) {
      return ErrorResult(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Result<int, Failure>> syncRemoteProducts() async {
    try {
      final remoteProducts = await _remoteDataSource.fetchProducts(_shopId);
      int count = 0;

      for (final raw in remoteProducts) {
        final productId = raw['id'] as String;
        await _localDataSource.upsertProduct(
          ProductsTableCompanion(
            id: Value(productId),
            shopId: Value(_shopId),
            categoryId: Value(raw['category_id'] as String?),
            name: Value(raw['name'] as String),
            brand: Value(raw['brand'] as String?),
            imageUrl: Value(raw['image_url'] as String?),
            unit: Value(raw['unit'] as String? ?? 'PCS'),
            mrpPaise: Value(BigInt.from((raw['mrp_paise'] as num).toInt())),
            sellingPricePaise:
                Value(BigInt.from((raw['selling_price_paise'] as num).toInt())),
            purchasePricePaise: Value(BigInt.from(
                ((raw['purchase_price_paise'] ?? 0) as num).toInt())),
            currentStock:
                Value((raw['current_stock'] as num?)?.toDouble() ?? 0.0),
            minStockAlert:
                Value((raw['min_stock_alert'] as num?)?.toDouble() ?? 5.0),
            description: Value(raw['description'] as String?),
            taxRatePercentage:
                Value((raw['tax_rate_percentage'] as num?)?.toDouble() ?? 0.0),
            isActive: Value(raw['is_active'] as bool? ?? true),
            createdAt: Value(DateTime.parse(raw['created_at'] as String)),
            updatedAt: Value(DateTime.parse(raw['updated_at'] as String)),
          ),
        );

        final barcodes = raw['product_barcodes'] as List<dynamic>? ?? [];
        for (final b in barcodes) {
          await _localDataSource.linkBarcode(
            ProductBarcodesTableCompanion(
              id: Value(b['id'] as String),
              shopId: Value(_shopId),
              productId: Value(productId),
              barcode: Value(b['barcode'] as String),
              isPrimary: Value(b['is_primary'] as bool? ?? true),
              createdAt: Value(DateTime.parse(b['created_at'] as String)),
            ),
          );
        }
        count++;
      }

      return Success(count);
    } catch (e) {
      return ErrorResult(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Result<String, Failure>> uploadProductImage({
    required String productId,
    required List<int> imageBytes,
    required String fileName,
  }) async {
    if (imageBytes.isEmpty) {
      return const ErrorResult(ValidationFailure('Image file cannot be empty'));
    }

    if (imageBytes.length > 5 * 1024 * 1024) {
      return const ErrorResult(
          ValidationFailure('Image size exceeds maximum limit of 5MB'));
    }

    try {
      final product = await _localDataSource.getProductById(productId);
      if (product == null) {
        return const ErrorResult(ValidationFailure('Product not found'));
      }

      String? publicUrl;
      bool uploadedToCloud = false;

      // 1. Try uploading to Supabase Storage if online
      if (_connectivityService != null) {
        final isOnline = await _connectivityService.isOnline();
        if (isOnline) {
          try {
            publicUrl = await _remoteDataSource.uploadProductImage(
              shopId: _shopId,
              productId: productId,
              imageBytes: imageBytes,
              fileName: fileName,
            );
            uploadedToCloud = true;
          } catch (cloudErr) {
            AppLogger.w('Cloud image upload deferred: $cloudErr',
                tag: 'ProductRepository');
          }
        }
      }

      // If offline or cloud upload failed, use placeholder reference
      final finalImageUrl = publicUrl ??
          'cached_local_image_${DateTime.now().millisecondsSinceEpoch}';

      final now = DateTime.now();
      final updatedProduct = product.copyWith(
        imageUrl: finalImageUrl,
        updatedAt: now,
      );

      // 2. Persist updated product with image to Drift SQLite
      await _localDataSource.upsertProduct(
        ProductsTableCompanion(
          id: Value(updatedProduct.id),
          shopId: Value(_shopId),
          categoryId: Value(updatedProduct.categoryId),
          name: Value(updatedProduct.name),
          brand: Value(updatedProduct.brand),
          imageUrl: Value(finalImageUrl),
          unit: Value(updatedProduct.unit),
          mrpPaise: Value(BigInt.from(updatedProduct.mrpPaise)),
          sellingPricePaise:
              Value(BigInt.from(updatedProduct.sellingPricePaise)),
          purchasePricePaise:
              Value(BigInt.from(updatedProduct.purchasePricePaise)),
          currentStock: Value(updatedProduct.currentStock),
          minStockAlert: Value(updatedProduct.minStockAlert),
          description: Value(updatedProduct.description),
          taxRatePercentage: Value(updatedProduct.taxRatePercentage),
          isActive: Value(updatedProduct.isActive),
          createdAt: Value(updatedProduct.createdAt),
          updatedAt: Value(now),
        ),
      );

      // 3. Enqueue sync operation if offline
      if (!uploadedToCloud) {
        final opId = _uuid.v4();
        await _localDataSource.enqueueSyncOperation(
          SyncQueueTableCompanion(
            operationId: Value(opId),
            shopId: Value(_shopId),
            entityType: const Value('product_image'),
            entityId: Value(productId),
            operationType: const Value('UPLOAD_IMAGE'),
            payload: Value(jsonEncode({
              'product_id': productId,
              'shop_id': _shopId,
              'file_name': fileName,
            })),
            createdAt: Value(now),
            status: const Value('PENDING'),
          ),
        );
      }

      return Success(finalImageUrl);
    } catch (e) {
      return ErrorResult(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Result<void, Failure>> deleteProductImage({
    required String productId,
  }) async {
    try {
      final product = await _localDataSource.getProductById(productId);
      if (product == null) {
        return const ErrorResult(ValidationFailure('Product not found'));
      }

      final now = DateTime.now();
      final updatedProduct = product.copyWith(
        imageUrl: null,
        updatedAt: now,
      );

      // 1. Clear imageUrl in local Drift SQLite
      await _localDataSource.upsertProduct(
        ProductsTableCompanion(
          id: Value(updatedProduct.id),
          shopId: Value(_shopId),
          categoryId: Value(updatedProduct.categoryId),
          name: Value(updatedProduct.name),
          brand: Value(updatedProduct.brand),
          imageUrl: const Value(null),
          unit: Value(updatedProduct.unit),
          mrpPaise: Value(BigInt.from(updatedProduct.mrpPaise)),
          sellingPricePaise:
              Value(BigInt.from(updatedProduct.sellingPricePaise)),
          purchasePricePaise:
              Value(BigInt.from(updatedProduct.purchasePricePaise)),
          currentStock: Value(updatedProduct.currentStock),
          minStockAlert: Value(updatedProduct.minStockAlert),
          description: Value(updatedProduct.description),
          taxRatePercentage: Value(updatedProduct.taxRatePercentage),
          isActive: Value(updatedProduct.isActive),
          createdAt: Value(updatedProduct.createdAt),
          updatedAt: Value(now),
        ),
      );

      // 2. Remove from Supabase Storage if online
      if (_connectivityService != null) {
        final isOnline = await _connectivityService.isOnline();
        if (isOnline) {
          try {
            await _remoteDataSource.deleteProductImage(
              shopId: _shopId,
              productId: productId,
              storagePath: '$_shopId/$productId/primary.jpg',
            );
          } catch (cloudErr) {
            AppLogger.w('Cloud image delete deferred: $cloudErr',
                tag: 'ProductRepository');
          }
        } else {
          // Enqueue delete sync operation
          final opId = _uuid.v4();
          await _localDataSource.enqueueSyncOperation(
            SyncQueueTableCompanion(
              operationId: Value(opId),
              shopId: Value(_shopId),
              entityType: const Value('product_image'),
              entityId: Value(productId),
              operationType: const Value('DELETE_IMAGE'),
              payload: Value(jsonEncode({
                'product_id': productId,
                'shop_id': _shopId,
              })),
              createdAt: Value(now),
              status: const Value('PENDING'),
            ),
          );
        }
      }

      return const Success(null);
    } catch (e) {
      return ErrorResult(ErrorHandler.handleException(e));
    }
  }
}
