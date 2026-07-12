import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'dart:convert';

class StreamHandler {
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
        if (key.toLowerCase() != 'transfer-encoding' && key.toLowerCase() != 'content-encoding') {
          responseHeaders[key] = value;
        }
      });
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
    // 1. Try youtube_explode_dart with different clients to bypass rate-limiting
    try {
      final yt = YoutubeExplode();
      print('[StreamHandler] Trying youtube_explode_dart for $videoId');
      
      // Try IOS client first which often bypasses restrictions
      final manifest = await yt.videos.streamsClient.getManifest(
        videoId,
        ytClients: [YoutubeApiClient.ios, YoutubeApiClient.tv, YoutubeApiClient.mweb],
      );
      
      final streamInfo = manifest.audioOnly.withHighestBitrate();
      yt.close();
      print('[StreamHandler] youtube_explode_dart resolved successfully!');
      return streamInfo.url.toString();
    } catch (e) {
      print('[StreamHandler] youtube_explode_dart failed: $e. Trying Piped fallback...');
    }

    // 2. Try Piped instances as fallback
    final instances = ['https://pipedapi.kavin.rocks', 'https://pipedapi.smnz.de'];
    for (var inst in instances) {
      try {
        final url = await _executePipedStream('$inst/streams/$videoId');
        if (url != null) return url;
      } catch (e) {
        print('[StreamHandler] Piped $inst failed: $e');
      }
    }
    
    return null;
  }

  Future<String?> _executePipedStream(String urlString) async {
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

    Map<String, dynamic>? bestStream;
    for (var stream in audioStreams) {
      if (stream['mimeType']?.toString().contains('audio/mp4') == true ||
          stream['mimeType']?.toString().contains('audio/m4a') == true) {
        bestStream = stream;
        break;
      }
    }
    
    bestStream ??= audioStreams.first;
    return bestStream!['url'] as String?;
  }
}
