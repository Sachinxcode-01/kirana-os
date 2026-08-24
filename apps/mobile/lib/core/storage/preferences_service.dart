import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// Lightweight non-sensitive key-value preferences for printer/scanner setup.
class PreferencesService {
  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  static Future<PreferencesService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferencesService(prefs);
  }

  Future<void> setSelectedPrinterMac(String mac) async {
    await _prefs.setString(AppConstants.keySelectedPrinterMac, mac);
  }

  String? getSelectedPrinterMac() {
    return _prefs.getString(AppConstants.keySelectedPrinterMac);
  }

  Future<void> setBoolean(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  bool getBoolean(String key, {bool defaultValue = false}) {
    return _prefs.getBool(key) ?? defaultValue;
  }
}
