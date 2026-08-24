import 'app_exception.dart';
import 'failure.dart';

/// Maps raw exceptions to domain [Failure] instances.
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
    if (exception is HardwareException) {
      return HardwareFailure(exception.message, code: exception.code);
    }

    return UnknownFailure(exception.toString());
  }

  /// Converts a [Failure] into a clean, actionable user-facing message.
  static String getUserMessage(Failure failure) {
    return switch (failure) {
      NetworkFailure() => 'Network connection unavailable. Offline mode is active.',
      DatabaseFailure() => 'Local storage operation failed. Please check device memory.',
      AuthFailure() => 'Authentication failed. Please verify your credentials or PIN.',
      PermissionDeniedFailure() => 'Action requires Shop Owner authorization.',
      BarcodeNotFoundFailure(:final barcode) => 'Barcode "$barcode" not recognized. Tap to add item.',
      BarcodeFailure() => 'Unable to read barcode. Please retry scan or type code.',
      ValidationFailure(:final message) => message,
      PaymentFailure(:final message) => 'Payment error: $message',
      HardwareFailure(:final message) => 'Hardware error: $message. Check printer/scanner.',
      SyncFailure() => 'Sync in progress. Offline billing continues unaffected.',
      UnknownFailure(:final message) => message,
    };
  }
}
