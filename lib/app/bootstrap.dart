import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audio_session/audio_session.dart';
import '../core/providers/core_providers.dart';
import '../core/services/logger_service.dart';

/// Pre-launch bootstrapping routines.
/// Initializes third-party SDKs, storage, and platform bindings.
abstract class AppBootstrap {
  /// Runs startup initializations and returns a configured [ProviderContainer].
  static Future<ProviderContainer> bootstrap() async {
    try {
      // 1. Ensure Flutter binding is initialized
      WidgetsFlutterBinding.ensureInitialized();

      // 2. Pre-load SharedPreferences
      AppLogger.i('Initializing SharedPreferences...');
      final SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

      // Configure audio session for music playback (ensures audio focus and voice output)
      try {
        final session = await AudioSession.instance;
        await session.configure(const AudioSessionConfiguration.music());
        AppLogger.i('AudioSession configured for music playback.');
      } catch (audioErr) {
        AppLogger.e('Failed to configure AudioSession', audioErr);
      }

      // 3. Create the ProviderContainer with overrides
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        ],
      );

      // Perform additional pre-run configurations if needed
      AppLogger.i('SUMIC Bootstrapping complete.');
      return container;
    } catch (e, stackTrace) {
      AppLogger.e('Critical failure during SUMIC Bootstrapping', e, stackTrace);
      rethrow;
    }
  }
}
