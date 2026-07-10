import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../domain/repositories/playlist_repository.dart';
import '../../data/datasources/playlist_remote_data_source.dart';
import '../../data/repositories/playlist_repository_impl.dart';
import '../../domain/entities/imported_playlist.dart';
import '../../data/models/imported_playlist_model.dart';
import '../../data/models/imported_playlist_track_model.dart';

/// Provider for the remote playlist data source.
final playlistRemoteDataSourceProvider = Provider<PlaylistRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PlaylistRemoteDataSourceImpl(apiClient);
});

/// Provider for the playlist repository.
final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  final remoteDataSource = ref.watch(playlistRemoteDataSourceProvider);
  return PlaylistRepositoryImpl(remoteDataSource);
});

/// Cache class for successfully imported playlists so they are readable by ID.
class ImportedPlaylistsCache extends Notifier<Map<String, ImportedPlaylist>> {
  static const _storageKey = 'imported_playlists_v1';

  @override
  Map<String, ImportedPlaylist> build() {
    try {
      final prefs = ref.watch(sharedPreferencesProvider);
      final rawData = prefs.getString(_storageKey);
      if (rawData != null && rawData.isNotEmpty) {
        final decoded = json.decode(rawData) as Map<String, dynamic>;
        return decoded.map((key, value) {
          final playlistModel = ImportedPlaylistModel.fromJson(value as Map<String, dynamic>);
          return MapEntry(key, playlistModel);
        });
      }
    } catch (_) {
      // Fallback on error or empty storage
    }
    return {};
  }

  void updatePlaylist(ImportedPlaylist playlist) {
    state = {
      ...state,
      playlist.id: playlist,
    };
    _saveToPrefs();
  }

  void deletePlaylist(String id) {
    final newState = Map<String, ImportedPlaylist>.from(state)..remove(id);
    state = newState;
    _saveToPrefs();
  }

  void _saveToPrefs() {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final serialized = state.map((key, value) {
        final model = ImportedPlaylistModel(
          id: value.id,
          title: value.title,
          owner: value.owner,
          tracks: value.tracks.map((t) => ImportedPlaylistTrackModel(
            id: t.id,
            title: t.title,
            author: t.author,
            thumbnail: t.thumbnail,
          )).toList(),
        );
        return MapEntry(key, model.toJson());
      });
      prefs.setString(_storageKey, json.encode(serialized));
    } catch (_) {
      // Ignore write errors
    }
  }
}

/// Cache provider for successfully imported playlists so they are readable by ID.
final importedPlaylistsCacheProvider = NotifierProvider<ImportedPlaylistsCache, Map<String, ImportedPlaylist>>(
  ImportedPlaylistsCache.new,
);

/// Future provider family for importing an external playlist by URL.
final importPlaylistProvider = FutureProvider.family<ImportedPlaylist, String>((ref, url) async {
  if (url.trim().isEmpty) {
    throw ArgumentError('URL cannot be empty.');
  }
  final repository = ref.watch(playlistRepositoryProvider);
  final playlist = await repository.importPlaylist(url);
  
  // Cache and save it
  ref.read(importedPlaylistsCacheProvider.notifier).updatePlaylist(playlist);
  
  return playlist;
});
