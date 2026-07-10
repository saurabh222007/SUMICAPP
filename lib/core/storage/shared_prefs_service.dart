import 'package:shared_preferences/shared_preferences.dart';
import '../services/logger_service.dart';
import '../errors/app_exception.dart';

/// Keys for SharedPreferences values.
abstract class SharedPrefsKeys {
  static const String themeMode = 'sumic_theme_mode';
  static const String localeCode = 'sumic_locale_code';
  static const String offlineModeEnabled = 'sumic_offline_mode_enabled';
  static const String highQualityStreaming = 'sumic_high_quality_streaming';
}

/// Service that handles key-value storage using SharedPreferences.
/// Suitable for application configurations, user preferences, and simple cache markers.
class SharedPrefsService {
  final SharedPreferences _prefs;

  const SharedPrefsService(this._prefs);

  /// Saves a string value.
  Future<void> setString(String key, String value) async {
    try {
      await _prefs.setString(key, value);
    } catch (e, stackTrace) {
      AppLogger.e('SharedPrefs setString failed for key: $key', e, stackTrace);
      throw const StorageException(message: 'Failed to write preference data.');
    }
  }

  /// Retrieves a string value.
  String? getString(String key) {
    return _prefs.getString(key);
  }

  /// Saves a boolean value.
  Future<void> setBool(String key, bool value) async {
    try {
      await _prefs.setBool(key, value);
    } catch (e, stackTrace) {
      AppLogger.e('SharedPrefs setBool failed for key: $key', e, stackTrace);
      throw const StorageException(message: 'Failed to write preference data.');
    }
  }

  /// Retrieves a boolean value.
  bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  /// Saves an integer value.
  Future<void> setInt(String key, int value) async {
    try {
      await _prefs.setInt(key, value);
    } catch (e, stackTrace) {
      AppLogger.e('SharedPrefs setInt failed for key: $key', e, stackTrace);
      throw const StorageException(message: 'Failed to write preference data.');
    }
  }

  /// Retrieves an integer value.
  int? getInt(String key) {
    return _prefs.getInt(key);
  }

  /// Removes a key from storage.
  Future<void> remove(String key) async {
    try {
      await _prefs.remove(key);
    } catch (e, stackTrace) {
      AppLogger.e('SharedPrefs remove failed for key: $key', e, stackTrace);
      throw const StorageException(message: 'Failed to delete preference data.');
    }
  }

  /// Clears all stored preferences.
  Future<void> clearAll() async {
    try {
      await _prefs.clear();
    } catch (e, stackTrace) {
      AppLogger.e('SharedPrefs clear failed', e, stackTrace);
      throw const StorageException(message: 'Failed to clear preference data.');
    }
  }
}
