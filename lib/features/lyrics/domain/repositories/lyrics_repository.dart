import '../entities/lyrics.dart';

/// Contract interface for the Lyrics feature.
abstract class LyricsRepository {
  /// Retrieves lyrics for the specified [track] and optional [artist].
  Future<Lyrics> getLyrics({required String track, String? artist});
}
