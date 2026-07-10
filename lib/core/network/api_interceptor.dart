import 'package:dio/dio.dart';

/// Adds default request headers (e.g. Accept, Content-Type) to outbound connections.
class ApiInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Accept'] = 'application/json';
    options.headers['Content-Type'] = 'application/json';
    return handler.next(options);
  }
}
