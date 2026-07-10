import 'dart:convert';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../models/imported_playlist_model.dart';

/// Data source interface for fetching/importing playlist data over the network.
abstract class PlaylistRemoteDataSource {
  Future<ImportedPlaylistModel> importPlaylist(String url);
}

/// Implementation of PlaylistRemoteDataSource.
class PlaylistRemoteDataSourceImpl implements PlaylistRemoteDataSource {
  final ApiClient _apiClient;

  PlaylistRemoteDataSourceImpl(this._apiClient);

  String? _parseSpotifyPlaylistId(String urlString) {
    final value = urlString.trim();
    if (value.startsWith('spotify:playlist:')) return value.split(':').last;
    try {
      final parsed = Uri.parse(value);
      final segments = parsed.pathSegments;
      if (parsed.host.contains('spotify') && segments.length >= 2 && segments[0] == 'playlist') {
        return segments[1];
      }
    } catch (_) {}
    return null;
  }

  Future<List<Map<String, String>>> _clientScrapeSpotifyPlaylist(String urlString) async {
    final playlistId = _parseSpotifyPlaylistId(urlString);
    if (playlistId == null) return [];

    final dio = dio_pkg.Dio();
    dio.options.headers = {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.9',
    };

    try {
      final embedUrl = 'https://open.spotify.com/embed/playlist/$playlistId';
      final response = await dio.get<String>(embedUrl);
      if (response.statusCode == 200 && response.data != null) {
        final html = response.data!;
        
        // Match __NEXT_DATA__
        final match = RegExp(r'<script id="__NEXT_DATA__" type="application/json">([\s\S]*?)</script>').firstMatch(html);
        if (match != null) {
          final jsonStr = match.group(1);
          if (jsonStr != null) {
            final decoded = jsonDecode(jsonStr);
            final List<dynamic> items =
                decoded['props']?['pageProps']?['state']?['data']?['entity']?['trackList'] ??
                decoded['props']?['pageProps']?['state']?['data']?['entity']?['items'] ??
                decoded['props']?['pageProps']?['state']?['data']?['entity']?['tracks']?['items'] ??
                [];
            
            final List<Map<String, String>> tracks = [];
            for (final t in items) {
              final title = t['title'] ?? t['name'] ?? t['track']?['name'] ?? 'Unknown';
              final artist = t['subtitle'] ?? t['artists']?[0]?['name'] ?? t['track']?['artists']?[0]?['name'] ?? '';
              if (title != 'Unknown') {
                tracks.add({
                  'title': title.toString(),
                  'artist': artist.toString(),
                });
              }
            }
            return tracks;
          }
        }
      }
    } catch (e) {
      debugPrint('Client-side Spotify page scrape failed: $e. Falling back to backend scraping.');
    }
    return [];
  }

  @override
  Future<ImportedPlaylistModel> importPlaylist(String url) async {
    try {
      // 1. Pre-scrape tracks client-side to bypass backend region blocking
      final List<Map<String, String>> tracks = await _clientScrapeSpotifyPlaylist(url);
      debugPrint('Client-side scraped ${tracks.length} tracks from Spotify.');

      // 2. Post to backend with scraped tracks if available
      final response = await _apiClient.post<dynamic>(
        '/api/import-playlist',
        data: {
          'url': url,
          'tracks': tracks.isNotEmpty ? tracks : null,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data.containsKey('error')) {
          throw Exception(data['error']);
        }
        if (data.containsKey('playlist')) {
          return ImportedPlaylistModel.fromJson(data['playlist'] as Map<String, dynamic>);
        }
        return ImportedPlaylistModel.fromJson(data);
      }
      throw Exception('Invalid playlist import response format.');
    } catch (e) {
      debugPrint('Playlist import error: $e');
      rethrow;
    }
  }
}
