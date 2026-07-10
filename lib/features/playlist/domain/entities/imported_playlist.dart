import 'imported_playlist_track.dart';

/// Domain entity representing a Spotify playlist successfully imported and matched on YouTube.
class ImportedPlaylist {
  final String id;
  final String title;
  final String owner;
  final List<ImportedPlaylistTrack> tracks;

  const ImportedPlaylist({
    required this.id,
    required this.title,
    required this.owner,
    required this.tracks,
  });
}
