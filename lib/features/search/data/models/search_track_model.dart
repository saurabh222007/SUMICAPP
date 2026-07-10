import '../../domain/entities/search_track.dart';

/// Data layer model of a search track result mapping directly from the REST API payload.
class SearchTrackModel extends SearchTrack {
  const SearchTrackModel({
    required super.id,
    required super.title,
    required super.author,
    required super.duration,
    required super.thumbnail,
  });

  factory SearchTrackModel.fromJson(Map<String, dynamic> json) {
    return SearchTrackModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Unknown Title',
      author: json['author'] as String? ?? 'Unknown Artist',
      duration: _parseDuration(json['duration']),
      thumbnail: json['thumbnail'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'duration': duration,
      'thumbnail': thumbnail,
    };
  }

  /// Handles duration coming as int (seconds from Piped/Invidious) or String ("3:12" from scraping)
  static String _parseDuration(dynamic value) {
    if (value == null) return '0:00';
    if (value is String) return value.isEmpty ? '0:00' : value;
    if (value is int || value is double) {
      final totalSeconds = (value as num).toInt();
      final minutes = totalSeconds ~/ 60;
      final seconds = totalSeconds % 60;
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
    return value.toString();
  }
}
