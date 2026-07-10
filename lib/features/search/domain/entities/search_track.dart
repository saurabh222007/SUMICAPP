/// Domain representation of a track search result.
class SearchTrack {
  final String id;
  final String title;
  final String author;
  final String duration;
  final String thumbnail;

  const SearchTrack({
    required this.id,
    required this.title,
    required this.author,
    required this.duration,
    required this.thumbnail,
  });
}
