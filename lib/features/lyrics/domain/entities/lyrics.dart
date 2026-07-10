import 'lyrics_line.dart';

/// Domain entity representing the complete lyrics of a track.
class Lyrics {
  final List<LyricsLine> lines;

  const Lyrics({
    required this.lines,
  });

  /// Check if the lyrics contain timing stamps (synced lyrics).
  bool get isSynced => lines.any((line) => line.time != null);
}
