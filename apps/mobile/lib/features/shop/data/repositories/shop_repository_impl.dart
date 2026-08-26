import 'dart:typed_data';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/storage/product_image_service.dart';
import '../../domain/models/shop_model.dart';
import '../../domain/repositories/shop_repository.dart';
import '../datasources/shop_local_data_source.dart';
import '../datasources/shop_remote_data_source.dart';

class ShopRepositoryImpl implements ShopRepository {
  final ShopLocalDataSource _localDataSource;
  final ShopRemoteDataSource _remoteDataSource;
  final ProductImageService _imageService;

  ShopRepositoryImpl({
    required ShopLocalDataSource localDataSource,
    required ShopRemoteDataSource remoteDataSource,
    required ProductImageService imageService,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        _imageService = imageService;

  @override
  Future<Result<ShopModel, Failure>> createShop({
    required String name,
    required String phone,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? gstin,
    String? fssaiLicense,
    String? upiId,
    String? logoUrl,
  }) async {
    if (name.trim().isEmpty) {
      return const ErrorResult(ValidationFailure('Shop name is required'));
    }
    if (phone.trim().length < 10) {
      return const ErrorResult(
          ValidationFailure('Valid 10-digit phone number is required'));
    }

    try {
      final shop = await _remoteDataSource.createShop(
        name: name,
        phone: phone,
        address: address,
        city: city,
        state: state,
        pincode: pincode,
        gstin: gstin,
        fssaiLicense: fssaiLicense,
        upiId: upiId,
        logoUrl: logoUrl,
      );

      // Cache locally
      await _localDataSource.saveShop(shop, ownerId: 'current_user');
      return Success(shop);
    } catch (e) {
      final failure = ErrorHandler.handle(e);
      if (failure is NetworkFailure ||
          e.toString().contains('connection') ||
          e.toString().contains('SocketException') ||
          e.toString().contains('offline')) {
        return const ErrorResult(
            NetworkFailure('Shop setup requires an internet connection.'));
      }
      return ErrorResult(failure);
    }
  }

  @override
  Future<Result<ShopModel, Failure>> getShopDetails(String shopId) async {
    try {
      final local = await _localDataSource.getShopById(shopId);
      if (local != null) {
        return Success(local);
      }

      final remote = await _remoteDataSource.getShopDetails(shopId);
      await _localDataSource.saveShop(remote, ownerId: 'current_user');
      return Success(remote);
    } catch (e) {
      return ErrorResult(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Result<ShopModel, Failure>> updateShopProfile({
    required String shopId,
    required String name,
    required String phone,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? gstin,
    String? fssaiLicense,
    String? upiId,
    String? receiptName,
  }) async {
    try {
      final updated = await _remoteDataSource.updateShopProfile(
        shopId: shopId,
        name: name,
        phone: phone,
        address: address,
        city: city,
        state: state,
        pincode: pincode,
        gstin: gstin,
        fssaiLicense: fssaiLicense,
        upiId: upiId,
        receiptName: receiptName,
      );

      await _localDataSource.saveShop(updated, ownerId: 'current_user');
      return Success(updated);
    } catch (e) {
      return ErrorResult(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Result<String, Failure>> uploadShopLogo({
    required String shopId,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    final validation = _imageService.validateImage(
      bytes: imageBytes,
      fileName: fileName,
    );
    if (validation.isError) {
      return ErrorResult(validation.failureOrNull!);
    }

    try {
      final url = await _remoteDataSource.uploadShopLogo(
        shopId: shopId,
        bytes: imageBytes,
        fileName: fileName,
      );

      // Update local cached shop logo
      final existing = await _localDataSource.getShopById(shopId);
      if (existing != null) {
        await _localDataSource.saveShop(
          existing.copyWith(logoUrl: url),
          ownerId: 'current_user',
        );
      }

      return Success(url);
    } catch (e) {
      return ErrorResult(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Result<bool, Failure>> removeShopLogo(String shopId) async {
    try {
      final success = await _remoteDataSource.removeShopLogo(shopId);
      final existing = await _localDataSource.getShopById(shopId);
      if (existing != null) {
        await _localDataSource.saveShop(
          existing.copyWith(logoUrl: null),
          ownerId: 'current_user',
        );
      }
      return Success(success);
    } catch (e) {
      return ErrorResult(ErrorHandler.handle(e));
    }
  }
}
