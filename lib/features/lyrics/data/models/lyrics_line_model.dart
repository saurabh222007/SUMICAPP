import '../../domain/entities/lyrics_line.dart';

/// Data layer model of a lyrics line.
class LyricsLineModel extends LyricsLine {
  const LyricsLineModel({
    required super.time,
    required super.text,
  });

  factory LyricsLineModel.fromJson(Map<String, dynamic> json) {
    final rawTime = json['time'];
    final double? parsedTime = rawTime != null ? (rawTime as num).toDouble() : null;
    return LyricsLineModel(
      time: parsedTime,
      text: json['text'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'text': text,
    };
  }
}
