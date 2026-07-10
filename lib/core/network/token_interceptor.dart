import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';
import '../services/logger_service.dart';

/// Intercepts outgoing requests to inject the Authorization Bearer Token.
/// Automatically handles token refreshing on 401 Unauthorized responses.
class TokenInterceptor extends Interceptor {
  final SecureStorageService _secureStorage;
  final Dio _refreshDio; // Secondary Dio client to perform refresh requests to avoid infinite loops

  TokenInterceptor(
    this._secureStorage,
    this._refreshDio,
  );

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // If the endpoint does not require authentication (e.g. login/register), skip token injection
    if (options.extra['requiresAuth'] == false) {
      return handler.next(options);
    }

    try {
      final String? token = await _secureStorage.read(SecureStorageKeys.accessToken);
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (e, stackTrace) {
      AppLogger.e('Failed to read access token from secure storage', e, stackTrace);
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    // If the server returns a 401 and the request required auth, try to refresh the token
    if (err.response?.statusCode == 401 &&
        err.requestOptions.extra['requiresAuth'] != false) {
      
      AppLogger.w('Token expired (401), attempting token refresh...');
      
      final bool refreshSuccess = await _attemptTokenRefresh();
      
      if (refreshSuccess) {
        AppLogger.i('Token refresh succeeded, retrying original request...');
        try {
          // Re-inject token into the request options
          final String? token = await _secureStorage.read(SecureStorageKeys.accessToken);
          if (token != null) {
            err.requestOptions.headers['Authorization'] = 'Bearer $token';
          }
          
          // Re-send the request using a clean fetch
          final Response<dynamic> response = await _refreshDio.fetch(err.requestOptions);
          return handler.resolve(response);
        } catch (retryError) {
          AppLogger.e('Retrying failed request after token refresh failed', retryError);
          return handler.next(err);
        }
      } else {
        AppLogger.w('Token refresh failed. Directing to re-authenticate.');
        // Here you would trigger logout / navigation to login screen
      }
    }
    
    return handler.next(err);
  }

  Future<bool> _attemptTokenRefresh() async {
    try {
      final String? refreshToken = await _secureStorage.read(SecureStorageKeys.refreshToken);
      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }

      // Execute refresh request
      final Response<dynamic> response = await _refreshDio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(extra: {'requiresAuth': false}), // Skip token injection for the refresh endpoint itself
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        final String newAccessToken = data['accessToken'] as String;
        final String? newRefreshToken = data['refreshToken'] as String?;

        // Save new tokens
        await _secureStorage.write(SecureStorageKeys.accessToken, newAccessToken);
        if (newRefreshToken != null) {
          await _secureStorage.write(SecureStorageKeys.refreshToken, newRefreshToken);
        }
        
        return true;
      }
    } catch (e, stackTrace) {
      AppLogger.e('Exception thrown during token refresh request', e, stackTrace);
    }
    return false;
  }
}
