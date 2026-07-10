import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../domain/repositories/lyrics_repository.dart';
import '../../data/datasources/lyrics_remote_data_source.dart';
import '../../data/repositories/lyrics_repository_impl.dart';
import '../../domain/entities/lyrics.dart';

/// Provider for the remote lyrics data source.
final lyricsRemoteDataSourceProvider = Provider<LyricsRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return LyricsRemoteDataSourceImpl(apiClient);
});

/// Provider for the lyrics repository.
final lyricsRepositoryProvider = Provider<LyricsRepository>((ref) {
  final remoteDataSource = ref.watch(lyricsRemoteDataSourceProvider);
  return LyricsRepositoryImpl(remoteDataSource);
});

/// Parameter object used for fetching lyrics.
class LyricsQueryParams {
  final String track;
  final String? artist;

  const LyricsQueryParams({required this.track, this.artist});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LyricsQueryParams &&
          runtimeType == other.runtimeType &&
          track == other.track &&
          artist == other.artist;

  @override
  int get hashCode => track.hashCode ^ artist.hashCode;
}

/// Future provider family that retrieves lyrics for a track name and artist.
final lyricsProvider = FutureProvider.family<Lyrics, LyricsQueryParams>((ref, params) async {
  if (params.track.trim().isEmpty) {
    return const Lyrics(lines: []);
  }
  final repository = ref.watch(lyricsRepositoryProvider);
  return repository.getLyrics(track: params.track, artist: params.artist);
});
