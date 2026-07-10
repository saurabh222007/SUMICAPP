import '../../domain/entities/imported_playlist.dart';
import '../../domain/repositories/playlist_repository.dart';
import '../datasources/playlist_remote_data_source.dart';

/// Implementation of the PlaylistRepository.
class PlaylistRepositoryImpl implements PlaylistRepository {
  final PlaylistRemoteDataSource _remoteDataSource;

  PlaylistRepositoryImpl(this._remoteDataSource);

  @override
  Future<ImportedPlaylist> importPlaylist(String url) async {
    return await _remoteDataSource.importPlaylist(url);
  }
}
