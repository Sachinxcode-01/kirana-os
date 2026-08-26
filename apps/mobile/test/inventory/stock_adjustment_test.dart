import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kirana_mobile/core/network/connectivity_service.dart';
import 'package:kirana_mobile/features/inventory/domain/models/adjustment_reason.dart';
import 'package:kirana_mobile/features/inventory/domain/models/inventory_movement_model.dart';
import 'package:kirana_mobile/features/inventory/domain/models/stock_adjustment_request.dart';
import 'package:kirana_mobile/features/inventory/data/repositories/inventory_repository_impl.dart';
import 'package:kirana_mobile/features/inventory/data/datasources/inventory_local_data_source.dart';
import 'package:kirana_mobile/features/inventory/data/datasources/inventory_remote_data_source.dart';
import 'package:kirana_mobile/features/products/data/datasources/product_local_data_source.dart';

class MockInventoryLocalDataSource extends Mock
    implements InventoryLocalDataSource {}

class MockInventoryRemoteDataSource extends Mock
    implements InventoryRemoteDataSource {}

class MockProductLocalDataSource extends Mock
    implements ProductLocalDataSource {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class FakeStockAdjustmentRequest extends Fake
    implements StockAdjustmentRequest {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeStockAdjustmentRequest());
  });

  late MockInventoryLocalDataSource mockLocal;
  late MockInventoryRemoteDataSource mockRemote;
  late MockProductLocalDataSource mockProductLocal;
  late MockConnectivityService mockConnectivity;
  late InventoryRepositoryImpl repository;

  setUp(() {
    mockLocal = MockInventoryLocalDataSource();
    mockRemote = MockInventoryRemoteDataSource();
    mockProductLocal = MockProductLocalDataSource();
    mockConnectivity = MockConnectivityService();

    repository = InventoryRepositoryImpl(
      localDataSource: mockLocal,
      remoteDataSource: mockRemote,
      productLocalDataSource: mockProductLocal,
      connectivityService: mockConnectivity,
    );
  });

  group('Stock Adjustment Domain Models & Logic', () {
    test('StockAdjustmentRequest calculates positive delta for INCREASE', () {
      const request = StockAdjustmentRequest(
        productId: 'prod_101',
        shopId: 'shop_1',
        adjustmentType: InventoryAdjustmentType.stockIn,
        quantity: 10.0,
        reason: 'Physical Count Correction',
        userId: 'user_1',
      );

      expect(request.calculateDelta(50.0), 10.0);
      expect(request.calculateNewStock(50.0), 60.0);
      expect(request.isDecrease(), false);
    });

    test('StockAdjustmentRequest calculates negative delta for DECREASE', () {
      const request = StockAdjustmentRequest(
        productId: 'prod_101',
        shopId: 'shop_1',
        adjustmentType: InventoryAdjustmentType.stockOut,
        quantity: 15.0,
        reason: 'Damaged',
        userId: 'user_1',
      );

      expect(request.calculateDelta(50.0), -15.0);
      expect(request.calculateNewStock(50.0), 35.0);
      expect(request.isDecrease(), true);
    });

    test('AdjustmentReason parses predefined reasons correctly', () {
      expect(AdjustmentReason.fromString('Physical Count Correction'),
          AdjustmentReason.physicalCountCorrection);
      expect(AdjustmentReason.fromString('Damaged'), AdjustmentReason.damaged);
      expect(AdjustmentReason.fromString('Expired'), AdjustmentReason.expired);
      expect(AdjustmentReason.fromString('Lost'), AdjustmentReason.lost);
      expect(AdjustmentReason.fromString('Found'), AdjustmentReason.found);
      expect(AdjustmentReason.fromString('Opening Stock'),
          AdjustmentReason.openingStock);
      expect(AdjustmentReason.fromString('Other'), AdjustmentReason.other);
      expect(AdjustmentReason.fromString('Unknown Reason'),
          AdjustmentReason.other);
    });

    test('InventoryMovementModel serialization handles previous stock', () {
      final now = DateTime.now();
      final model = InventoryMovementModel(
        id: 'mov_99',
        shopId: 'shop_1',
        productId: 'prod_1',
        productName: 'Atta 10kg',
        previousQuantity: 100.0,
        quantityDelta: -10.0,
        balanceAfter: 90.0,
        reason: 'stock_adjustment',
        adjustmentReason: 'Damaged',
        performedBy: 'user_mgr',
        note: 'Broken bag in transit',
        createdAt: now,
      );

      expect(model.computedPreviousQuantity, 100.0);
      expect(model.displayReason, 'Damaged');
      expect(model.isPositive, false);
      expect(model.type, InventoryAdjustmentType.stockOut);

      final json = model.toJson();
      expect(json['previous_quantity'], 100.0);
      expect(json['quantity_delta'], -10.0);
      expect(json['balance_after'], 90.0);

      final restored = InventoryMovementModel.fromJson(json);
      expect(restored.computedPreviousQuantity, 100.0);
      expect(restored.balanceAfter, 90.0);
    });
  });

  group('InventoryRepositoryImpl Stock Adjustment Rules', () {
    test('Offline adjustment is blocked with internet connection error',
        () async {
      when(() => mockConnectivity.isOnline()).thenAnswer((_) async => false);

      const request = StockAdjustmentRequest(
        productId: 'prod_1',
        shopId: 'shop_1',
        adjustmentType: InventoryAdjustmentType.stockIn,
        quantity: 5.0,
        reason: 'Physical Count Correction',
        userId: 'user_1',
      );

      final result = await repository.adjustStock(request);

      expect(result.isError, isTrue);
      expect(
        result.failureOrNull?.message,
        'Internet connection required to adjust stock.',
      );
      verifyZeroInteractions(mockRemote);
    });

    test('Reason "Other" requires non-empty notes', () async {
      when(() => mockConnectivity.isOnline()).thenAnswer((_) async => true);

      const request = StockAdjustmentRequest(
        productId: 'prod_1',
        shopId: 'shop_1',
        adjustmentType: InventoryAdjustmentType.stockIn,
        quantity: 5.0,
        reason: 'Other',
        note: '   ',
        userId: 'user_1',
      );

      final result = await repository.adjustStock(request);

      expect(result.isError, isTrue);
      expect(
        result.failureOrNull?.message,
        'Reason "Other" requires a short explanation in notes',
      );
      verifyZeroInteractions(mockRemote);
    });

    test('Online adjustment succeeds via remote RPC and updates local cache',
        () async {
      when(() => mockConnectivity.isOnline()).thenAnswer((_) async => true);

      const request = StockAdjustmentRequest(
        productId: 'prod_1',
        shopId: 'shop_1',
        adjustmentType: InventoryAdjustmentType.stockIn,
        quantity: 10.0,
        reason: 'Physical Count Correction',
        userId: 'user_1',
      );

      final remoteMovement = InventoryMovementModel(
        id: 'mov_remote_1',
        shopId: 'shop_1',
        productId: 'prod_1',
        previousQuantity: 20.0,
        quantityDelta: 10.0,
        balanceAfter: 30.0,
        reason: 'stock_adjustment',
        adjustmentReason: 'Physical Count Correction',
        performedBy: 'user_1',
        createdAt: DateTime.now(),
      );

      when(() => mockRemote.adjustStock(any()))
          .thenAnswer((_) async => remoteMovement);

      when(() => mockLocal.recordMovementAndStockUpdate(
            movementId: any(named: 'movementId'),
            shopId: any(named: 'shopId'),
            productId: any(named: 'productId'),
            quantityDelta: any(named: 'quantityDelta'),
            reason: any(named: 'reason'),
            adjustmentReason: any(named: 'adjustmentReason'),
            performedBy: any(named: 'performedBy'),
            referenceId: any(named: 'referenceId'),
            note: any(named: 'note'),
            idempotencyKey: any(named: 'idempotencyKey'),
            previousQuantity: any(named: 'previousQuantity'),
            newBalance: any(named: 'newBalance'),
          )).thenAnswer((_) async => remoteMovement);

      final result = await repository.adjustStock(request);

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.balanceAfter, 30.0);
      verify(() => mockRemote.adjustStock(any())).called(1);
    });
  });
}
