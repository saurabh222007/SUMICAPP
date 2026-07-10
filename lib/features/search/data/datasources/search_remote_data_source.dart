import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../models/search_track_model.dart';

/// Data source interface interacting with the network.
abstract class SearchRemoteDataSource {
  Future<List<SearchTrackModel>> search(String query);
}

/// Implementation of the SearchRemoteDataSource.
class SearchRemoteDataSourceImpl implements SearchRemoteDataSource {
  final ApiClient _apiClient;

  SearchRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<SearchTrackModel>> search(String query) async {
    try {
      final response = await _apiClient.get<dynamic>(
        '/api/search',
        queryParameters: {'q': query},
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data.containsKey('error')) {
          throw Exception(data['error']);
        }
        final results = data['results'] as List<dynamic>?;
        if (results != null) {
          return results
              .map((json) => SearchTrackModel.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }
      throw Exception('Unexpected response format.');
    } catch (e) {
      debugPrint('Search parse error: $e');
      rethrow;
    }
  }
}
