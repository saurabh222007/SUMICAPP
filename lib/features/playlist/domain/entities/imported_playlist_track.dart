/// Domain entity representing a track in an imported playlist.
class ImportedPlaylistTrack {
  final String id;
  final String title;
  final String author;
  final String thumbnail;

  const ImportedPlaylistTrack({
    required this.id,
    required this.title,
    required this.author,
    required this.thumbnail,
  });
}
