import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import '../core/network/api_config.dart';

/// Service representing the parallel yt-dlp worker streaming flow.
class YtStreamService {
  final String _baseUrl;

  YtStreamService({String? baseUrl}) : _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  /// Retrieves an AudioSource by requesting the FastAPI helper worker on Render.
  Future<AudioSource> getAudioSource(String videoId) async {
    final response = await http.get(Uri.parse('$_baseUrl/yt-stream/$videoId'));

    if (response.statusCode != 200) {
      throw Exception('Failed to load stream metadata: status ${response.statusCode}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final audioUrl = data['audio_url'] as String?;
    if (audioUrl == null || audioUrl.isEmpty) {
      throw Exception('Audio URL not present in metadata response.');
    }

    // Return the source for just_audio to play directly
    return AudioSource.uri(
      Uri.parse(audioUrl),
      tag: {
        'title': (data['title'] as String?) ?? 'Unknown Title',
        'duration': data['duration'] != null 
            ? Duration(seconds: (data['duration'] as num).toInt()) 
            : null,
      },
    );
  }
}
