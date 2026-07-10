import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../domain/repositories/search_repository.dart';
import '../../data/datasources/search_remote_data_source.dart';
import '../../data/repositories/search_repository_impl.dart';
import '../../domain/entities/search_track.dart';

/// Provider for the remote search data source.
final searchRemoteDataSourceProvider = Provider<SearchRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SearchRemoteDataSourceImpl(apiClient);
});

/// Provider for the search repository.
final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  final remoteDataSource = ref.watch(searchRemoteDataSourceProvider);
  return SearchRepositoryImpl(remoteDataSource);
});

/// Future provider family for searching tracks based on a query parameter.
final searchResultsProvider = FutureProvider.family<List<SearchTrack>, String>((ref, query) async {
  if (query.trim().isEmpty) {
    return const [];
  }
  final repository = ref.watch(searchRepositoryProvider);
  return repository.search(query);
});
