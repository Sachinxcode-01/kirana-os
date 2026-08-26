import 'dart:typed_data';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../models/shop_model.dart';

abstract interface class ShopRepository {
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
  });

  Future<Result<ShopModel, Failure>> getShopDetails(String shopId);

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
  });

  Future<Result<String, Failure>> uploadShopLogo({
    required String shopId,
    required Uint8List imageBytes,
    required String fileName,
  });

  Future<Result<bool, Failure>> removeShopLogo(String shopId);
}
