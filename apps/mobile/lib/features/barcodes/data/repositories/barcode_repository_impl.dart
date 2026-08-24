import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:kirana_mobile/core/errors/error_handler.dart';
import 'package:kirana_mobile/core/errors/failure.dart';
import 'package:kirana_mobile/core/errors/result.dart';
import 'package:kirana_mobile/core/network/connectivity_service.dart';
import 'package:kirana_mobile/core/utils/app_logger.dart';
import 'package:kirana_mobile/database/drift/database.dart';
import 'package:kirana_mobile/features/products/data/datasources/product_local_data_source.dart';
import 'package:kirana_mobile/features/products/domain/models/product_model.dart';
import '../../domain/models/barcode_model.dart';
import '../../domain/repositories/barcode_repository.dart';
import '../../domain/utils/barcode_validator.dart';
import '../datasources/barcode_local_data_source.dart';
import '../datasources/barcode_remote_data_source.dart';

class BarcodeRepositoryImpl implements BarcodeRepository {
  final BarcodeLocalDataSource _localDataSource;
  final BarcodeRemoteDataSource _remoteDataSource;
  final ProductLocalDataSource _productLocalDataSource;
  final ConnectivityService? _connectivityService;
  final String _shopId;
  final Uuid _uuid = const Uuid();

