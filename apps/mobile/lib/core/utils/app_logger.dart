import 'dart:developer' as developer;

enum LogLevel { debug, info, warning, error }

/// Production-ready structured logger with automatic sanitization of sensitive tokens and passwords.
abstract final class AppLogger {
  static bool enableDebugLogs = true;

  static void d(String message,
      {String tag = 'KiranaOS', Object? error, StackTrace? stackTrace}) {
    if (!enableDebugLogs) return;
    _log(LogLevel.debug, tag, message, error, stackTrace);
  }

  static void i(String message, {String tag = 'KiranaOS'}) {
    _log(LogLevel.info, tag, message, null, null);
  }

  static void w(String message,
      {String tag = 'KiranaOS', Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.warning, tag, message, error, stackTrace);
  }

  static void e(String message,
      {String tag = 'KiranaOS', Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, tag, message, error, stackTrace);
  }

  static void _log(
    LogLevel level,
    String tag,
    String message,
    Object? error,
    StackTrace? stackTrace,
  ) {
    final sanitizedMessage = _sanitize(message);
    final prefix = switch (level) {
      LogLevel.debug => '🔍 [DEBUG]',
      LogLevel.info => 'ℹ️ [INFO]',
      LogLevel.warning => '⚠️ [WARN]',
      LogLevel.error => '🛑 [ERROR]',
    };

    developer.log(
      '$prefix [$tag] $sanitizedMessage',
      name: tag,
      error: error != null ? _sanitize(error.toString()) : null,
      stackTrace: stackTrace,
      level: switch (level) {
        LogLevel.debug => 500,
        LogLevel.info => 800,
        LogLevel.warning => 900,
        LogLevel.error => 1000,
      },
    );
  }

  /// Sanitizes sensitive patterns (tokens, passwords, PINs, auth headers)
  static String _sanitize(String input) {
    var result = input;
    // Mask Bearer tokens
    result = result.replaceAllMapped(
      RegExp(r'Bearer\s+[A-Za-z0-9\-\._~\+\/]+=*', caseSensitive: false),
      (match) => 'Bearer [REDACTED_TOKEN]',
    );
    // Mask password or pin values in JSON or key-value pairs
    result = result.replaceAllMapped(
      RegExp(
          r'("?(?:password|pin|secret|service_role|pin_hash)"?\s*[:=]\s*)"?([^",\s}]+)"?',
          caseSensitive: false),
      (match) => '${match.group(1)}"[REDACTED]"',
    );
    return result;
  }
}
