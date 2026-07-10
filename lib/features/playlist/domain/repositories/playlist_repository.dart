import '../entities/imported_playlist.dart';

/// Contract interface for Playlist/Import feature operations.
abstract class PlaylistRepository {
  /// Imports a playlist from a external link (e.g. Spotify playlist).
  Future<ImportedPlaylist> importPlaylist(String url);
}
