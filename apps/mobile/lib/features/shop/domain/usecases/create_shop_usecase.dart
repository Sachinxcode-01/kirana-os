import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../models/shop_model.dart';
import '../repositories/shop_repository.dart';

class CreateShopUseCase {
  final ShopRepository _repository;

  const CreateShopUseCase(this._repository);

  Future<Result<ShopModel, Failure>> execute({
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
    final cleanName = name.trim();
    final cleanPhone = phone.trim();

    if (cleanName.isEmpty) {
      return const ErrorResult(ValidationFailure('Shop name is required'));
    }

    if (cleanPhone.length < 10) {
      return const ErrorResult(
          ValidationFailure('Valid 10-digit phone number is required'));
    }

    if (pincode != null && pincode.trim().isNotEmpty) {
      final cleanPincode = pincode.trim();
      if (cleanPincode.length != 6 || int.tryParse(cleanPincode) == null) {
        return const ErrorResult(
            ValidationFailure('Pincode must be a 6-digit number'));
      }
    }

    if (gstin != null && gstin.trim().isNotEmpty) {
      final cleanGstin = gstin.trim().toUpperCase();
      if (cleanGstin.length != 15) {
        return const ErrorResult(
            ValidationFailure('GSTIN must be 15 characters long'));
      }
    }

    return await _repository.createShop(
      name: cleanName,
      phone: cleanPhone,
      address: address?.trim(),
      city: city?.trim(),
      state: state?.trim() ?? 'Karnataka',
      pincode: pincode?.trim(),
      gstin: gstin?.trim().toUpperCase(),
      fssaiLicense: fssaiLicense?.trim(),
      upiId: upiId?.trim(),
      logoUrl: logoUrl,
    );
  }
}
