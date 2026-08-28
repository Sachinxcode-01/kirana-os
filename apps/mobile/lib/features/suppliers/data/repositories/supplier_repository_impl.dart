import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/network/connectivity_status.dart';
import '../../../../database/drift/database.dart';
import '../../../purchases/domain/models/purchase_model.dart';
import '../../domain/models/supplier_model.dart';
import '../../domain/repositories/supplier_repository.dart';
import '../datasources/supplier_local_data_source.dart';
import '../datasources/supplier_remote_data_source.dart';

class SupplierRepositoryImpl implements SupplierRepository {
  final SupplierLocalDataSource _localDataSource;
  final SupplierRemoteDataSource _remoteDataSource;
  final ConnectivityService _connectivityService;
  final _uuid = const Uuid();

  SupplierRepositoryImpl({
    required SupplierLocalDataSource localDataSource,
    required SupplierRemoteDataSource remoteDataSource,
    required ConnectivityService connectivityService,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        _connectivityService = connectivityService;

  @override
  Future<Result<SupplierModel, Failure>> createSupplier({
    required String shopId,
    required String name,
    required String phone,
    String? contactPerson,
    String? email,
    String? address,
    String? gstin,
    String? notes,
  }) async {
    try {
      final cleanName = name.trim();
      final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');

      if (cleanName.length < 2) {
        return const ErrorResult(
          ValidationFailure(
              'Supplier business name must be at least 2 characters.'),
        );
      }

      if (!SupplierModel.isValidPhone(cleanPhone)) {
        return const ErrorResult(
          ValidationFailure('Enter a valid 10-digit mobile number.'),
        );
      }

      if (!SupplierModel.isValidEmail(email)) {
        return const ErrorResult(
          ValidationFailure('Enter a valid email address format.'),
        );
      }

      if (!SupplierModel.isValidGstin(gstin)) {
        return const ErrorResult(
          ValidationFailure('GSTIN must be exactly 15 characters long.'),
        );
      }

      final existingSuppliers =
          await _localDataSource.getSuppliers(shopId, includeArchived: true);
      final hasDuplicate = existingSuppliers.any(
        (s) =>
            !s.isArchived &&
            (s.phone == cleanPhone ||
                s.name.toLowerCase() == cleanName.toLowerCase()),
      );

      if (hasDuplicate) {
        return const ErrorResult(
          ValidationFailure(
              'A supplier with this name or phone number already exists.'),
        );
      }

      final now = DateTime.now();
      final suppId =
          'supp_${now.millisecondsSinceEpoch}_${_uuid.v4().substring(0, 6)}';
      final supplier = SupplierModel(
        id: suppId,
        shopId: shopId,
        name: cleanName,
        contactPerson: contactPerson?.trim(),
        phone: cleanPhone,
        email: email?.trim(),
        address: address?.trim(),
        gstin: gstin?.trim().toUpperCase(),
        notes: notes?.trim(),
        currentBalancePaise: 0,
        isArchived: false,
        createdAt: now,
        updatedAt: now,
      );

      final companion = SuppliersTableCompanion.insert(
        id: suppId,
        shopId: shopId,
        name: cleanName,
        phone: cleanPhone,
        email: Value(email?.trim()),
        address: Value(address?.trim()),
        gstin: Value(gstin?.trim().toUpperCase()),
        contactPerson: Value(contactPerson?.trim()),
        notes: Value(notes?.trim()),
        createdAt: Value(now),
        updatedAt: Value(now),
      );

      if (_connectivityService.currentStatus != ConnectivityStatus.offline) {
        try {
          await _remoteDataSource.insertSupplier(supplier);
        } catch (_) {}
      }

      await _localDataSource.saveSupplier(companion);
      return Success(supplier);
    } catch (e) {
      return ErrorResult(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Result<SupplierModel, Failure>> updateSupplier(
      SupplierModel supplier) async {
    try {
      if (supplier.name.trim().length < 2) {
        return const ErrorResult(
          ValidationFailure('Supplier name must be at least 2 characters.'),
        );
      }

      if (!SupplierModel.isValidPhone(supplier.phone)) {
        return const ErrorResult(
          ValidationFailure('Enter a valid 10-digit phone number.'),
        );
      }

      final now = DateTime.now();
      final updated = supplier.copyWith(updatedAt: now);

      final companion = SuppliersTableCompanion.insert(
        id: supplier.id,
        shopId: supplier.shopId,
        name: supplier.name.trim(),
        phone: supplier.phone,
        email: Value(supplier.email),
        address: Value(supplier.address),
        gstin: Value(supplier.gstin),
        contactPerson: Value(supplier.contactPerson),
        notes: Value(supplier.notes),
        currentBalancePaise: Value(BigInt.from(supplier.currentBalancePaise)),
        isArchived: Value(supplier.isArchived),
        createdAt: Value(supplier.createdAt),
        updatedAt: Value(now),
      );

      if (_connectivityService.currentStatus != ConnectivityStatus.offline) {
        try {
          await _remoteDataSource.updateSupplier(updated);
        } catch (_) {}
      }

      await _localDataSource.saveSupplier(companion);
      return Success(updated);
    } catch (e) {
      return ErrorResult(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Result<SupplierModel, Failure>> archiveSupplier({
    required String shopId,
    required String supplierId,
  }) async {
    try {
      final existing = await _localDataSource.getSupplierById(supplierId);
      if (existing == null) {
        return const ErrorResult(
            ValidationFailure('Supplier record not found.'));
      }

      if (existing.shopId != shopId) {
        return const ErrorResult(
          PermissionDeniedFailure(
              'Cannot archive a supplier from another shop.'),
        );
      }

      final archivedModel = SupplierModel(
        id: existing.id,
        shopId: existing.shopId,
        name: existing.name,
        contactPerson: existing.contactPerson,
        phone: existing.phone,
        email: existing.email,
        address: existing.address,
        gstin: existing.gstin,
        notes: existing.notes,
        currentBalancePaise: existing.currentBalancePaise.toInt(),
        isArchived: true,
        createdAt: existing.createdAt,
        updatedAt: DateTime.now(),
      );

      if (_connectivityService.currentStatus != ConnectivityStatus.offline) {
        try {
          await _remoteDataSource.archiveSupplier(shopId, supplierId);
        } catch (_) {}
      }

      await _localDataSource.archiveSupplier(supplierId);
      return Success(archivedModel);
    } catch (e) {
      return ErrorResult(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Result<List<SupplierModel>, Failure>> getSuppliers({
    required String shopId,
    bool includeArchived = false,
    String? searchQuery,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      if (shopId.trim().isEmpty) {
        return const ErrorResult(ValidationFailure('Shop ID is required.'));
      }

      final localList = await _localDataSource.getSuppliers(
        shopId,
        includeArchived: includeArchived,
        searchQuery: searchQuery,
      );

      return Success(localList);
    } catch (e) {
      return ErrorResult(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Result<SupplierModel?, Failure>> getSupplierById(String id) async {
    try {
      final local = await _localDataSource.getSupplierById(id);
      if (local != null) {
        return Success(SupplierModel(
          id: local.id,
          shopId: local.shopId,
          name: local.name,
          contactPerson: local.contactPerson,
          phone: local.phone,
          email: local.email,
          address: local.address,
          gstin: local.gstin,
          notes: local.notes,
          currentBalancePaise: local.currentBalancePaise.toInt(),
          isArchived: local.isArchived,
          createdAt: local.createdAt,
          updatedAt: local.updatedAt,
        ));
      }

      return const Success(null);
    } catch (e) {
      return ErrorResult(ErrorHandler.handle(e));
    }
  }

  /// Record Stock Purchase Entry
  Future<Result<PurchaseModel, Failure>> recordPurchase({
    required String shopId,
    String? supplierId,
    String? supplierNameSnapshot,
    required String invoiceNumber,
    required DateTime invoiceDate,
    required List<
            ({
              String productId,
              String productName,
              double quantity,
              int purchasePricePaise,
              double taxRate
            })>
        lineItems,
  }) async {
    try {
      if (lineItems.isEmpty) {
        return const ErrorResult(ValidationFailure(
            'Please add at least one product line item to purchase'));
      }

      final now = DateTime.now();
      final purchaseId =
          'pur_${now.millisecondsSinceEpoch}_${_uuid.v4().substring(0, 4)}';
      final opId = _uuid.v4();

      int subtotalPaise = 0;
      int taxTotalPaise = 0;

      final List<PurchaseItemsTableCompanion> itemCompanions = [];
      final List<Map<String, dynamic>> itemPayloads = [];
      final List<({String productId, double qtyAdded})> stockUpdates = [];
      final List<InventoryMovementsTableCompanion> movements = [];
      final List<PurchaseItemModel> itemModels = [];

      for (final item in lineItems) {
        final itemId = 'pur_item_${_uuid.v4().substring(0, 8)}';
        final itemSubtotalPaise =
            (item.quantity * item.purchasePricePaise).round();
        final itemTaxPaise =
            (itemSubtotalPaise * (item.taxRate / 100.0)).round();
        final itemTotalPaise = itemSubtotalPaise + itemTaxPaise;

        subtotalPaise += itemSubtotalPaise;
        taxTotalPaise += itemTaxPaise;

        itemCompanions.add(PurchaseItemsTableCompanion.insert(
          id: itemId,
          purchaseId: purchaseId,
          productId: item.productId,
          quantity: item.quantity,
          purchasePricePaise: BigInt.from(item.purchasePricePaise),
          taxRate: item.taxRate,
          totalPaise: BigInt.from(itemTotalPaise),
          createdAt: Value(now),
        ));

        itemPayloads.add({
          'id': itemId,
          'purchase_id': purchaseId,
          'product_id': item.productId,
          'quantity': item.quantity,
          'purchase_price_paise': item.purchasePricePaise,
          'tax_rate': item.taxRate,
          'total_paise': itemTotalPaise,
          'created_at': now.toIso8601String(),
        });

        stockUpdates.add((productId: item.productId, qtyAdded: item.quantity));

        movements.add(InventoryMovementsTableCompanion.insert(
          id: 'inv_mov_${_uuid.v4().substring(0, 8)}',
          shopId: shopId,
          productId: item.productId,
          quantityDelta: item.quantity,
          balanceAfter: 0.0,
          reason: 'purchase_inward',
          performedBy: shopId,
          referenceId: Value(purchaseId),
          notes:
              Value('Inward stock purchase invoice #${invoiceNumber.trim()}'),
          createdAt: Value(now),
        ));

        itemModels.add(PurchaseItemModel(
          id: itemId,
          purchaseId: purchaseId,
          productId: item.productId,
          productName: item.productName,
          quantity: item.quantity,
          purchasePricePaise: item.purchasePricePaise,
          taxRate: item.taxRate,
          totalPaise: itemTotalPaise,
          createdAt: now,
        ));
      }

      final totalPaise = subtotalPaise + taxTotalPaise;

      final purchaseCompanion = PurchasesTableCompanion.insert(
        id: purchaseId,
        shopId: shopId,
        supplierId: Value(supplierId),
        invoiceNumber: invoiceNumber.trim(),
        invoiceDate: invoiceDate,
        subtotalPaise: BigInt.from(subtotalPaise),
        taxTotalPaise: BigInt.from(taxTotalPaise),
        totalPaise: BigInt.from(totalPaise),
        status: 'completed',
        supplierNameSnapshot: Value(supplierNameSnapshot?.trim()),
        createdAt: Value(now),
      );

      final purchasePayload = {
        'id': purchaseId,
        'shop_id': shopId,
        'supplier_id': supplierId,
        'invoice_number': invoiceNumber.trim(),
        'invoice_date': invoiceDate.toIso8601String(),
        'subtotal_paise': subtotalPaise,
        'tax_total_paise': taxTotalPaise,
        'total_paise': totalPaise,
        'status': 'completed',
        'supplier_name_snapshot': supplierNameSnapshot?.trim(),
        'created_at': now.toIso8601String(),
      };

      final syncOp = SyncQueueTableCompanion(
        operationId: Value(opId),
        shopId: Value(shopId),
        entityType: const Value('purchase'),
        entityId: Value(purchaseId),
        operationType: const Value('CREATE'),
        payload: Value(jsonEncode(purchasePayload)),
        createdAt: Value(now),
        status: const Value('PENDING'),
      );

      await _localDataSource.recordPurchaseTransaction(
        purchase: purchaseCompanion,
        items: itemCompanions,
        movements: movements,
        stockUpdates: stockUpdates,
        syncOp: syncOp,
        supplierId: supplierId,
        totalPaise: totalPaise,
      );

      try {
        await _remoteDataSource.pushPurchase(
          purchasePayload: purchasePayload,
          itemPayloads: itemPayloads,
          supplierId: supplierId,
          totalPaise: totalPaise,
        );
      } catch (_) {}

      final model = PurchaseModel(
        id: purchaseId,
        shopId: shopId,
        supplierId: supplierId,
        supplierNameSnapshot: supplierNameSnapshot,
        invoiceNumber: invoiceNumber.trim(),
        invoiceDate: invoiceDate,
        subtotalPaise: subtotalPaise,
        taxTotalPaise: taxTotalPaise,
        totalPaise: totalPaise,
        status: 'completed',
        items: itemModels,
        createdAt: now,
      );

      return Success(model);
    } catch (e) {
      return ErrorResult(ErrorHandler.handle(e));
    }
  }

  /// Record Payment Made to Supplier (Settlement)
  Future<Result<void, Failure>> recordSupplierPayment({
    required String supplierId,
    required String shopId,
    required int amountPaise,
    String? paymentMethod,
    String? notes,
  }) async {
    try {
      if (amountPaise <= 0) {
        return const ErrorResult(
            ValidationFailure('Please enter a valid amount greater than zero'));
      }

      final now = DateTime.now();
      final opId = _uuid.v4();

      final payload = {
        'supplier_id': supplierId,
        'shop_id': shopId,
        'amount_paise': amountPaise,
        'payment_method': paymentMethod ?? 'Cash',
        'notes': notes,
        'created_at': now.toIso8601String(),
      };

      final syncOp = SyncQueueTableCompanion(
        operationId: Value(opId),
        shopId: Value(shopId),
        entityType: const Value('supplier_payment'),
        entityId: Value(supplierId),
        operationType: const Value('CREATE'),
        payload: Value(jsonEncode(payload)),
        createdAt: Value(now),
        status: const Value('PENDING'),
      );

      await _localDataSource.recordSupplierPayment(
        supplierId: supplierId,
        amountPaise: amountPaise,
        syncOp: syncOp,
      );

      try {
        await _remoteDataSource.pushSupplierPayment(
          supplierId: supplierId,
          amountPaise: amountPaise,
        );
      } catch (_) {}

      return const Success(null);
    } catch (e) {
      return ErrorResult(ErrorHandler.handle(e));
    }
  }
}
