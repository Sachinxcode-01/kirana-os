enum Environment { dev, staging, prod }

/// Multi-environment configuration container for KiranaOS.
class AppConfig {
  final Environment environment;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final bool enableDebugLogging;

  const AppConfig({
    required this.environment,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    this.enableDebugLogging = false,
  });

  static AppConfig dev() {
    return const AppConfig(
      environment: Environment.dev,
      supabaseUrl: 'https://placeholder.supabase.co',
      supabaseAnonKey: 'placeholder-anon-key',
      enableDebugLogging: true,
    );
  }

  static AppConfig prod({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) {
    return AppConfig(
      environment: Environment.prod,
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseAnonKey,
      enableDebugLogging: false,
    );
  }
}
