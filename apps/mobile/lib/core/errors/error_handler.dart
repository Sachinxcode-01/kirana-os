import 'app_exception.dart';
import 'failure.dart';

/// Maps raw exceptions and database/network errors to domain [Failure] instances.
abstract final class ErrorHandler {
  static Failure handleException(dynamic exception, [StackTrace? stackTrace]) {
    if (exception is Failure) return exception;

    if (exception is NetworkException) {
      return NetworkFailure(exception.message, code: exception.code);
    }
    if (exception is DatabaseException) {
      return DatabaseFailure(exception.message, code: exception.code);
    }
    if (exception is AuthException) {
      return AuthFailure(exception.message, code: exception.code);
    }
    if (exception is ValidationException) {
      return ValidationFailure(exception.message, code: exception.code);
    }
    if (exception is StorageException) {
      return StorageFailure(exception.message, code: exception.code);
    }
    if (exception is HardwareException) {
      return HardwareFailure(exception.message, code: exception.code);
    }
    if (exception is SyncException) {
      return SyncFailure(exception.message, code: exception.code);
    }

    final str = exception.toString();
    if (str.contains('SocketException') ||
        str.contains('TimeoutException') ||
        str.contains('ClientException')) {
      return const NetworkFailure(
          'Network connection unavailable. Offline mode active.');
    }
    if (str.contains('AuthException') || str.contains('invalid_credentials')) {
      return const AuthFailure('Invalid credentials or session expired.');
    }
    if (str.contains('duplicate key') || str.contains('UNIQUE constraint')) {
      return const ValidationFailure(
          'Record with this unique identifier already exists.');
    }

    return UnknownFailure(str);
  }

  /// Converts a [Failure] into a clean, actionable user-facing message.
  static String getUserMessage(Failure failure) {
    return switch (failure) {
      NetworkFailure() =>
        'Network connection unavailable. Offline mode is active.',
      DatabaseFailure() =>
        'Local storage operation failed. Please check device memory.',
      AuthFailure(:final message) => message.isNotEmpty
          ? message
          : 'Authentication failed. Please verify credentials.',
      PermissionDeniedFailure() => 'Action requires Shop Owner authorization.',
      StorageFailure(:final message) => 'Image storage error: $message',
      BarcodeNotFoundFailure(:final barcode) =>
        'Barcode "$barcode" not recognized. Tap to add item.',
      BarcodeFailure() =>
        'Unable to read barcode. Please retry scan or type code.',
      ValidationFailure(:final message) => message,
      PaymentFailure(:final message) => 'Payment error: $message',
      HardwareFailure(:final message) =>
        'Hardware error: $message. Check printer/scanner.',
      SyncFailure() =>
        'Sync in progress. Offline billing continues unaffected.',
      UnknownFailure(:final message) => message,
    };
  }
}
