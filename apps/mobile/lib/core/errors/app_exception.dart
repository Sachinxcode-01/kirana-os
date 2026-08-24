/// Base exception for KiranaOS errors.
sealed class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const AppException([this.message = '', this.code, this.details]);

  @override
  String toString() => '$runtimeType: $message (code: $code)';
}

final class NetworkException extends AppException {
  const NetworkException(
      [super.message = 'Network connection failed', super.code]);
}

final class DatabaseException extends AppException {
  const DatabaseException(
      [super.message = 'Database operation failed', super.code, super.details]);
}

final class AuthException extends AppException {
  const AuthException([super.message = 'Authentication error', super.code]);
}

final class ValidationException extends AppException {
  const ValidationException([super.message = 'Validation failed', super.code]);
}

final class StorageException extends AppException {
  const StorageException(
      [super.message = 'Storage operation failed', super.code, super.details]);
}

final class HardwareException extends AppException {
  const HardwareException(
      [super.message = 'Hardware communication error', super.code]);
}

final class SyncException extends AppException {
  const SyncException(
      [super.message = 'Sync operation failed', super.code, super.details]);
}
