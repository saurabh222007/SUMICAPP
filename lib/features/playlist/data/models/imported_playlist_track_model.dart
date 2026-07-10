import '../../domain/entities/imported_playlist_track.dart';

/// Data layer model of a track inside an imported playlist.
class ImportedPlaylistTrackModel extends ImportedPlaylistTrack {
  const ImportedPlaylistTrackModel({
    required super.id,
    required super.title,
    required super.author,
    required super.thumbnail,
  });

  factory ImportedPlaylistTrackModel.fromJson(Map<String, dynamic> json) {
    return ImportedPlaylistTrackModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Unknown Title',
      author: json['author'] as String? ?? 'Unknown Artist',
      thumbnail: json['thumbnail'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'thumbnail': thumbnail,
    };
  }
}
