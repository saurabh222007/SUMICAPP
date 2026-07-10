import 'package:dio/dio.dart';
import '../services/logger_service.dart';

/// Intercepts outgoing HTTP connections to log request, response, and exception states.
class LoggingInterceptor extends Interceptor {
  // Store start times for profiling request duration
  final Map<int, DateTime> _requestTimestamps = {};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final int hash = options.hashCode;
    _requestTimestamps[hash] = DateTime.now();

    AppLogger.d(
      '🌐 [API REQUEST] --> ${options.method.toUpperCase()} ${options.uri}\n'
      'Headers: ${options.headers}\n'
      'QueryParams: ${options.queryParameters}\n'
      'Data/Body: ${options.data}',
    );
    return handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    final int hash = response.requestOptions.hashCode;
    final DateTime? startTime = _requestTimestamps.remove(hash);
    final String durationString = startTime != null
        ? '${DateTime.now().difference(startTime).inMilliseconds}ms'
        : 'unknown';

    AppLogger.i(
      '✅ [API RESPONSE] <-- ${response.statusCode} (${response.statusMessage}) in $durationString\n'
      'URI: ${response.requestOptions.uri}\n'
      'Data/Payload: ${response.data}',
    );
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final int hash = err.requestOptions.hashCode;
    _requestTimestamps.remove(hash);

    AppLogger.e(
      '❌ [API ERROR] <-- ${err.response?.statusCode} (${err.response?.statusMessage})\n'
      'URI: ${err.requestOptions.uri}\n'
      'Error Type: ${err.type}\n'
      'Error Message: ${err.message}\n'
      'Response Data: ${err.response?.data}',
      err,
      err.stackTrace,
    );
    return handler.next(err);
  }
}
