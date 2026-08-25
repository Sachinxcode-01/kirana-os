enum Environment { dev, staging, prod }

/// Centralized runtime configuration container for the KiranaOS client.
class AppConfig {
  final Environment environment;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final bool enableDebugLogging;
  final int autoLockTimeoutSeconds;
  final String defaultCurrencySymbol;
  final String defaultCurrencyCode;

  const AppConfig({
    required this.environment,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    this.enableDebugLogging = false,
    this.autoLockTimeoutSeconds = 120,
    this.defaultCurrencySymbol = '₹',
    this.defaultCurrencyCode = 'INR',
  });

  bool get isProduction => environment == Environment.prod;
  bool get isDevelopment => environment == Environment.dev;

  /// Development environment preset (configured with project endpoints).
  static AppConfig dev({
    String supabaseUrl = const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://ehjijetpbnsqswlxmzjv.supabase.co',
    ),
    String supabaseAnonKey = const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: 'sb_publishable_JdqSYHkZizc6aMM_oC8x4w_f96bbOvH',
    ),
    bool enableDebugLogging = true,
  }) {
    return AppConfig(
      environment: Environment.dev,
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseAnonKey,
      enableDebugLogging: enableDebugLogging,
      autoLockTimeoutSeconds: 120,
    );
  }

  /// Staging environment preset.
  static AppConfig staging({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) {
    assert(supabaseUrl.isNotEmpty, 'supabaseUrl cannot be empty');
    assert(supabaseAnonKey.isNotEmpty, 'supabaseAnonKey cannot be empty');
    return AppConfig(
      environment: Environment.staging,
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseAnonKey,
      enableDebugLogging: true,
      autoLockTimeoutSeconds: 120,
    );
  }

  /// Production environment configuration (requires valid non-empty URLs & keys).
  static AppConfig prod({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) {
    assert(supabaseUrl.isNotEmpty, 'supabaseUrl cannot be empty in production');
    assert(supabaseAnonKey.isNotEmpty,
        'supabaseAnonKey cannot be empty in production');
    return AppConfig(
      environment: Environment.prod,
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseAnonKey,
      enableDebugLogging: false,
      autoLockTimeoutSeconds: 120,
    );
  }
}
