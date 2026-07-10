/// Base class representing exceptions thrown within the application.
abstract class AppException implements Exception {
  final String message;
  final String? code;

  const AppException({required this.message, this.code});

  @override
  String toString() => '$runtimeType: $message${code != null ? " (Code: $code)" : ""}';
}

/// Thrown during network operations.
class ApiException extends AppException {
  final int? statusCode;

  const ApiException({
    required super.message,
    super.code,
    this.statusCode,
  });
}

/// Thrown during device local storage operations (SharedPreferences, SecureStorage).
class StorageException extends AppException {
  const StorageException({required super.message, super.code});
}

/// Thrown during caching operations (image caching, database local cache).
class CacheException extends AppException {
  const CacheException({required super.message, super.code});
}

/// Thrown during authentication operations.
class AuthException extends AppException {
  const AuthException({required super.message, super.code});
}

/// Thrown when an unexpected or general error occurs.
class UnknownException extends AppException {
  const UnknownException({required super.message, super.code});
}
