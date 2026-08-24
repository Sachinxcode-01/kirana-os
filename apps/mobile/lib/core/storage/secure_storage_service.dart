import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

/// Service managing hardware-backed encrypted storage (Android Keystore / iOS Keychain).
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  Future<void> saveAuthToken(String token) async {
    await _storage.write(key: AppConstants.keyAuthToken, value: token);
  }

  Future<String?> getAuthToken() async {
    return await _storage.read(key: AppConstants.keyAuthToken);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: AppConstants.keyRefreshToken, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: AppConstants.keyRefreshToken);
  }

  Future<void> saveActiveShopId(String shopId) async {
    await _storage.write(key: AppConstants.keyActiveShopId, value: shopId);
  }

  Future<String?> getActiveShopId() async {
    return await _storage.read(key: AppConstants.keyActiveShopId);
  }

  Future<void> saveQuickPinHash(String pinHash) async {
    await _storage.write(key: AppConstants.keyQuickPinHash, value: pinHash);
  }

  Future<String?> getQuickPinHash() async {
    return await _storage.read(key: AppConstants.keyQuickPinHash);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
