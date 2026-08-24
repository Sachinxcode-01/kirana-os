/// Base class for all domain and operational failures in KiranaOS.
sealed class Failure {
  final String message;
  final String? code;
  final dynamic details;

  const Failure(this.message, {this.code, this.details});

  @override
  String toString() => '$runtimeType(message: $message, code: $code)';
}

// Network Failures
final class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code, super.details});
}

// Database & Persistence Failures
final class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, {super.code, super.details});
}

// Authentication & Session Failures
final class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code, super.details});
}

// Authorization & Permission Failures
final class PermissionDeniedFailure extends Failure {
  const PermissionDeniedFailure(super.message, {super.code, super.details});
}

// Barcode Failures
final class BarcodeFailure extends Failure {
  const BarcodeFailure(super.message, {super.code, super.details});
}

final class BarcodeNotFoundFailure extends Failure {
  final String barcode;
  const BarcodeNotFoundFailure(this.barcode, {super.code})
      : super('Product not found for barcode: $barcode');
}

// Validation Failures
final class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code, super.details});
}

// Payment Failures
final class PaymentFailure extends Failure {
  const PaymentFailure(super.message, {super.code, super.details});
}

// Hardware & Peripheral Failures (Printers, Scanners)
final class HardwareFailure extends Failure {
  const HardwareFailure(super.message, {super.code, super.details});
}

// Sync Pipeline Failures
final class SyncFailure extends Failure {
  const SyncFailure(super.message, {super.code, super.details});
}

// Fallback Unknown Failure
final class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unexpected error occurred. Please try again.']);
}
