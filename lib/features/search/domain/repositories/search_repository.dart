import '../entities/search_track.dart';

/// Contract interface for the Search feature.
abstract class SearchRepository {
  /// Searches for tracks matching the [query].
  Future<List<SearchTrack>> search(String query);
}
