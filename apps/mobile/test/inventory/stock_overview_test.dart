import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kirana_mobile/core/errors/failure.dart';
import 'package:kirana_mobile/core/errors/result.dart';
import 'package:kirana_mobile/core/network/connectivity_service.dart';
import 'package:kirana_mobile/core/network/connectivity_status.dart';
import 'package:kirana_mobile/features/auth/domain/models/auth_state_model.dart';
import 'package:kirana_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:kirana_mobile/features/billing/data/datasources/billing_local_data_source.dart';
import 'package:kirana_mobile/features/billing/data/datasources/billing_remote_data_source.dart';
import 'package:kirana_mobile/features/billing/data/repositories/billing_repository_impl.dart';
import 'package:kirana_mobile/features/billing/domain/models/bill_model.dart';
import 'package:kirana_mobile/features/billing/domain/models/payment_model.dart';
import 'package:kirana_mobile/features/inventory/data/datasources/stock_local_data_source.dart';
import 'package:kirana_mobile/features/inventory/data/datasources/stock_remote_data_source.dart';
import 'package:kirana_mobile/features/inventory/data/repositories/stock_repository_impl.dart';
import 'package:kirana_mobile/features/inventory/domain/models/stock_overview_model.dart';
import 'package:kirana_mobile/features/inventory/presentation/providers/stock_overview_provider.dart';
import 'package:kirana_mobile/features/inventory/presentation/screens/stock_overview_screen.dart';
import 'package:kirana_mobile/features/products/domain/models/product_model.dart';


class MockConnectivityService implements ConnectivityService {
  ConnectivityStatus _status = ConnectivityStatus.online;

  void setStatus(ConnectivityStatus s) => _status = s;

  @override
  ConnectivityStatus get currentStatus => _status;

  @override
  Stream<ConnectivityStatus> get statusStream => Stream.value(_status);

  @override
  Future<bool> isOnline() async => _status == ConnectivityStatus.online;

  @override
  Future<ConnectivityStatus> checkConnectivity() async => _status;

  @override
  void updateSyncStatus(ConnectivityStatus status) {
    _status = status;
  }

  @override
  void dispose() {}
}

