import '../../domain/entities/imported_playlist.dart';
import 'imported_playlist_track_model.dart';

/// Data layer model of an imported playlist.
class ImportedPlaylistModel extends ImportedPlaylist {
  const ImportedPlaylistModel({
    required super.id,
    required super.title,
    required super.owner,
    required List<ImportedPlaylistTrackModel> super.tracks,
  });

  factory ImportedPlaylistModel.fromJson(Map<String, dynamic> json) {
    final rawPlaylist = json['playlist'] as Map<String, dynamic>? ?? {};
    final rawTracks = rawPlaylist['tracks'] as List<dynamic>? ?? [];
    
    final tracksList = rawTracks
        .map((t) => ImportedPlaylistTrackModel.fromJson(t as Map<String, dynamic>))
        .toList();

    return ImportedPlaylistModel(
      id: rawPlaylist['id'] as String? ?? '',
      title: rawPlaylist['title'] as String? ?? 'Imported Playlist',
      owner: rawPlaylist['owner'] as String? ?? 'Spotify',
      tracks: tracksList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playlist': {
        'id': id,
        'title': title,
        'owner': owner,
        'tracks': tracks.map((t) => (t as ImportedPlaylistTrackModel).toJson()).toList(),
      }
    };
  }
}
