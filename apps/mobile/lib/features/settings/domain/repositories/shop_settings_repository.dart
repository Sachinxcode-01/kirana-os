import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../models/shop_settings_model.dart';

abstract interface class ShopSettingsRepository {
  Future<Result<ShopSettingsModel, Failure>> getShopSettings(String shopId);

  Future<Result<ShopSettingsModel, Failure>> updateShopSettings(
    ShopSettingsModel settings,
  );
}
