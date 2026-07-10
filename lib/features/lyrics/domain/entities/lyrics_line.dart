/// Domain entity representing a single line of lyrics.
class LyricsLine {
  /// Time in seconds when the line starts. Can be null if the lyrics are plain text/unsynced.
  final double? time;
  final String text;

  const LyricsLine({
    required this.time,
    required this.text,
  });
}
