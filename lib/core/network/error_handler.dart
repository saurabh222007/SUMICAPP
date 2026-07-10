import 'package:dio/dio.dart';
import '../errors/app_exception.dart';

/// Translates networking library specific exceptions (DioException)
/// into standard domain exceptions (AppException).
abstract class ErrorHandler {
  /// Maps a [DioException] to an [AppException].
  static AppException handle(DioException exception) {
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          message: 'Connection timed out. Please check your internet connection and try again.',
          code: 'TIMEOUT',
        );
        
      case DioExceptionType.badCertificate:
        return const ApiException(
          message: 'Security validation failed. Bad SSL certificate.',
          code: 'BAD_CERTIFICATE',
        );

      case DioExceptionType.badResponse:
        final Response<dynamic>? response = exception.response;
        final int? statusCode = response?.statusCode;
        
        String message = 'An unexpected response was received from the server.';
        String? errorCode = 'BAD_RESPONSE';

        if (response?.data != null && response!.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
          // Parse typical error formats from Node.js APIs (e.g. { error: "Message" } or { message: "Message", code: "CODE" })
          message = data['message'] as String? ?? 
                    data['error'] as String? ?? 
                    message;
          errorCode = data['code'] as String? ?? errorCode;
        }

        return ApiException(
          message: message,
          code: errorCode,
          statusCode: statusCode,
        );

      case DioExceptionType.cancel:
        return const ApiException(
          message: 'Request was cancelled.',
          code: 'CANCELLED',
        );

      case DioExceptionType.connectionError:
        return const ApiException(
          message: 'Unable to connect to the server. Please verify you are online.',
          code: 'CONNECTION_ERROR',
        );

      case DioExceptionType.unknown:
      default:
        return ApiException(
          message: exception.message ?? 'An unknown network error occurred.',
          code: 'UNKNOWN_NETWORK_ERROR',
        );
    }
  }
}
