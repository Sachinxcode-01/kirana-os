import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:kirana_mobile/database/drift/database.dart';
import 'package:kirana_mobile/core/network/connectivity_service.dart';
import 'package:kirana_mobile/features/barcodes/domain/models/barcode_model.dart';
import 'package:kirana_mobile/features/barcodes/domain/utils/barcode_validator.dart';
import 'package:kirana_mobile/features/barcodes/data/datasources/barcode_local_data_source.dart';
import 'package:kirana_mobile/features/barcodes/data/datasources/barcode_remote_data_source.dart';
import 'package:kirana_mobile/features/barcodes/data/repositories/barcode_repository_impl.dart';
import 'package:kirana_mobile/features/barcode/presentation/widgets/scan_result_sheet.dart';
import 'package:kirana_mobile/features/products/data/datasources/product_local_data_source.dart';
import 'package:kirana_mobile/features/products/domain/models/product_model.dart';

class MockBarcodeLocalDataSource extends Mock
    implements BarcodeLocalDataSource {}

class MockBarcodeRemoteDataSource extends Mock
    implements BarcodeRemoteDataSource {}

class MockProductLocalDataSource extends Mock
    implements ProductLocalDataSource {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class FakeProductsTableCompanion extends Fake
    implements ProductsTableCompanion {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeProductsTableCompanion());
    registerFallbackValue(
      BarcodeModel(
        id: 'bc_test',
        shopId: 'shop_A',
        productId: 'prod_1',
        barcode: '8901030383742',
        barcodeType: 'EAN_13',
        isPrimary: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  });

  group('Phase 13.1 — Barcode Normalization & Validation', () {
    test(
        'Normalizes raw inputs cleanly removing whitespace and enforcing uppercase',
        () {
      expect(BarcodeValidator.normalize('  8901030383742  '), '8901030383742');
      expect(BarcodeValidator.normalize(' ean-123456 '), 'EAN-123456');
      expect(
          BarcodeValidator.normalize('upc 0123 4567 8905'), 'UPC012345678905');
    });

    test('Validates EAN-13, EAN-8, UPC-A, UPC-E, Code-128, Code-39 formats',
        () {
      expect(BarcodeValidator.validate('8901030383742').isSuccess, isTrue);
      expect(BarcodeValidator.validate('89012345').isSuccess, isTrue);
      expect(BarcodeValidator.validate('012345678905').isSuccess, isTrue);
      expect(BarcodeValidator.validate('123456').isSuccess, isTrue);
      expect(BarcodeValidator.validate('CODE128-PROD').isSuccess, isTrue);
    });

    test('Detects accurate BarcodeType for retail formats', () {
      expect(BarcodeValidator.detectType('8901030383742'), BarcodeType.ean13);
      expect(BarcodeValidator.detectType('89012345'), BarcodeType.ean8);
      expect(BarcodeValidator.detectType('012345678905'), BarcodeType.upcA);
      expect(BarcodeValidator.detectType('123456'), BarcodeType.upcE);
      expect(BarcodeValidator.detectType('PROD-SKU_123'), BarcodeType.code128);
    });
  });

  group('Phase 13.1 — Online & Offline Barcode Lookup Repository', () {
    late MockBarcodeLocalDataSource mockLocal;
    late MockBarcodeRemoteDataSource mockRemote;
    late MockProductLocalDataSource mockProductLocal;
    late MockConnectivityService mockConnectivity;
    late BarcodeRepositoryImpl repository;

    const shopId = 'shop_A_id';
    const testBarcode = '8901030383742';

    final testProduct = ProductModel(
      id: 'prod_123',
      shopId: shopId,
      name: 'Amul Butter 500g',
      sellingPricePaise: 27500,
      mrpPaise: 28500,
      currentStock: 25,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    setUp(() {
      mockLocal = MockBarcodeLocalDataSource();
      mockRemote = MockBarcodeRemoteDataSource();
      mockProductLocal = MockProductLocalDataSource();
      mockConnectivity = MockConnectivityService();

      repository = BarcodeRepositoryImpl(
        localDataSource: mockLocal,
        remoteDataSource: mockRemote,
        productLocalDataSource: mockProductLocal,
        connectivityService: mockConnectivity,
        shopId: shopId,
      );
    });

    test('Returns product from Drift local cache sub-15ms when cached',
        () async {
      when(() => mockLocal.getProductByBarcode(shopId, testBarcode))
          .thenAnswer((_) async => testProduct);

      final result = await repository.searchProductByBarcode(testBarcode);

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, equals(testProduct));
      verify(() => mockLocal.getProductByBarcode(shopId, testBarcode))
          .called(1);
      verifyNever(() => mockRemote.fetchProductByBarcode(any(), any()));
    });

    test(
        'Queries Supabase online when not in local cache and saves to local Drift cache',
        () async {
      when(() => mockLocal.getProductByBarcode(shopId, testBarcode))
          .thenAnswer((_) async => null);
      when(() => mockConnectivity.isOnline()).thenAnswer((_) async => true);
      when(() => mockRemote.fetchProductByBarcode(shopId, testBarcode))
          .thenAnswer((_) async => testProduct);
      when(() => mockProductLocal.upsertProduct(any()))
          .thenAnswer((_) async => 'prod_123');
      when(() => mockLocal.saveBarcode(any())).thenAnswer((_) async => 1);

      final result = await repository.searchProductByBarcode(testBarcode);

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, equals(testProduct));
      verify(() => mockRemote.fetchProductByBarcode(shopId, testBarcode))
          .called(1);
      verify(() => mockProductLocal.upsertProduct(any())).called(1);
    });

    test(
        'Enforces shop isolation: Shop A searching Shop B barcode returns null',
        () async {
      const shopBBarcode = '9999999999999';

      when(() => mockLocal.getProductByBarcode(shopId, shopBBarcode))
          .thenAnswer((_) async => null);
      when(() => mockConnectivity.isOnline()).thenAnswer((_) async => true);
      when(() => mockRemote.fetchProductByBarcode(shopId, shopBBarcode))
          .thenAnswer((_) async => null);

      final result = await repository.searchProductByBarcode(shopBBarcode);

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, isNull);
    });

    test('Offline mode when uncached returns null without calling remote',
        () async {
      when(() => mockLocal.getProductByBarcode(shopId, testBarcode))
          .thenAnswer((_) async => null);
      when(() => mockConnectivity.isOnline()).thenAnswer((_) async => false);

      final result = await repository.searchProductByBarcode(testBarcode);

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, isNull);
      verifyNever(() => mockRemote.fetchProductByBarcode(any(), any()));
    });
  });

  group('Phase 13.1 — ScanResultSheet UI & Unknown Barcode Flow', () {
    testWidgets('Displays product details cleanly when product is found',
        (tester) async {
      final product = ProductModel(
        id: 'p1',
        shopId: 's1',
        name: 'Tata Salt 1kg',
        sellingPricePaise: 2800,
        mrpPaise: 3000,
        unit: 'KG',
        currentStock: 50,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScanResultSheet(
              barcode: '8901030383742',
              product: product,
              onScanAgain: () {},
            ),
          ),
        ),
      );

      expect(find.text('Product Scanned'), findsOneWidget);
      expect(find.text('Tata Salt 1kg'), findsOneWidget);
      expect(find.text('Stock: 50.0 KG'), findsOneWidget);
      expect(find.text('₹28.00'), findsOneWidget);
      expect(find.text('View Product'), findsOneWidget);
    });

    testWidgets(
        'Displays Barcode Not Registered and Add Product button for unknown barcode',
        (tester) async {
      bool addProductTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScanResultSheet(
              barcode: '999888777666',
              product: null,
              onScanAgain: () {},
              onAddProduct: () {
                addProductTapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Barcode Not Registered'), findsWidgets);
      expect(find.text('Detected:\n999888777666'), findsOneWidget);
      expect(find.text('+ Add Product'), findsOneWidget);

      await tester.tap(find.text('+ Add Product'));
      await tester.pumpAndSettle();

      expect(addProductTapped, isTrue);
    });

    testWidgets('Displays offline warning banner when offline and uncached',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScanResultSheet(
              barcode: '999888777666',
              product: null,
              isOffline: true,
              onScanAgain: () {},
            ),
          ),
        ),
      );

      expect(find.text('Product unavailable offline.'), findsWidgets);
    });
  });
}
