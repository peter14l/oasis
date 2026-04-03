/// Base exception class for all application-level errors.
///
/// All domain and data layer exceptions should extend this class
/// to provide a unified error handling strategy.
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final StackTrace? stackTrace;

  const AppException(this.message, {this.code, this.stackTrace});

  @override
  String toString() {
    final buffer = StringBuffer('AppException');
    if (code != null) buffer.write(' [$code]');
    buffer.write(': $message');
    if (stackTrace != null) buffer.write('\n$stackTrace');
    return buffer.toString();
  }
}

/// Network-related errors (API failures, timeouts, connectivity issues).
class NetworkException extends AppException {
  final int? statusCode;

  const NetworkException(
    super.message, {
    this.statusCode,
    super.code,
    super.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer('NetworkException');
    if (statusCode != null) buffer.write(' (HTTP $statusCode)');
    if (code != null) buffer.write(' [$code]');
    buffer.write(': $message');
    return buffer.toString();
  }
}

/// Storage-related errors (local storage, cache, file system failures).
class StorageException extends AppException {
  const StorageException(super.message, {super.code, super.stackTrace});
}

/// Validation errors (invalid input, malformed data).
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  const ValidationException(
    super.message, {
    this.fieldErrors,
    super.code,
    super.stackTrace,
  });
}

/// Authentication errors (expired sessions, invalid credentials).
class AuthenticationException extends AppException {
  const AuthenticationException(super.message, {super.code, super.stackTrace});
}
