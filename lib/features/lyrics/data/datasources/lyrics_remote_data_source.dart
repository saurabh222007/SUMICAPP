import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../models/lyrics_model.dart';

/// Data source interface interacting with the network.
abstract class LyricsRemoteDataSource {
  Future<LyricsModel> getLyrics({required String track, String? artist});
}

/// Implementation of the LyricsRemoteDataSource.
class LyricsRemoteDataSourceImpl implements LyricsRemoteDataSource {
  final ApiClient _apiClient;

  LyricsRemoteDataSourceImpl(this._apiClient);

  @override
  Future<LyricsModel> getLyrics({required String track, String? artist}) async {
    final params = <String, dynamic>{'track': track};
    if (artist != null && artist.isNotEmpty) {
      params['artist'] = artist;
    }

    try {
      final response = await _apiClient.get<dynamic>(
        '/api/lyrics',
        queryParameters: params,
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data.containsKey('error')) {
          throw Exception(data['error']);
        }
        return LyricsModel.fromJson(data);
      }
      throw Exception('Invalid lyrics response format.');
    } catch (e) {
      debugPrint('Lyrics fetch error: $e');
      rethrow;
    }
  }
}
