import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class RetryInterceptor extends Interceptor {
  final Dio dio;
  bool _isFirstCall = true;

  RetryInterceptor({required this.dio});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_isFirstCall) {
      options.connectTimeout = const Duration(seconds: 60);
      options.receiveTimeout = const Duration(seconds: 60);
    } else {
      options.connectTimeout ??= const Duration(seconds: 15);
      options.receiveTimeout ??= const Duration(seconds: 15);
    }
    
    // Specifically for playlist import, allow a long timeout
    if (options.path.contains('import-playlist')) {
      options.connectTimeout = const Duration(seconds: 60);
      options.receiveTimeout = const Duration(seconds: 60);
    }

    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _isFirstCall = false;
    super.onResponse(response, handler);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    _isFirstCall = false;

    // Retry once if we haven't retried yet for this request
    final extra = err.requestOptions.extra;
    final isRetried = extra['isRetried'] ?? false;

    if (!isRetried && _shouldRetry(err)) {
      if (kDebugMode) {
        print('Retrying request: ${err.requestOptions.path}');
      }
      
      try {
        err.requestOptions.extra['isRetried'] = true;
        final response = await dio.fetch(err.requestOptions);
        return handler.resolve(response);
      } on DioException catch (retryErr) {
        return super.onError(retryErr, handler);
      } catch (e) {
        return super.onError(err, handler);
      }
    }

    super.onError(err, handler);
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.response?.statusCode != null && err.response!.statusCode! >= 500);
  }
}
