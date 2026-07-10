import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';
import '../network/api_config.dart';
import '../storage/secure_storage_service.dart';
import '../storage/shared_prefs_service.dart';

/// Provider for SharedPreferences. Must be overridden in the ProviderScope at bootstrap.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider is not initialized. Ensure it is overridden at bootstrap.');
});

/// Provider for the general SharedPreferences service.
final sharedPrefsServiceProvider = Provider<SharedPrefsService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SharedPrefsService(prefs);
});

/// Provider for the encrypted secure storage service.
final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return const SecureStorageService();
});

/// Provider for the backend REST API Client.
final apiClientProvider = Provider<ApiClient>((ref) {
  final secureStorage = ref.watch(secureStorageServiceProvider);
  
  // Environment configurations (Can be loaded from .env variables dynamically)
  const String baseUrl = ApiConfig.baseUrl;
  
  const int connectTimeoutMs = int.fromEnvironment(
    'API_CONNECT_TIMEOUT',
    defaultValue: 30000,
  );
  
  const int receiveTimeoutMs = int.fromEnvironment(
    'API_RECEIVE_TIMEOUT',
    defaultValue: 30000,
  );

  return ApiClient(
    baseUrl: baseUrl,
    connectTimeout: const Duration(milliseconds: connectTimeoutMs),
    receiveTimeout: const Duration(milliseconds: receiveTimeoutMs),
    secureStorage: secureStorage,
  );
});
