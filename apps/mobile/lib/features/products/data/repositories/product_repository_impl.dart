import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../database/drift/database.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_local_data_source.dart';
import '../datasources/product_remote_data_source.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductLocalDataSource _localDataSource;
  final ProductRemoteDataSource _remoteDataSource;
  final String _shopId;

  ProductRepositoryImpl({
    required ProductLocalDataSource localDataSource,
    required ProductRemoteDataSource remoteDataSource,
    required String shopId,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
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
  Stream<List<ProductData>> watchProducts() {
    return _localDataSource.watchProducts(_shopId);
  }

  @override
  Future<Result<void, Failure>> createProduct({
    required String name,
    required int mrpPaise,
    required int sellingPricePaise,
    required String barcode,
    String? categoryId,
    String? unitId,
    double initialStock = 0.0,
    double taxRate = 0.0,
  }) async {
    try {
      final productId = const Uuid().v4();
      final now = DateTime.now();

      // 1. Insert local product record
      await _localDataSource.upsertProduct(
        ProductsTableCompanion(
          id: Value(productId),
          shopId: Value(_shopId),
          name: Value(name),
          mrpPaise: Value(BigInt.from(mrpPaise)),
          sellingPricePaise: Value(BigInt.from(sellingPricePaise)),
          purchasePricePaise: Value(BigInt.zero),
          categoryId: Value(categoryId),
          currentStock: Value(initialStock),
          taxRatePercentage: Value(taxRate),
          isActive: const Value(true),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      // 2. Link barcode
      await _localDataSource.linkBarcode(
        ProductBarcodesTableCompanion(
          id: Value(const Uuid().v4()),
          shopId: Value(_shopId),
          productId: Value(productId),
          barcode: Value(barcode),
          isPrimary: const Value(true),
          createdAt: Value(now),
        ),
      );

      // 3. Enlist in local sync queue
      final opId = const Uuid().v4();
      final payload = {
        'id': productId,
        'shop_id': _shopId,
        'name': name,
        'mrp_paise': mrpPaise,
        'selling_price_paise': sellingPricePaise,
        'barcode': barcode,
        'current_stock': initialStock,
        'tax_rate_percentage': taxRate,
      };

      await _localDataSource.enqueueSyncOperation(
        SyncQueueTableCompanion(
          operationId: Value(opId),
          shopId: Value(_shopId),
          entityType: const Value('product'),
          entityId: Value(productId),
          operationType: const Value('CREATE'),
          payload: Value(jsonEncode(payload)),
          createdAt: Value(now),
          status: const Value('PENDING'),
        ),
      );

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
            name: Value(raw['name'] as String),
            mrpPaise: Value(BigInt.from((raw['mrp_paise'] as num).toInt())),
            sellingPricePaise:
                Value(BigInt.from((raw['selling_price_paise'] as num).toInt())),
            purchasePricePaise: Value(BigInt.from(
                ((raw['purchase_price_paise'] ?? 0) as num).toInt())),
            currentStock:
                Value((raw['current_stock'] as num?)?.toDouble() ?? 0.0),
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
}
