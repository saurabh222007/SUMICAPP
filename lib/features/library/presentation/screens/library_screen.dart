import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router.dart';
import '../../../../shared/themes/app_colors.dart';
import '../../../../shared/themes/app_typography.dart';
import '../../../playlist/presentation/providers/playlist_providers.dart';
import '../../../playlist/domain/entities/imported_playlist.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  int _selectedTab = 0; // 0: Playlists, 1: Artists, 2: Albums

  void _showImportDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1D1B20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Import Spotify Playlist',
          style: AppTypography.titleMedium.copyWith(color: Colors.white, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paste your Spotify playlist URL. The backend will parse it and match all tracks with high-quality stream links.',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.darkOnSurfaceVariant, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'https://open.spotify.com/playlist/...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF0D0D12),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.darkOutline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              final url = controller.text.trim();
              if (url.isEmpty) return;

              Navigator.pop(context); // Close input dialog
              _showLoadingDialog(context);

              try {
                final playlist = await ref.read(importPlaylistProvider(url).future);
                if (context.mounted) {
                  Navigator.pop(context); // Close loading dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Successfully imported "${playlist.title}"!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  // Open the new playlist detail
                  context.push(AppRoutePaths.playlist.replaceAll(':id', playlist.id));
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context); // Close loading dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to import: ${e.toString()}'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Import', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1D1B20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  'Importing tracks from Spotify & resolving YouTube streams. This may take a minute...',
                  style: AppTypography.bodyMedium.copyWith(color: Colors.white, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: replace with real backend once auth + DB endpoints exist
    final importedPlaylistsMap = ref.watch(importedPlaylistsCacheProvider);
    final importedPlaylists = importedPlaylistsMap.values.toList();

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        title: Text(
          'SUMIC',
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.primary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: -1.0,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.primary),
            onPressed: () => context.push(AppRoutePaths.settings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 140.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTabButton('Playlists', 0),
                    const SizedBox(width: 12),
                    _buildTabButton('Artists', 1),
                    const SizedBox(width: 12),
                    _buildTabButton('Albums', 2),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Header and Action Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Your Library', style: AppTypography.headlineMedium.copyWith(color: Colors.white)),
                  if (_selectedTab == 0)
                    Container(
                      height: 38,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(19.0),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFCFBCFF), Color(0xFF6750A4)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () => _showImportDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(19.0),
                          ),
                        ),
                        icon: const Icon(Icons.add, color: Colors.black, size: 18),
                        label: Text(
                          'New Playlist',
                          style: AppTypography.caption.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Tab Content
            if (_selectedTab == 0) ...[
              // Playlists List
              if (importedPlaylists.isEmpty) ...[
                // Default pre-populated design playlists if cache is empty
                _buildPlaylistsSection([
                  const PlaylistListItem(
                    id: 'default_1',
                    title: 'Night Drive Vibes',
                    subtitle: 'Electronic • 42 tracks',
                    imageUrl:
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuBbmNZtOr6EWmuKTpHbI7YtvPV8slv71vCbyJ6f3R4j_seQgar90EjX2GIbOuqQBQZZhvYyvB6y3kAkLAg-AGuFAFxS1VIuTXP42rK9MKkGm7Kop_VsZT2igW5w2ag0HwrXksFbe32QRuzMQsyzg8EfAIy3MRG0t28lssicdlLYS4ok1fUQpgNejXN3rBXO_oJzoSdU1YmhBZ6DUm8pRPi62XnsZM01ePRVI7ZmxZKS_RywzoG_o2aY2T8MvyEDTS1a1-JwkDwTMpQ',
                  ),
                  const PlaylistListItem(
                    id: 'default_2',
                    title: 'Lo-Fi Focus',
                    subtitle: 'Instrumental • 128 tracks',
                    imageUrl:
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuAw4Q85ZG_psKa1F1UrhceNOsSQ0gDA_x8uqIS1hxMLQrcETanD6PARmJPLgW_tmZtPUofRXnKymqoN2f_T9PDbgsiDoSAtuctxzoGk00J_s46VOXooEahYTcNfOVILD5AU1HzRKrkaplxB3RQWp5KP2xRXA8CEsYF_6uXLDvwjPekms3hvRq-XfexB7g3xx3JEJ0wHN-37ktujUsxvLZNn1AkCPrmMnYPzkv3f9ThEPkzOxj8QvBnwD3PHp1h1NOI_4q_3aS7aGbE',
                  ),
                ]),
              ] else ...[
                // Display both imported playlists and defaults
                _buildPlaylistsSection([
                  ...importedPlaylists.map((p) => PlaylistListItem(
                        id: p.id,
                        title: p.title,
                        subtitle: '${p.tracks.length} tracks • By ${p.owner}',
                        imageUrl: p.tracks.isNotEmpty ? p.tracks.first.thumbnail : '',
                      )),
                  const PlaylistListItem(
                    id: 'default_1',
                    title: 'Night Drive Vibes',
                    subtitle: 'Electronic • 42 tracks',
                    imageUrl:
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuBbmNZtOr6EWmuKTpHbI7YtvPV8slv71vCbyJ6f3R4j_seQgar90EjX2GIbOuqQBQZZhvYyvB6y3kAkLAg-AGuFAFxS1VIuTXP42rK9MKkGm7Kop_VsZT2igW5w2ag0HwrXksFbe32QRuzMQsyzg8EfAIy3MRG0t28lssicdlLYS4ok1fUQpgNejXN3rBXO_oJzoSdU1YmhBZ6DUm8pRPi62XnsZM01ePRVI7ZmxZKS_RywzoG_o2aY2T8MvyEDTS1a1-JwkDwTMpQ',
                  ),
                  const PlaylistListItem(
                    id: 'default_2',
                    title: 'Lo-Fi Focus',
                    subtitle: 'Instrumental • 128 tracks',
                    imageUrl:
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuAw4Q85ZG_psKa1F1UrhceNOsSQ0gDA_x8uqIS1hxMLQrcETanD6PARmJPLgW_tmZtPUofRXnKymqoN2f_T9PDbgsiDoSAtuctxzoGk00J_s46VOXooEahYTcNfOVILD5AU1HzRKrkaplxB3RQWp5KP2xRXA8CEsYF_6uXLDvwjPekms3hvRq-XfexB7g3xx3JEJ0wHN-37ktujUsxvLZNn1AkCPrmMnYPzkv3f9ThEPkzOxj8QvBnwD3PHp1h1NOI_4q_3aS7aGbE',
                  ),
                ]),
              ]
            ] else if (_selectedTab == 1) ...[
              // Artists list
              _buildArtistsSection(),
            ] else ...[
              // Albums list
              _buildAlbumsSection(),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String text, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4D4465) : const Color(0xFF2B292F),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: AppTypography.caption.copyWith(
            color: isSelected ? Colors.white : AppColors.darkOnSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistsSection(List<PlaylistListItem> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: InkWell(
              onTap: () {
                context.push(AppRoutePaths.playlist.replaceAll(':id', item.id));
              },
              borderRadius: BorderRadius.circular(16.0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16.0),
                    child: Container(
                      width: 64,
                      height: 64,
                      color: Colors.white.withOpacity(0.05),
                      child: item.imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: item.imageUrl,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => const Icon(Icons.playlist_play, color: Colors.white38),
                            )
                          : const Icon(Icons.playlist_play, color: Colors.white38, size: 28),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: AppTypography.titleMedium.copyWith(color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle,
                          style: AppTypography.caption.copyWith(color: AppColors.darkOnSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: AppColors.darkOnSurfaceVariant),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildArtistsSection() {
    final artists = [
      _ArtistItem(
        name: 'The Midnight Echo',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuDCWPtnA26Z_WOY1MXPOXDL2VvPG9Z8DRrduZO8mVOMD9Qz1hCz0_xyMX0JC1GfNPQkpPa95NlI1W31p7YsInSN1pga7YQ54osH3JrWdc7oTn68667NN0xrWoTSYl6JfFAY7pgAsod46kSP-5W0HQpVa_Oj-hobHR-jZSo1XoAJzNGESxNgSxE4k_SC851BJALTqMbmK6TWd76nKRDeC66j8HsIBwYSCPK-XIA4pq7PwZA9t9cteDvb8lLWjXi3zfYZ28lhXREl82s',
      ),
      _ArtistItem(
        name: 'Kavinsky',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuDUlM6DZeJzJ-fWqKcAUKlszHYJjJ4pfMmykunwI4cxi-9Zm_9h47M2EI6IJcKfKUTgQ93lM0qb0Wt8D2XO_TxfGF_hKAE7jwDZFoW9fRWKA61bhCD4L0ggC1ijJHQk2vv13sMQ25YIPB8qjs3C7yUZPFGzyrMpOwZAYE7OyiFQjMYrhNnZs0l78Uh94FHdwmJECxvZqG8dtP36-RXTyRrVKFb9CXzs08ghFpu6NRplWzp1rzEhBnTqe1ena1OcoqtfbTShriqjLos',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: artists.length,
        itemBuilder: (context, index) {
          final artist = artists[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundImage: NetworkImage(artist.imageUrl),
                  backgroundColor: Colors.white.withOpacity(0.05),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        artist.name,
                        style: AppTypography.titleMedium.copyWith(color: Colors.white, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Artist',
                        style: AppTypography.caption.copyWith(color: AppColors.darkOnSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAlbumsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.album, size: 64, color: AppColors.darkOutline),
            const SizedBox(height: 16),
            Text(
              'No albums saved yet',
              style: AppTypography.titleMedium.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap follow on albums to see them here.',
              style: AppTypography.caption.copyWith(color: AppColors.darkOnSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class PlaylistListItem {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;

  const PlaylistListItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
  });
}

class _ArtistItem {
  final String name;
  final String imageUrl;

  const _ArtistItem({
    required this.name,
    required this.imageUrl,
  });
}
