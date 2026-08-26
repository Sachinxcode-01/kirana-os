import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kirana_mobile/core/errors/result.dart';
import 'package:kirana_mobile/core/errors/failure.dart';
import 'package:kirana_mobile/core/network/connectivity_service.dart';
import 'package:kirana_mobile/core/network/connectivity_status.dart';
import 'package:kirana_mobile/features/auth/domain/models/auth_state_model.dart';
import 'package:kirana_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:kirana_mobile/features/purchases/data/datasources/purchase_local_data_source.dart';
import 'package:kirana_mobile/features/purchases/data/datasources/purchase_remote_data_source.dart';
import 'package:kirana_mobile/features/purchases/data/repositories/purchase_repository_impl.dart';
import 'package:kirana_mobile/features/purchases/domain/models/purchase_item_model.dart';
import 'package:kirana_mobile/features/purchases/domain/models/purchase_model.dart';
import 'package:kirana_mobile/features/suppliers/data/datasources/supplier_local_data_source.dart';
import 'package:kirana_mobile/features/suppliers/data/datasources/supplier_remote_data_source.dart';
import 'package:kirana_mobile/features/suppliers/data/repositories/supplier_repository_impl.dart';
import 'package:kirana_mobile/features/suppliers/domain/models/supplier_model.dart';
import 'package:kirana_mobile/features/suppliers/presentation/providers/supplier_provider.dart';
import 'package:kirana_mobile/features/suppliers/presentation/screens/suppliers_screen.dart';

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
  group('KIRANAOS Phase 07.2 — Supplier Management Tests', () {
    late SupplierLocalDataSource localDataSource;
    late SupplierRemoteDataSource remoteDataSource;
    late MockConnectivityService connectivityService;
    late SupplierRepositoryImpl repository;

    late PurchaseLocalDataSource purchaseLocalDS;
    late PurchaseRemoteDataSource purchaseRemoteDS;
    late PurchaseRepositoryImpl purchaseRepository;

    setUp(() {
      localDataSource = SupplierLocalDataSource();
      remoteDataSource = SupplierRemoteDataSource();
      connectivityService = MockConnectivityService();
      repository = SupplierRepositoryImpl(
        localDataSource: localDataSource,
        remoteDataSource: remoteDataSource,
        connectivityService: connectivityService,
      );

      purchaseLocalDS = PurchaseLocalDataSource();
      purchaseRemoteDS = PurchaseRemoteDataSource();
      purchaseRepository = PurchaseRepositoryImpl(
        localDataSource: purchaseLocalDS,
        remoteDataSource: purchaseRemoteDS,
        connectivityService: connectivityService,
      );
    });

    test('1. Creates a supplier with validations and persists locally',
        () async {
      final res = await repository.createSupplier(
        shopId: 'shop_alpha',
        name: 'Hindustan Unilever Dist.',
        phone: '9845012345',
        contactPerson: 'Rajesh Kumar',
        email: 'hul.dist@kirana.com',
        address: 'MG Road, Bangalore',
        gstin: '29AAAAA0000A1Z5',
        notes: 'Delivers on Mondays',
      );

      expect(res, isA<Success<SupplierModel, Failure>>());
      final supplier = (res as Success<SupplierModel, Failure>).data;
      expect(supplier.name, equals('Hindustan Unilever Dist.'));
      expect(supplier.phone, equals('9845012345'));
      expect(supplier.gstin, equals('29AAAAA0000A1Z5'));
      expect(supplier.isArchived, isFalse);

      // Verify fetch by ID
      final fetchedRes = await repository.getSupplierById(supplier.id);
      expect(fetchedRes, isA<Success<SupplierModel?, Failure>>());
      final fetched = (fetchedRes as Success<SupplierModel?, Failure>).data;
      expect(fetched, isNotNull);
      expect(fetched!.contactPerson, equals('Rajesh Kumar'));
    });

    test(
        '2. Prevents duplicate supplier creation with same phone or name within shop',
        () async {
      await repository.createSupplier(
        shopId: 'shop_alpha',
        name: 'ITC Distributors',
        phone: '9988776655',
      );

      // Duplicate phone
      final dupPhoneRes = await repository.createSupplier(
        shopId: 'shop_alpha',
        name: 'ITC Allied Sales',
        phone: '9988776655',
      );
      expect(dupPhoneRes, isA<ErrorResult<SupplierModel, Failure>>());
      expect(
        (dupPhoneRes as ErrorResult<SupplierModel, Failure>).failure,
        isA<ValidationFailure>(),
      );

      // Duplicate name
      final dupNameRes = await repository.createSupplier(
        shopId: 'shop_alpha',
        name: 'itc distributors',
        phone: '9111222333',
      );
      expect(dupNameRes, isA<ErrorResult<SupplierModel, Failure>>());
      expect(
        (dupNameRes as ErrorResult<SupplierModel, Failure>).failure,
        isA<ValidationFailure>(),
      );
    });

    test('3. Updates supplier details successfully', () async {
      final createRes = await repository.createSupplier(
        shopId: 'shop_alpha',
        name: 'Metro Wholesale',
        phone: '9876543210',
      );
      final original = (createRes as Success<SupplierModel, Failure>).data;

      final updatedModel = original.copyWith(
        name: 'Metro Cash & Carry Wholesale',
        contactPerson: 'Suresh Patil',
        email: 'metro@wholesale.in',
      );

      final updateRes = await repository.updateSupplier(updatedModel);
      expect(updateRes, isA<Success<SupplierModel, Failure>>());
      final updated = (updateRes as Success<SupplierModel, Failure>).data;
      expect(updated.name, equals('Metro Cash & Carry Wholesale'));
      expect(updated.contactPerson, equals('Suresh Patil'));
    });

    test('4. Archives supplier and preserves historical purchases', () async {
      final createRes = await repository.createSupplier(
        shopId: 'shop_alpha',
        name: 'Nestle Wholesale',
        phone: '9443322110',
      );
      final supplier = (createRes as Success<SupplierModel, Failure>).data;

      // Link supplier to a completed purchase
      final draftRes = await purchaseRepository.createDraft(
        shopId: 'shop_alpha',
        cashierId: 'user_owner',
      );
      var draft = (draftRes as Success<PurchaseModel, Failure>).data;
      draft = draft.copyWith(
        supplierId: supplier.id,
        supplierName: supplier.name,
        items: [
          PurchaseItemModel.create(
            id: 'item_1',
            purchaseId: draft.id,
            productId: 'prod_maggi',
            productName: 'Maggi 2-Min Noodles',
            quantity: 10.0,
            purchasePricePaise: 1200,
          ),
        ],
      );
      await purchaseRepository.saveDraft(draft);

      final confirmRes = await purchaseRepository.confirmPurchaseStockIn(
        shopId: 'shop_alpha',
        userRole: 'owner',
        currentUserId: 'user_owner',
        purchase: draft,
        idempotencyKey: 'idemp_nestle_1',
      );
      final completedPurchase =
          (confirmRes as Success<PurchaseModel, Failure>).data;
      expect(completedPurchase.supplierId, equals(supplier.id));

      // Archive supplier
      final archiveRes = await repository.archiveSupplier(
        shopId: 'shop_alpha',
        supplierId: supplier.id,
      );
      expect(archiveRes, isA<Success<SupplierModel, Failure>>());
      final archived = (archiveRes as Success<SupplierModel, Failure>).data;
      expect(archived.isArchived, isTrue);

      // Verify active supplier list excludes archived supplier
      final activeListRes = await repository.getSuppliers(
        shopId: 'shop_alpha',
        includeArchived: false,
      );
      final activeList =
          (activeListRes as Success<List<SupplierModel>, Failure>).data;
      expect(activeList.any((s) => s.id == supplier.id), isFalse);

      // Verify historical completed purchase retains linked supplier ID & snapshot
      final fetchPurchaseRes =
          await purchaseRepository.getPurchaseById(completedPurchase.id);
      final fetchedPurchase =
          (fetchPurchaseRes as Success<PurchaseModel?, Failure>).data;
      expect(fetchedPurchase, isNotNull);
      expect(fetchedPurchase!.supplierId, equals(supplier.id));
      expect(fetchedPurchase.supplierName, equals('Nestle Wholesale'));
    });

    test('5. Searches suppliers by name, phone, or GSTIN accurately', () async {
      await repository.createSupplier(
        shopId: 'shop_alpha',
        name: 'Amul Dairy Dist',
        phone: '9845099999',
        gstin: '29BBBBB1111A1Z1',
      );
      await repository.createSupplier(
        shopId: 'shop_alpha',
        name: 'Parle Biscuits Dist',
        phone: '9845088888',
        gstin: '29CCCCC2222A1Z2',
      );

      // Search by Name
      final nameRes = await repository.getSuppliers(
        shopId: 'shop_alpha',
        searchQuery: 'Amul',
      );
      final nameMatches =
          (nameRes as Success<List<SupplierModel>, Failure>).data;
      expect(nameMatches.length, equals(1));
      expect(nameMatches.first.name, contains('Amul'));

      // Search by Phone
      final phoneRes = await repository.getSuppliers(
        shopId: 'shop_alpha',
        searchQuery: '9845088888',
      );
      final phoneMatches =
          (phoneRes as Success<List<SupplierModel>, Failure>).data;
      expect(phoneMatches.length, equals(1));
      expect(phoneMatches.first.name, contains('Parle'));

      // Search by GSTIN
      final gstinRes = await repository.getSuppliers(
        shopId: 'shop_alpha',
        searchQuery: '29BBBBB',
      );
      final gstinMatches =
          (gstinRes as Success<List<SupplierModel>, Failure>).data;
      expect(gstinMatches.length, equals(1));
      expect(gstinMatches.first.name, contains('Amul'));
    });

    test('6. Serves cached suppliers when offline', () async {
      await repository.createSupplier(
        shopId: 'shop_alpha',
        name: 'Britannia Foods',
        phone: '9776655443',
      );

      connectivityService.setStatus(ConnectivityStatus.offline);

      final offlineRes = await repository.getSuppliers(shopId: 'shop_alpha');
      expect(offlineRes, isA<Success<List<SupplierModel>, Failure>>());
      final offlineSuppliers =
          (offlineRes as Success<List<SupplierModel>, Failure>).data;
      expect(offlineSuppliers.any((s) => s.name == 'Britannia Foods'), isTrue);
    });

    testWidgets('7. Renders SuppliersScreen UI and tab switching',
        (tester) async {
      final user = UserModel(
        id: 'user_owner',
        email: 'owner@kirana.com',
        displayName: 'Owner',
        role: 'owner',
        shopId: 'shop_alpha',
        shopName: 'Alpha Kirana',
      );

      await repository.createSupplier(
        shopId: 'shop_alpha',
        name: 'Dabur India Dist',
        phone: '9554433221',
      );

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
            supplierRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(
            home: SuppliersScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Header and Tabs
      expect(find.text('Supplier Directory'), findsOneWidget);
      expect(find.text('Active Suppliers'), findsOneWidget);
      expect(find.text('Archived'), findsOneWidget);
      expect(find.text('Dabur India Dist'), findsOneWidget);

      // Tap Archived Tab
      await tester.tap(find.text('Archived'));
      await tester.pumpAndSettle();

      expect(find.text('No archived suppliers'), findsOneWidget);
    });
  });
}

class AuthNotifierMock extends StateNotifier<AuthStateModel>
    implements AuthNotifier {
  AuthNotifierMock(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
