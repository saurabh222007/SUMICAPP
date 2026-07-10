import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/themes/app_colors.dart';
import '../../../../shared/themes/app_typography.dart';
import '../../../player/presentation/providers/player_providers.dart';
import '../../../search/domain/entities/search_track.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Premium pre-populated real tracks with working YouTube video IDs and thumbnails
    final continueListeningTracks = [
      const SearchTrack(
        id: 'qbShHxWNmug',
        title: '47',
        author: 'Sidhu Moose Wala ft. Mist',
        duration: '3:12',
        thumbnail: 'https://img.youtube.com/vi/qbShHxWNmug/mqdefault.jpg',
      ),
      const SearchTrack(
        id: 'YkADj0TPrJA',
        title: 'Starboy',
        author: 'The Weeknd ft. Daft Punk',
        duration: '3:50',
        thumbnail: 'https://img.youtube.com/vi/YkADj0TPrJA/mqdefault.jpg',
      ),
    ];

    final recentlyPlayedTracks = [
      const SearchTrack(
        id: 'hLQl3WQQoQ0',
        title: 'Someone Like You',
        author: 'Adele',
        duration: '4:45',
        thumbnail: 'https://img.youtube.com/vi/hLQl3WQQoQ0/mqdefault.jpg',
      ),
      const SearchTrack(
        id: 'JGwWNGJdvx8',
        title: 'Shape of You',
        author: 'Ed Sheeran',
        duration: '3:53',
        thumbnail: 'https://img.youtube.com/vi/JGwWNGJdvx8/mqdefault.jpg',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground.withValues(alpha: 0.8),
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: const NetworkImage(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuACI5k3q-rp9zItRyZTdrd13a28DQuZLph30813iEzk4g6ViJz2GK6o5PIT4f6sA_6-LRf-GcagNYl2OgkE6z3HvAYQgSdZmSLOBmWQ5d9w58jNceUbOcGJdez-flkUveaOALcxqxNQrhs-TZXrCbkJZDMmjITgn_b5JmmsW6mBRqu7NrQPbrvPVLlhWOxV5tVNoYQ-j9ak7CdDWLo1E6IivlmVNMQZeHg9F-hfh0F3lon0gD_SWY_xsUIkghFO_8w11LM1XnMWwrQ',
              ),
              backgroundColor: Colors.white.withOpacity(0.1),
            ),
            const SizedBox(width: 12),
            Text(
              'Good evening, Aria',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.primary,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: AppColors.primary),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120.0, top: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Continue Listening Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Continue Listening', style: AppTypography.titleMedium),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'See all',
                      style: AppTypography.caption.copyWith(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                scrollDirection: Axis.horizontal,
                itemCount: continueListeningTracks.length,
                itemBuilder: (context, index) {
                  final track = continueListeningTracks[index];
                  return Container(
                    width: 140,
                    margin: const EdgeInsets.only(right: 16.0),
                    child: GestureDetector(
                      onTap: () => ref.read(playerProvider.notifier).playTrack(track),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16.0),
                                child: CachedNetworkImage(
                                  imageUrl: track.thumbnail,
                                  width: 140,
                                  height: 140,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.4),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            track.title,
                            style: AppTypography.titleMedium.copyWith(color: Colors.white, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            track.author,
                            style: AppTypography.caption.copyWith(color: AppColors.darkOnSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),
            // Recently Played Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text('Recently Played', style: AppTypography.titleMedium),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 190,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                scrollDirection: Axis.horizontal,
                itemCount: recentlyPlayedTracks.length,
                itemBuilder: (context, index) {
                  final track = recentlyPlayedTracks[index];
                  final isArtistCircle = index == 0; // The Midnight is circular in the design

                  return Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 16.0),
                    child: GestureDetector(
                      onTap: () => ref.read(playerProvider.notifier).playTrack(track),
                      child: Column(
                        crossAxisAlignment: isArtistCircle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(isArtistCircle ? 60.0 : 16.0),
                            child: CachedNetworkImage(
                              imageUrl: track.thumbnail,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            track.title,
                            textAlign: isArtistCircle ? TextAlign.center : TextAlign.start,
                            style: AppTypography.titleMedium.copyWith(color: Colors.white, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (!isArtistCircle)
                            Text(
                              track.author,
                              style: AppTypography.caption.copyWith(color: AppColors.darkOnSurfaceVariant),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),
            // Mood Mixes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text('Mood Mixes', style: AppTypography.titleMedium),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 96,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.0),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Chill',
                          style: AppTypography.titleMedium.copyWith(color: Colors.white, fontSize: 20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      height: 96,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.0),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF43F5E), Color(0xFFF97316)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Hype',
                          style: AppTypography.titleMedium.copyWith(color: Colors.white, fontSize: 20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
