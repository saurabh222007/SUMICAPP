import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class LocalAudioProxy {
  HttpServer? _server;
  final YoutubeExplode _yt = YoutubeExplode();
  int? port;

  Future<void> start() async {
    if (_server != null) return;
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    port = _server!.port;
    
    _server!.listen((HttpRequest request) async {
      final id = request.uri.queryParameters['id'];
      print('Proxy received request for id: $id');
      if (id == null) {
        request.response.statusCode = 400;
        request.response.close();
        return;
      }
      
      try {
        print('Proxy: fetching manifest for $id using androidSdkless...');
        final manifest = await _yt.videos.streamsClient.getManifest(
          id,
          ytClients: [YoutubeApiClient.androidSdkless],
        );
        print('Proxy: manifest fetched successfully.');
        final streamInfo = manifest.audioOnly.withHighestBitrate();
        
        final rangeHeader = request.headers.value('range');
        print('Proxy: client requested Range: $rangeHeader');
        
        if (rangeHeader != null && rangeHeader.startsWith('bytes=')) {
          // Parse requested range
          final parts = rangeHeader.substring(6).split('-');
          int? rangeStart = int.tryParse(parts[0]);
          int? rangeEnd;
          if (parts.length > 1 && parts[1].isNotEmpty) {
            rangeEnd = int.tryParse(parts[1]);
          }
          
          rangeStart ??= 0;
          // Bounded chunk size to prevent YouTube 403 blocks
          final chunkSize = 2 * 1024 * 1024; // 2MB chunk
          rangeEnd ??= rangeStart + chunkSize - 1;
          if (rangeEnd >= streamInfo.size.totalBytes) {
            rangeEnd = streamInfo.size.totalBytes - 1;
          }
          
          final boundedRange = 'bytes=$rangeStart-$rangeEnd';
          print('Proxy: requesting bounded Range from YouTube: $boundedRange');
          
          final client = HttpClient();
          final ytRequest = await client.getUrl(streamInfo.url);
          ytRequest.headers.set('range', boundedRange);
          ytRequest.headers.set('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
          
          final ytResponse = await ytRequest.close();
          print('Proxy: YouTube response status: ${ytResponse.statusCode}');
          
          request.response.statusCode = HttpStatus.partialContent;
          request.response.headers.set('Content-Range', 'bytes $rangeStart-$rangeEnd/${streamInfo.size.totalBytes}');
          request.response.headers.contentLength = (rangeEnd - rangeStart) + 1;
          request.response.headers.set('Accept-Ranges', 'bytes');
          request.response.headers.contentType = ContentType('audio', 'mpeg');
          
          await ytResponse.pipe(request.response);
          client.close();
          print('Proxy: piped chunk successfully.');
        } else {
          // Non-range request: stream chunk-by-chunk in a loop
          request.response.statusCode = 200;
          request.response.headers.contentType = ContentType('audio', 'mpeg');
          request.response.headers.contentLength = streamInfo.size.totalBytes;
          
          int start = 0;
          final chunkSize = 2 * 1024 * 1024; // 2MB chunks
          while (start < streamInfo.size.totalBytes) {
            int end = start + chunkSize - 1;
            if (end >= streamInfo.size.totalBytes) {
              end = streamInfo.size.totalBytes - 1;
            }
            
            final boundedRange = 'bytes=$start-$end';
            print('Proxy loop: requesting $boundedRange');
            final client = HttpClient();
            final ytRequest = await client.getUrl(streamInfo.url);
            ytRequest.headers.set('range', boundedRange);
            ytRequest.headers.set('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
            
            final ytResponse = await ytRequest.close();
            await ytResponse.pipe(request.response);
            client.close();
            
            start = end + 1;
          }
          print('Proxy: piped entire file successfully.');
        }
      } catch (e, stack) {
        print('Proxy error: $e');
        print(stack);
        try {
          request.response.statusCode = 500;
          request.response.close();
        } catch (_) {}
      }
    });
  }

  void stop() {
    _server?.close();
    _yt.close();
  }
}
