import 'package:dio/dio.dart';
import 'api_interceptor.dart';
import 'logging_interceptor.dart';
import 'token_interceptor.dart';
import 'error_handler.dart';
import 'retry_interceptor.dart';
import '../storage/secure_storage_service.dart';

/// Centralized networking client for performing REST API transactions.
class ApiClient {
  final Dio _dio;

  ApiClient({
    required String baseUrl,
    required Duration connectTimeout,
    required Duration receiveTimeout,
    required SecureStorageService secureStorage,
  }) : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl.endsWith('/') ? baseUrl : '$baseUrl/',
            connectTimeout: connectTimeout,
            receiveTimeout: receiveTimeout,
          ),
        ) {
    // Secondary Dio client used by TokenInterceptor for token refreshes
    // to prevent circular dependency logging or authorization injection.
    final Dio refreshDio = Dio(
      BaseOptions(
        baseUrl: baseUrl.endsWith('/') ? baseUrl : '$baseUrl/',
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
      ),
    );
    refreshDio.interceptors.addAll([
      ApiInterceptor(),
      LoggingInterceptor(),
    ]);

    // Attach Interceptors
    _dio.interceptors.addAll([
      ApiInterceptor(),
      TokenInterceptor(secureStorage, refreshDio),
      RetryInterceptor(dio: _dio),
      LoggingInterceptor(),
    ]);
  }

  String _normalizePath(String path) {
    if (path.startsWith('/')) {
      return path.substring(1);
    }
    return path;
  }

  /// Perform a GET request.
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.get<T>(
        _normalizePath(path),
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  /// Perform a POST request.
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.post<T>(
        _normalizePath(path),
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  /// Perform a PUT request.
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.put<T>(
        _normalizePath(path),
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  /// Perform a PATCH request.
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.patch<T>(
        _normalizePath(path),
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  /// Perform a DELETE request.
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete<T>(
        _normalizePath(path),
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
