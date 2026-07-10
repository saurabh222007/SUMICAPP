/// Base representation of failures at the Domain level.
/// Presentation layers read this to display user-friendly messages.
abstract class Failure {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});

  @override
  String toString() => '$runtimeType: $message';
}

/// Represents connection timeouts, internet losses, or unreachable hosts.
class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, super.code});
}

/// Represents HTTP status code errors returned from the server (e.g. 500, 404).
class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure({
    required super.message,
    super.code,
    this.statusCode,
  });
}

/// Represents failures related to local persistence.
class StorageFailure extends Failure {
  const StorageFailure({required super.message, super.code});
}

/// Represents failures related to media/asset caching.
class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.code});
}

/// Represents authentication token expirations or unauthorized requests (401/403).
class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.code});
}

/// Represents unknown, generic, or parsing failures.
class UnknownFailure extends Failure {
  const UnknownFailure({required super.message, super.code});
}
