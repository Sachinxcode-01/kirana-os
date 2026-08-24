/// Global constants for the KiranaOS POS platform.
abstract final class AppConstants {
  static const String appName = 'KiranaOS';
  static const String appVersion = '1.0.0';
  static const String defaultCurrencySymbol = '₹';
  static const String defaultCurrencyCode = 'INR';
  static const int defaultPaisePerRupee = 100;

  // POS Operational Limits
  static const int maxCartItems = 500;
  static const int defaultCreditLimitPaise = 500000; // ₹5,000.00
  static const int maxDiscountPercentage = 50;
  static const int quickPinLength = 4;
  static const int posAutoLockTimeoutSeconds = 120;

  // Sync Configuration
  static const int syncBatchSize = 25;
  static const int syncMaxRetries = 5;
  static const Duration syncInitialBackoff = Duration(seconds: 2);
  static const Duration syncMaxBackoff = Duration(seconds: 60);

  // Storage Keys
  static const String keyAuthToken = 'kirana_auth_token';
  static const String keyRefreshToken = 'kirana_refresh_token';
  static const String keyActiveShopId = 'kirana_active_shop_id';
  static const String keyQuickPinHash = 'kirana_quick_pin_hash';
  static const String keySelectedPrinterMac = 'kirana_printer_mac';
}
