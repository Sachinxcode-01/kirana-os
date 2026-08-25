import 'dart:convert';
import '../../../../core/storage/preferences_service.dart';
import '../../domain/models/shop_settings_model.dart';

class ShopSettingsLocalDataSource {
  final PreferencesService? _prefs;
  final Map<String, ShopSettingsModel> _memoryCache = {};

  ShopSettingsLocalDataSource([this._prefs]);

  String _cacheKey(String shopId) => 'shop_settings_$shopId';

  Future<ShopSettingsModel?> getSettings(String shopId) async {
    if (_memoryCache.containsKey(shopId)) {
      return _memoryCache[shopId];
    }

    if (_prefs != null) {
      try {
        final jsonStr = _prefs.getString(_cacheKey(shopId));
        if (jsonStr != null && jsonStr.isNotEmpty) {
          final Map<String, dynamic> map = jsonDecode(jsonStr);
          final settings = ShopSettingsModel.fromJson(map);
          _memoryCache[shopId] = settings;
          return settings;
        }
      } catch (_) {
        // Ignore cache read failures
      }
    }
    return null;
  }

  Future<void> saveSettings(ShopSettingsModel settings) async {
    _memoryCache[settings.shopId] = settings;
    if (_prefs != null) {
      try {
        await _prefs.setString(
          _cacheKey(settings.shopId),
          jsonEncode(settings.toJson()),
        );
      } catch (_) {
        // Ignore cache write failures
      }
    }
  }
}