  BarcodeRepositoryImpl({
    required BarcodeLocalDataSource localDataSource,
    required BarcodeRemoteDataSource remoteDataSource,
    required ProductLocalDataSource productLocalDataSource,
    ConnectivityService? connectivityService,
    required String shopId,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        _productLocalDataSource = productLocalDataSource,
        _connectivityService = connectivityService,
        _shopId = shopId;

  @override
  Future<Result<BarcodeModel, Failure>> addBarcode({
    required String productId,
    required String barcode,
    String? barcodeType,
    bool isPrimary = false,
  }) async {
    final validation = BarcodeValidator.validate(barcode);
    if (validation.isError) {
      return ErrorResult(validation.failureOrNull!);
    }

    final cleanCode = validation.dataOrNull!;
    final detectedType =
        barcodeType ?? BarcodeValidator.detectType(cleanCode).code;

    try {
      // 1. Duplicate check per shop
      final existing =
          await _localDataSource.getBarcodeByValue(_shopId, cleanCode);
      if (existing != null) {
        return ErrorResult(ValidationFailure(
            'Barcode "$cleanCode" is already assigned to a product in this shop.'));
      }

      final now = DateTime.now();
      final model = BarcodeModel(
        id: 'bc_${_uuid.v4()}',
        shopId: _shopId,
        productId: productId,
        barcode: cleanCode,
        barcodeType: detectedType,
        isPrimary: isPrimary,
        createdAt: now,
        updatedAt: now,
      );

      // 2. Save locally (Offline First)
      await _localDataSource.saveBarcode(model);

      // 3. Enqueue mutation in sync queue
      final opId = 'sync_bc_${_uuid.v4()}';
      await _localDataSource.enqueueSyncOperation(
        SyncQueueTableCompanion(
          operationId: Value(opId),
          shopId: Value(_shopId),
          entityType: const Value('product_barcode'),
          entityId: Value(model.id),
          operationType: const Value('CREATE'),
          payload: Value(jsonEncode(model.toJson())),
          createdAt: Value(now),
          status: const Value('PENDING'),
        ),
      );

      // 4. Opportunistic cloud push
      if (_connectivityService != null) {
        final isOnline = await _connectivityService.isOnline();
        if (isOnline) {
          try {
            await _remoteDataSource.createBarcode(model);
          } catch (cloudErr) {
            AppLogger.w('Background barcode cloud creation deferred: $cloudErr',
                tag: 'BarcodeRepository');
          }
        }
      }

      return Success(model);
    } catch (e) {
      return ErrorResult(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Result<BarcodeModel, Failure>> updateBarcode({
    required String id,
    required String newBarcode,
    String? barcodeType,
    bool? isPrimary,
  }) async {
    final validation = BarcodeValidator.validate(newBarcode);
    if (validation.isError) {
      return ErrorResult(validation.failureOrNull!);
    }

    final cleanCode = validation.dataOrNull!;

    try {
      final current = await _localDataSource.getBarcodeById(id);
      if (current == null) {
        return const ErrorResult(ValidationFailure('Barcode entry not found'));
      }

      if (current.barcode != cleanCode) {
        final existing =
            await _localDataSource.getBarcodeByValue(_shopId, cleanCode);
        if (existing != null && existing.id != id) {
          return ErrorResult(ValidationFailure(
              'Barcode "$cleanCode" is already assigned to another product.'));
        }
      }

      final detectedType =
          barcodeType ?? BarcodeValidator.detectType(cleanCode).code;
      final now = DateTime.now();

      final updated = current.copyWith(
        barcode: cleanCode,
        barcodeType: detectedType,
        isPrimary: isPrimary ?? current.isPrimary,
        updatedAt: now,
      );

      // Save locally
      await _localDataSource.saveBarcode(updated);

      // Enqueue sync UPDATE
      final opId = 'sync_bc_upd_${_uuid.v4()}';
      await _localDataSource.enqueueSyncOperation(
        SyncQueueTableCompanion(
          operationId: Value(opId),
          shopId: Value(_shopId),
          entityType: const Value('product_barcode'),
          entityId: Value(updated.id),
          operationType: const Value('UPDATE'),
          payload: Value(jsonEncode(updated.toJson())),
          createdAt: Value(now),
          status: const Value('PENDING'),
        ),
      );

      // Cloud push if online
      if (_connectivityService != null) {
        final isOnline = await _connectivityService.isOnline();
        if (isOnline) {
          try {
            await _remoteDataSource.updateBarcode(updated);
          } catch (cloudErr) {
            AppLogger.w('Background barcode cloud update deferred: $cloudErr',
                tag: 'BarcodeRepository');
          }
        }
      }

      return Success(updated);
    } catch (e) {
      return ErrorResult(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Result<void, Failure>> removeBarcode(String id) async {
    try {
      final current = await _localDataSource.getBarcodeById(id);
      if (current == null) {
        return const ErrorResult(ValidationFailure('Barcode not found'));
      }

      // Delete locally
      await _localDataSource.deleteBarcode(id);

      final now = DateTime.now();
      final opId = 'sync_bc_del_${_uuid.v4()}';
      await _localDataSource.enqueueSyncOperation(
        SyncQueueTableCompanion(
          operationId: Value(opId),
          shopId: Value(_shopId),
          entityType: const Value('product_barcode'),
          entityId: Value(id),
          operationType: const Value('DELETE'),
          payload: Value(jsonEncode({'id': id, 'shop_id': _shopId})),
          createdAt: Value(now),
          status: const Value('PENDING'),
        ),
      );

      if (_connectivityService != null) {
        final isOnline = await _connectivityService.isOnline();
        if (isOnline) {
          try {
            await _remoteDataSource.deleteBarcode(id, _shopId);
          } catch (cloudErr) {
            AppLogger.w('Background barcode cloud delete deferred: $cloudErr',
                tag: 'BarcodeRepository');
          }
        }
      }

      return const Success(null);
    } catch (e) {
      return ErrorResult(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Result<List<BarcodeModel>, Failure>> getBarcodesForProduct(
      String productId) async {
    try {
      final barcodes = await _localDataSource.getBarcodesForProduct(productId);
      return Success(barcodes);
    } catch (e) {
      return ErrorResult(ErrorHandler.handleException(e));
    }
  }

  @override
  Stream<List<BarcodeModel>> watchBarcodesForProduct(String productId) {
    return _localDataSource.watchBarcodesForProduct(productId);
  }

  @override
  Future<Result<ProductModel?, Failure>> searchProductByBarcode(
      String barcode) async {
    final validation = BarcodeValidator.validate(barcode);
    if (validation.isError) {
      return ErrorResult(validation.failureOrNull!);
    }

    final cleanCode = validation.dataOrNull!;

    try {
      // 1. Sub-15ms fast indexed local Drift lookup
      final localProduct =
          await _localDataSource.getProductByBarcode(_shopId, cleanCode);
      if (localProduct != null) {
        return Success(localProduct);
      }

      // 2. If unavailable locally, check Supabase cloud when online
      if (_connectivityService != null) {
        final isOnline = await _connectivityService.isOnline();
        if (isOnline) {
          final remoteProduct = await _remoteDataSource.fetchProductByBarcode(
            _shopId,
            cleanCode,
          );

          if (remoteProduct != null) {
            // 3. Cache product & barcode locally in Drift
            await _productLocalDataSource.upsertProduct(
              ProductsTableCompanion(
                id: Value(remoteProduct.id),
                shopId: Value(_shopId),
                categoryId: Value(remoteProduct.categoryId),
                name: Value(remoteProduct.name),
                brand: Value(remoteProduct.brand),
                unit: Value(remoteProduct.unit),
                mrpPaise: Value(BigInt.from(remoteProduct.mrpPaise)),
                sellingPricePaise:
                    Value(BigInt.from(remoteProduct.sellingPricePaise)),
                purchasePricePaise:
                    Value(BigInt.from(remoteProduct.purchasePricePaise)),
                currentStock: Value(remoteProduct.currentStock),
                minStockAlert: Value(remoteProduct.minStockAlert),
                description: Value(remoteProduct.description),
                taxRatePercentage: Value(remoteProduct.taxRatePercentage),
                isActive: Value(remoteProduct.isActive),
                createdAt: Value(remoteProduct.createdAt),
                updatedAt: Value(remoteProduct.updatedAt),
              ),
            );

            await _localDataSource.saveBarcode(
              BarcodeModel(
                id: 'bc_${_uuid.v4()}',
                shopId: _shopId,
                productId: remoteProduct.id,
                barcode: cleanCode,
                barcodeType: BarcodeValidator.detectType(cleanCode).code,
                isPrimary: true,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );

            return Success(remoteProduct);
          }
        }
      }

      return const Success(null);
    } catch (e) {
      return ErrorResult(ErrorHandler.handleException(e));
    }
  }
}
