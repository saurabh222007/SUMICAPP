import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/logger_service.dart';
import '../errors/app_exception.dart';

/// Standardized keys for local secure storage values.
abstract class SecureStorageKeys {
  static const String accessToken = 'sumic_access_token';
  static const String refreshToken = 'sumic_refresh_token';
  static const String userId = 'sumic_user_id';
}

/// Service that handles secure, encrypted key-value storage.
/// Suitable for authentication tokens and user credentials.
class SecureStorageService {
  final FlutterSecureStorage _storage;

  const SecureStorageService([
    this._storage = const FlutterSecureStorage(),
  ]);

  /// Writes a value to secure storage.
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e, stackTrace) {
      AppLogger.e('Secure storage write failed for key: $key', e, stackTrace);
      throw const StorageException(message: 'Failed to write encrypted data to storage.');
    }
  }

  /// Reads a value from secure storage.
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e, stackTrace) {
      AppLogger.e('Secure storage read failed for key: $key', e, stackTrace);
      throw const StorageException(message: 'Failed to read encrypted data from storage.');
    }
  }

  /// Deletes a value from secure storage.
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e, stackTrace) {
      AppLogger.e('Secure storage delete failed for key: $key', e, stackTrace);
      throw const StorageException(message: 'Failed to delete encrypted data from storage.');
    }
  }

  /// Clears all keys from secure storage.
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e, stackTrace) {
      AppLogger.e('Secure storage clear failed', e, stackTrace);
      throw const StorageException(message: 'Failed to clear secure storage.');
    }
  }
}
