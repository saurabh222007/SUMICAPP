import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Representation of a song retrieved from Piped API.
class PipedSong {
  final String id;
  final String title;
  final String artist;
  final String thumbnail;
  final int durationSeconds;

  const PipedSong({
    required this.id,
    required this.title,
    required this.artist,
    required this.thumbnail,
    required this.durationSeconds,
  });

  factory PipedSong.fromJson(Map<String, dynamic> json) {
    final String rawId = json['id'] as String? ?? '';
    // Clean ID to extract raw video ID (e.g. "/watch?v=dQw4w9WgXcQ" -> "dQw4w9WgXcQ")
    String videoId = rawId;
    if (rawId.contains('v=')) {
      videoId = rawId.split('v=').last;
    } else {
      videoId = rawId.replaceAll('/', '');
    }

    return PipedSong(
      id: videoId,
      title: json['title'] as String? ?? json['name'] as String? ?? 'Unknown Title',
      artist: json['uploaderName'] as String? ?? json['uploader'] as String? ?? 'Unknown Artist',
      thumbnail: json['thumbnail'] as String? ?? '',
      durationSeconds: json['duration'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'thumbnail': thumbnail,
      'durationSeconds': durationSeconds,
    };
  }
}

/// Service class interfacing with Piped public API instances with failover support.
class PipedService {
  static const String _primaryUrl = 'https://pipedapi.kavin.rocks';
  static const String _fallbackUrl = 'https://pipedapi.smnz.de';

  /// Searches for a song by query on Piped API.
  /// Automatically switches to the fallback instance if the primary fails.
  Future<PipedSong?> searchSong(String query) async {
    final String encodedQuery = Uri.encodeComponent(query);
    final String path = '/search?q=$encodedQuery&filter=music_songs';

    try {
      debugPrint('[PipedService] Searching primary: $_primaryUrl$path');
      final song = await _executeSearch('$_primaryUrl$path');
      if (song != null) return song;
    } catch (e) {
      debugPrint('[PipedService] Primary search failed: $e. Trying fallback...');
    }

    try {
      debugPrint('[PipedService] Searching fallback: $_fallbackUrl$path');
      return await _executeSearch('$_fallbackUrl$path');
    } catch (e) {
      debugPrint('[PipedService] Fallback search failed: $e');
      rethrow;
    }
  }

  /// Fetches the direct audio stream URL for a given Piped song/video ID.
  /// Automatically switches to the fallback instance if the primary fails.
  Future<String?> fetchAudioStream(String videoId) async {
    final String path = '/streams/$videoId';

    try {
      debugPrint('[PipedService] Streaming from primary: $_primaryUrl$path');
      final url = await _executeStream('$_primaryUrl$path');
      if (url != null) return url;
    } catch (e) {
      debugPrint('[PipedService] Primary streaming failed: $e. Trying fallback...');
    }

    try {
      debugPrint('[PipedService] Streaming from fallback: $_fallbackUrl$path');
      return await _executeStream('$_fallbackUrl$path');
    } catch (e) {
      debugPrint('[PipedService] Fallback streaming failed: $e');
      rethrow;
    }
  }

  Future<PipedSong?> _executeSearch(String urlString) async {
    final response = await http.get(
      Uri.parse(urlString),
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw http.ClientException(
        'Server returned status code ${response.statusCode}',
        Uri.parse(urlString),
      );
    }

    final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic>? items = data['items'] as List<dynamic>?;

    if (items == null || items.isEmpty) {
      return null;
    }

    return PipedSong.fromJson(items.first as Map<String, dynamic>);
  }

  Future<String?> _executeStream(String urlString) async {
    final response = await http.get(
      Uri.parse(urlString),
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw http.ClientException(
        'Server returned status code ${response.statusCode}',
        Uri.parse(urlString),
      );
    }

    final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic>? audioStreams = data['audioStreams'] as List<dynamic>?;

    if (audioStreams == null || audioStreams.isEmpty) {
      return null;
    }

    final Map<String, dynamic> firstStream = audioStreams.first as Map<String, dynamic>;
    return firstStream['url'] as String?;
  }
}
