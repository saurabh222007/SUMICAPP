import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:sumic_backend/stream_handler.dart';

void main(List<String> args) async {
  final streamHandler = StreamHandler();

  final router = Router()
    ..get('/', _rootHandler)
    ..get('/stream', streamHandler.handleStream);

  // Configure a pipeline that logs requests and handles CORS
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders(
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
          'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Range',
          'Access-Control-Expose-Headers': 'Content-Length, Content-Range, Accept-Ranges',
        }
      ))
      .addHandler(router.call);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  
  // Use IPv4 bind
  final server = await serve(handler, InternetAddress.anyIPv4, port);
  print('Server listening on port ${server.port}');
}

Response _rootHandler(Request req) {
  return Response.ok('Sumic Dart Backend API is running!\n');
}
