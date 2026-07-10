import '../../domain/entities/lyrics.dart';
import '../../domain/repositories/lyrics_repository.dart';
import '../datasources/lyrics_remote_data_source.dart';

/// Implementation of the LyricsRepository.
class LyricsRepositoryImpl implements LyricsRepository {
  final LyricsRemoteDataSource _remoteDataSource;

  LyricsRepositoryImpl(this._remoteDataSource);

  @override
  Future<Lyrics> getLyrics({required String track, String? artist}) async {
    return await _remoteDataSource.getLyrics(track: track, artist: artist);
  }
}