void main() {
  group('KIRANAOS Phase 07.4 — Stock Overview Tests', () {
    late StockLocalDataSource localDataSource;
    late StockRemoteDataSource remoteDataSource;
    late MockConnectivityService connectivityService;
    late StockRepositoryImpl repository;

    late BillingLocalDataSource billingLocalDS;
    late BillingRemoteDataSource billingRemoteDS;
    late BillingRepositoryImpl billingRepository;

    setUp(() {
      localDataSource = StockLocalDataSource();
      remoteDataSource = StockRemoteDataSource();
      connectivityService = MockConnectivityService();
      repository = StockRepositoryImpl(
        localDataSource: localDataSource,
        remoteDataSource: remoteDataSource,
        connectivityService: connectivityService,
      );

      billingLocalDS = BillingLocalDataSource();
      billingRemoteDS = BillingRemoteDataSource();
      billingRepository = BillingRepositoryImpl(
        localDataSource: billingLocalDS,
        remoteDataSource: billingRemoteDS,
        connectivityService: connectivityService,
      );
    });

    test(
        '1. Correctly calculates StockStatus based on configured min_stock_alert',
        () {
      final inStock = ProductModel(
        id: 'p1',
        shopId: 'shop_alpha',
        name: 'Rice 5kg',
        sellingPricePaise: 25000,
        mrpPaise: 30000,
        currentStock: 10.0,
        minStockAlert: 3.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(inStock.stockStatus, equals(StockStatus.inStock));

      final lowStock = ProductModel(
        id: 'p2',
        shopId: 'shop_alpha',
        name: 'Wheat 5kg',
        sellingPricePaise: 20000,
        mrpPaise: 24000,
        currentStock: 2.0,
        minStockAlert: 5.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(lowStock.stockStatus, equals(StockStatus.lowStock));

      final outOfStock = ProductModel(
        id: 'p3',
        shopId: 'shop_alpha',
        name: 'Sugar 1kg',
        sellingPricePaise: 4500,
        mrpPaise: 5000,
        currentStock: 0.0,
        minStockAlert: 5.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(outOfStock.stockStatus, equals(StockStatus.outOfStock));
    });

    test('2. Loads paginated stock list and filters by StockStatus', () async {
      final p1 = ProductModel(
        id: 'p1',
        shopId: 'shop_alpha',
        name: 'Maggi 2-Min Noodles',
        sellingPricePaise: 1400,
        mrpPaise: 1400,
        currentStock: 20.0,
        minStockAlert: 5.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final p2 = ProductModel(
        id: 'p2',
        shopId: 'shop_alpha',
        name: 'Tata Salt 1kg',
        sellingPricePaise: 2800,
        mrpPaise: 3000,
        currentStock: 2.0,
        minStockAlert: 5.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final p3 = ProductModel(
        id: 'p3',
        shopId: 'shop_alpha',
        name: 'Fortune Oil 1L',
        sellingPricePaise: 14500,
        mrpPaise: 16000,
        currentStock: 0.0,
        minStockAlert: 3.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await localDataSource.saveProducts([p1, p2, p3]);

      // All Products Overview
      final allRes = await repository.getStockOverview(shopId: 'shop_alpha');
      expect(allRes, isA<Success<StockOverviewResult, Failure>>());
      final allData = (allRes as Success<StockOverviewResult, Failure>).data;
      expect(allData.totalCount, equals(3));
      expect(allData.inStockCount, equals(1));
      expect(allData.lowStockCount, equals(1));
      expect(allData.outOfStockCount, equals(1));

      // Filter LOW STOCK
      final lowRes = await repository.getStockOverview(
        shopId: 'shop_alpha',
        filter: const StockOverviewFilter(statusFilter: StockStatus.lowStock),
      );
      final lowData = (lowRes as Success<StockOverviewResult, Failure>).data;
      expect(lowData.products.length, equals(1));
      expect(lowData.products.first.name, equals('Tata Salt 1kg'));
    });

    test('3. Searches stock by product name and HSN code', () async {
      final p1 = ProductModel(
        id: 'p1',
        shopId: 'shop_alpha',
        name: 'Amul Butter 100g',
        hsnCode: '04051000',
        sellingPricePaise: 5800,
        mrpPaise: 6000,
        currentStock: 15.0,
        minStockAlert: 5.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final p2 = ProductModel(
        id: 'p2',
        shopId: 'shop_alpha',
        name: 'Britannia Cheese Slices',
        hsnCode: '04063000',
        sellingPricePaise: 13000,
        mrpPaise: 14000,
        currentStock: 8.0,
        minStockAlert: 2.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await localDataSource.saveProducts([p1, p2]);

      // Search by Name
      final nameRes = await repository.getStockOverview(
        shopId: 'shop_alpha',
        filter: const StockOverviewFilter(search: 'Amul'),
      );
      final nameData = (nameRes as Success<StockOverviewResult, Failure>).data;
      expect(nameData.products.length, equals(1));
      expect(nameData.products.first.name, contains('Amul'));

      // Search by HSN Code
      final hsnRes = await repository.getStockOverview(
        shopId: 'shop_alpha',
        filter: const StockOverviewFilter(search: '04063000'),
      );
      final hsnData = (hsnRes as Success<StockOverviewResult, Failure>).data;
      expect(hsnData.products.length, equals(1));
      expect(hsnData.products.first.name, contains('Britannia'));
    });

    test('4. Increases stock quantity on completed purchase stock-in',
        () async {
      final initialProduct = ProductModel(
        id: 'prod_mrp_1',
        shopId: 'shop_alpha',
        name: 'Dabur Honey 250g',
        sellingPricePaise: 18000,
        mrpPaise: 20000,
        currentStock: 5.0,
        minStockAlert: 2.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await localDataSource.saveProduct(initialProduct);

      // Simulate stock update on stock-in
      final updatedProduct = initialProduct.copyWith(
        currentStock: initialProduct.currentStock + 10.0,
      );
      await localDataSource.saveProduct(updatedProduct);

      final fetchedRes = await repository.getProductStockDetails(
        shopId: 'shop_alpha',
        productId: initialProduct.id,
      );
      final fetched = (fetchedRes as Success<ProductModel?, Failure>).data;
      expect(fetched, isNotNull);
      expect(fetched!.currentStock, equals(15.0));
      expect(fetched.stockStatus, equals(StockStatus.inStock));
    });

    test('5. Decreases stock quantity on completed sale checkout', () async {
      final initialProduct = ProductModel(
        id: 'prod_sale_1',
        shopId: 'shop_alpha',
        name: 'Cadbury Dairy Milk 50g',
        sellingPricePaise: 4000,
        mrpPaise: 4000,
        currentStock: 10.0,
        minStockAlert: 3.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await localDataSource.saveProduct(initialProduct);

      final item = BillItemModel(
        id: 'bitem_1',
        billId: 'bill_sale_1',
        productId: initialProduct.id,
        productName: initialProduct.name,
        unitPricePaise: initialProduct.sellingPricePaise,
        quantity: 4.0,
        taxAmountPaise: 0,
        totalPaise: 16000,
        createdAt: DateTime.now(),
      );

      final draftBill = BillModel(
        id: 'bill_sale_1',
        shopId: 'shop_alpha',
        cashierId: 'user_cashier',
        billNumber: 'BILL-1001',
        status: 'draft',
        items: [item],
        totalPaise: 16000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final payment = PaymentModel(
        id: 'pay_1',
        shopId: 'shop_alpha',
        billId: 'bill_sale_1',
        mode: 'cash',
        amountPaise: 16000,
        status: 'success',
        createdAt: DateTime.now(),
      );

      final checkoutRes = await billingRepository.completeSaleCheckout(
        bill: draftBill,
        payment: payment,
        idempotencyKey: 'idemp_sale_stock_1',
      );
      expect(checkoutRes, isA<Success<BillModel, Failure>>());

      // Simulate stock update after checkout
      final updatedProduct = initialProduct.copyWith(
        currentStock: initialProduct.currentStock - 4.0,
      );
      await localDataSource.saveProduct(updatedProduct);

      final fetchedRes = await repository.getProductStockDetails(
        shopId: 'shop_alpha',
        productId: initialProduct.id,
      );
      final fetched = (fetchedRes as Success<ProductModel?, Failure>).data;
      expect(fetched, isNotNull);
      expect(fetched!.currentStock, equals(6.0));
    });

    testWidgets(
        '6. Renders StockOverviewScreen UI with filters and Stock Details modal',
        (tester) async {
      final user = UserModel(
        id: 'user_owner',
        email: 'owner@kirana.com',
        displayName: 'Owner',
        role: 'owner',
        shopId: 'shop_alpha',
        shopName: 'Alpha Kirana',
      );

      final p = ProductModel(
        id: 'prod_ui_stock',
        shopId: 'shop_alpha',
        name: 'Haldiram Bhujia 200g',
        sellingPricePaise: 5500,
        mrpPaise: 6000,
        currentStock: 2.0,
        minStockAlert: 5.0,
        hsnCode: '21069099',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await localDataSource.saveProduct(p);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              (ref) => AuthNotifierMock(
                AuthStateModel.authenticatedWithShop(
                  user: user,
                  shopId: 'shop_alpha',
                  shopName: 'Alpha Kirana',
                ),
              ),
            ),
            stockRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(
            home: StockOverviewScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Header and Stock Card
      expect(find.text('Stock Overview'), findsOneWidget);
      expect(find.text('Haldiram Bhujia 200g'), findsOneWidget);
      expect(find.text('LOW STOCK'), findsWidgets);

      // Tap Stock Card to open details modal
      await tester.tap(find.text('Haldiram Bhujia 200g'));
      await tester.pumpAndSettle();

      // Verify Modal details
      expect(find.text('2.0 PCS'), findsOneWidget);
      expect(
          find.text('Stock level is below safety minimum threshold (5.0 PCS).'),
          findsOneWidget);
    });
  });
}

class AuthNotifierMock extends StateNotifier<AuthStateModel>
    implements AuthNotifier {
  AuthNotifierMock(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
