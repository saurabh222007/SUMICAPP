import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';

class StreamHandler {
  static const String _primaryUrl = 'https://pipedapi.kavin.rocks';
  static const String _fallbackUrl = 'https://pipedapi.smnz.de';

  Future<Response> handleStream(Request request) async {
    final id = request.url.queryParameters['id'];
    if (id == null || id.isEmpty) {
      return Response.badRequest(body: 'Missing video id');
    }

    try {
      final streamUrl = await _fetchAudioStream(id);
      if (streamUrl == null) {
        return Response.notFound('Audio stream not found');
      }

      // Check for Range header
      final rangeHeader = request.headers['range'];
      final headers = <String, String>{
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      };
      
      if (rangeHeader != null) {
        headers['range'] = rangeHeader;
      }

      // Forward request to actual stream URL
      final client = http.Client();
      final streamRequest = http.Request('GET', Uri.parse(streamUrl));
      streamRequest.headers.addAll(headers);
      
      final streamResponse = await client.send(streamRequest);
      
      // Pass the response stream directly to the client
      final responseHeaders = <String, String>{};
      streamResponse.headers.forEach((key, value) {
        // Exclude specific headers that shelf handles automatically or shouldn't be forwarded
        if (key.toLowerCase() != 'transfer-encoding' && key.toLowerCase() != 'content-encoding') {
          responseHeaders[key] = value;
        }
      });
      // Force permissive CORS
      responseHeaders['Access-Control-Allow-Origin'] = '*';

      return Response(
        streamResponse.statusCode,
        body: streamResponse.stream,
        headers: responseHeaders,
      );

    } catch (e) {
      print('Proxy error: $e');
      return Response.internalServerError(body: 'Error fetching stream: $e');
    }
  }

  Future<String?> _fetchAudioStream(String videoId) async {
    final String path = '/streams/$videoId';

    try {
      final url = await _executeStream('$_primaryUrl$path');
      if (url != null) return url;
    } catch (e) {
      print('[StreamHandler] Primary streaming failed: $e. Trying fallback...');
    }

    try {
      return await _executeStream('$_fallbackUrl$path');
    } catch (e) {
      print('[StreamHandler] Fallback streaming failed: $e');
      return null;
    }
  }

  Future<String?> _executeStream(String urlString) async {
    final response = await http.get(
      Uri.parse(urlString),
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Server returned status code ${response.statusCode}');
    }

    final Map<String, dynamic> data = jsonDecode(response.body);
    final List<dynamic>? audioStreams = data['audioStreams'];

    if (audioStreams == null || audioStreams.isEmpty) {
      return null;
    }

    // Try to get high quality m4a/aac stream first
    Map<String, dynamic>? bestStream;
    for (var stream in audioStreams) {
      if (stream['mimeType']?.toString().contains('audio/mp4') == true ||
          stream['mimeType']?.toString().contains('audio/m4a') == true) {
        bestStream = stream;
        break;
      }
    }
    
    // Fallback to first available
    bestStream ??= audioStreams.first;
    
    return bestStream['url'] as String?;
  }
}
