import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../staff/domain/models/staff_member_model.dart';
import '../models/shop_settings_model.dart';
import '../repositories/shop_settings_repository.dart';

class GetShopSettingsUseCase {
  final ShopSettingsRepository _repository;

  GetShopSettingsUseCase(this._repository);

  Future<Result<ShopSettingsModel, Failure>> execute(String shopId) {
    if (shopId.trim().isEmpty) {
      return Future.value(
        const ErrorResult(ValidationFailure('Shop ID is required')),
      );
    }
    return _repository.getShopSettings(shopId);
  }
}

class UpdateShopSettingsUseCase {
  final ShopSettingsRepository _repository;

  UpdateShopSettingsUseCase(this._repository);

  Future<Result<ShopSettingsModel, Failure>> execute({
    required ShopSettingsModel settings,
    required String userRole,
    required String activeShopId,
  }) async {
    // 1. RBAC authorization check
    final role = StaffRoleExtension.fromString(userRole);
    if (role != StaffRole.owner && role != StaffRole.manager) {
      return const ErrorResult(
        PermissionDeniedFailure(
          'Only Shop Owners and Managers are authorized to modify shop settings.',
        ),
      );
    }

    // 2. Shop isolation validation
    if (settings.shopId != activeShopId) {
      return const ErrorResult(
        PermissionDeniedFailure('Cannot modify settings for another shop.'),
      );
    }

    // 3. Validation checks
    if (settings.shopName.trim().isEmpty) {
      return const ErrorResult(
        ValidationFailure('Shop name is required.'),
      );
    }

    if (settings.phone.trim().length < 10) {
      return const ErrorResult(
        ValidationFailure('Valid 10-digit phone number is required.'),
      );
    }

    if (settings.defaultTaxPercentage < 0 ||
        settings.defaultTaxPercentage > 100) {
      return const ErrorResult(
        ValidationFailure('Tax percentage must be between 0% and 100%.'),
      );
    }

    if (settings.nextInvoiceNumber < 1) {
      return const ErrorResult(
        ValidationFailure('Next invoice number must be at least 1.'),
      );
    }

    if (settings.billPrefix.trim().isEmpty) {
      return const ErrorResult(
        ValidationFailure('Bill prefix is required.'),
      );
    }

    return _repository.updateShopSettings(settings);
  }
}
