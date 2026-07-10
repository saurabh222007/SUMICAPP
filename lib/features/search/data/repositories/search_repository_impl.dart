import '../../domain/entities/search_track.dart';
import '../../domain/repositories/search_repository.dart';
import '../datasources/search_remote_data_source.dart';

/// Implementation of the SearchRepository interface.
class SearchRepositoryImpl implements SearchRepository {
  final SearchRemoteDataSource _remoteDataSource;

  SearchRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<SearchTrack>> search(String query) async {
    return await _remoteDataSource.search(query);
  }
}
