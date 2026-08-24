/// Base class for all handled low-level exceptions in KiranaOS.
class AppException implements Exception {
  final String message;
  final String? code;
  final StackTrace? stackTrace;

  const AppException(this.message, {this.code, this.stackTrace});

  @override
  String toString() => '$runtimeType(message: $message, code: $code)';
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.stackTrace});
}

class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.code, super.stackTrace});
}

class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.stackTrace});
}

class ValidationException extends AppException {
  const ValidationException(super.message, {super.code, super.stackTrace});
}

class HardwareException extends AppException {
  const HardwareException(super.message, {super.code, super.stackTrace});
}
