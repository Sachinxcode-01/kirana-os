import 'package:uuid/uuid.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/network/connectivity_status.dart';
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

      // Check Duplicate Supplier within Shop
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
      final supplier = SupplierModel(
        id: 'supp_${now.millisecondsSinceEpoch}_${_uuid.v4().substring(0, 6)}',
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

      SupplierModel savedSupplier = supplier;

      if (_connectivityService.currentStatus != ConnectivityStatus.offline) {
        try {
          savedSupplier = await _remoteDataSource.insertSupplier(supplier);
        } catch (e) {
          // Keep local fallback if remote insert fails on offline dev
        }
      }

      await _localDataSource.saveSupplier(savedSupplier);
      return Success(savedSupplier);
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

      if (!SupplierModel.isValidEmail(supplier.email)) {
        return const ErrorResult(
          ValidationFailure('Enter a valid email address.'),
        );
      }

      if (!SupplierModel.isValidGstin(supplier.gstin)) {
        return const ErrorResult(
          ValidationFailure('GSTIN must be 15 characters long.'),
        );
      }

      final updated = supplier.copyWith(updatedAt: DateTime.now());
      SupplierModel saved = updated;

      if (_connectivityService.currentStatus != ConnectivityStatus.offline) {
        try {
          saved = await _remoteDataSource.updateSupplier(updated);
        } catch (_) {}
      }

      await _localDataSource.saveSupplier(saved);
      return Success(saved);
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

      final archived = existing.copyWith(
        isArchived: true,
        updatedAt: DateTime.now(),
      );

      SupplierModel saved = archived;
      if (_connectivityService.currentStatus != ConnectivityStatus.offline) {
        try {
          saved = await _remoteDataSource.archiveSupplier(shopId, supplierId);
        } catch (_) {}
      }

      await _localDataSource.saveSupplier(saved);
      return Success(saved);
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

      if (_connectivityService.currentStatus != ConnectivityStatus.offline) {
        try {
          final remoteList = await _remoteDataSource.fetchSuppliers(
            shopId,
            includeArchived: includeArchived,
            searchQuery: searchQuery,
            limit: limit,
            offset: offset,
          );
          await _localDataSource.saveSuppliers(remoteList);
        } catch (_) {}
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
      if (local != null) return Success(local);

      if (_connectivityService.currentStatus != ConnectivityStatus.offline) {
        try {
          final remote = await _remoteDataSource.fetchSupplierById(id);
          if (remote != null) {
            await _localDataSource.saveSupplier(remote);
            return Success(remote);
          }
        } catch (_) {}
      }

      return const Success(null);
    } catch (e) {
      return ErrorResult(ErrorHandler.handle(e));
    }
  }
}
