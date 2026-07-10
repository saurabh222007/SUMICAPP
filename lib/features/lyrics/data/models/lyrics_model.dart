import '../../domain/entities/lyrics.dart';
import 'lyrics_line_model.dart';

/// Data layer model of lyrics.
class LyricsModel extends Lyrics {
  const LyricsModel({
    required List<LyricsLineModel> super.lines,
  });

  factory LyricsModel.fromJson(Map<String, dynamic> json) {
    final rawLines = json['lines'] as List<dynamic>? ?? [];
    final linesList = rawLines
        .map((l) => LyricsLineModel.fromJson(l as Map<String, dynamic>))
        .toList();
    return LyricsModel(lines: linesList);
  }

  Map<String, dynamic> toJson() {
    return {
      'lines': lines.map((l) => (l as LyricsLineModel).toJson()).toList(),
    };
  }
}
