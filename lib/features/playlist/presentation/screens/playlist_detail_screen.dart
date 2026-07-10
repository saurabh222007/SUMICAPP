import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/themes/app_colors.dart';
import '../../../../shared/themes/app_typography.dart';
import '../../../player/presentation/providers/player_providers.dart';
import '../../../search/domain/entities/search_track.dart';
import '../providers/playlist_providers.dart';

class PlaylistDetailScreen extends ConsumerWidget {
  final String id;

  const PlaylistDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cachedPlaylists = ref.watch(importedPlaylistsCacheProvider);
    final importedPlaylist = cachedPlaylists[id];

    // Pre-populate beautiful default/fallback mock playlist if cache is empty
    final String title = importedPlaylist?.title ?? 'Midnight Synthwave';
    final String owner = importedPlaylist?.owner ?? 'Aria Vance';
    final String coverUrl = importedPlaylist?.tracks.isNotEmpty == true
        ? importedPlaylist!.tracks.first.thumbnail
        : 'https://lh3.googleusercontent.com/aida-public/AB6AXuA356a_G5XeXnD13rk_F4-LjNo5o71f9cvm94BuV3YoM_XaNJeAhWX3PNPEg2rGO7qWIU8BwWbFn9N9b-924xt4cuhEPUMAtdCJHUfWSEsHo7xUiIe4pCc0Q8z4G9o8198HyFJiJiLtC0Yh4IBjk3v2PJx2-DlAjjiybS6kVYb0mbZyeSIjcfQXhEvbhM84-dZ1bM6XsAa9rWDD5PQ6I1sZCpWvw22NnJVu11YKPSFnHBidPml-yZM1sQ5fnu_Yg3hKUdeT-7g-HMo';

    // Map playlist tracks to unified SearchTrack for player compatibility
    final List<SearchTrack> tracks = importedPlaylist != null
        ? importedPlaylist.tracks.map((t) => SearchTrack(
              id: t.id,
              title: t.title,
              author: t.author,
              duration: '3:45', // Default fallback dur
              thumbnail: t.thumbnail,
            )).toList()
        : [
            const SearchTrack(
              id: 'neon_nights',
              title: 'Neon Nights',
              author: 'Cyberdrive',
              duration: '4:15',
              thumbnail: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBx11iJma7_bccLX7QRYvaBzIXX9myj6rxCyh1JZG8FkEj4Sg0jIEqQe82OZTMfIasmqGh7aYk5MtNfaDgRSQfvKKEVTu2SKqkQ3RRvlFiol6LqY559Wn3A8ioRN43QM0C7GZTcr3BM9KZmyP-InJoh4sUgWK6qybXK7s0X1IVcj4kIww-FpqL6y93_wD3OADmLvdkiPyYN_P3l3x8TM71-Oj2hem-d4uNpwDGVvencOc4cBm7qq4OPj0581o9QGG--jY6oHwBo_oc',
            ),
            const SearchTrack(
              id: 'cruising_altitude',
              title: 'Cruising Altitude',
              author: 'Aria Vance',
              duration: '3:30',
              thumbnail: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCG0j-hoZh90-ndFXUaBkoB2XdHHVYxmeOqByZd17AlMsyCYQGaC9MOo2mEv28j-4_FsQ8736TJwCR-E0PqIB2mPoBvMIEPNim3M94IxtutUSdFCsBeGjxM6gJJOAOFGNon4qKyd7aW1AXX2rxi2gbnZeJKk_Ix6PHLIVaWtO-6fF8tGy0kBcXUckfV-VFFWRnwzA3CwqNVObe5q58FL1AOPMP7qJsxu_hz5SjI9tqi4hJKk6WjldBR6Y4FfIy04znGC0X3T9lYPVQ',
            ),
            const SearchTrack(
              id: 'analog_dreams',
              title: 'Analog Dreams',
              author: 'The Midnight Boys',
              duration: '5:02',
              thumbnail: 'https://lh3.googleusercontent.com/aida-public/AB6AXuB2V9SODAh__zzZHR95XMA8g8G3Sa2P378rf9E0mwkv3bGvH2-n9xwu_H5c-yPz6ZN19RFbTXx10SOaNH2AQ4ION6yaCh1n4VXCLwGREpB1pTsS0v5ssJOXc0taX6xcr2K_BEwI1Rrs1N5pTFG3K_HB26_zBSkFP8D8N3DZ1HnbvouCBjpY4DeJ3bXiqBeA2TljxqP_9nDKheK27YapAePmfDqHu0hnGWFZtxTzKF5wJpVsQyqh1IYIVlVG-KhZDuMoThwfjOjdePE',
            ),
            const SearchTrack(
              id: 'data_stream',
              title: 'Data Stream',
              author: 'Vectro',
              duration: '3:45',
              thumbnail: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDDhy43M42aG7ppsdiBvn5MoTjochm3Kg-JYhtFCswPZ7mX5L6mOKqCuDQMLVuqHwGc7a9CJgE58ccsYXoYK-ct7w1iycqbbEthBUQCyAQnV4QXjfgZ82fo8fB3Fk87OsKKXOkVa0Yzg4FaLds1lxnwbL95pLxlH319mUM99Ru0m1b1cYHXR211FOBr2U2WGtkZF2ys9gRdZX0kvfW0YEomADf_goONTqgYP-D6UhgQ9O8bJZw2_vLvxh96Q7mvKDap7FHONObNXZE',
            ),
          ];

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        children: [
          // Ambient Glow Background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 350,
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.2,
                  colors: [
                    const Color(0xFF6750A4).withOpacity(0.35),
                    AppColors.darkBackground.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          // Custom Back Action Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, top: 8),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.pop(),
              ),
            ),
          ),
          // Content Layout
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 120.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 32),
                    // Cover Art
                    Center(
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6750A4).withOpacity(0.3),
                              blurRadius: 32,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: CachedNetworkImage(
                            imageUrl: coverUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppTypography.headlineMedium.copyWith(
                        color: Colors.white,
                        fontSize: 26,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Owner
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundImage: const NetworkImage(
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuDBnc-0U_x7trikm4VLJYCGAcydKfnvpWD0S0w5WlWjOy6kCqbJDut3NF2eq8yJMwmIxeyOnfFNBhJ80kVoY2oQsuVnApgl-SeiwTUcsoHGyLXi9tMFBd6GdAKXfo1iL63-ethZdzeXWa-NyrEDij0zGlKcOaZmJ0IRAwL0mq_mqcwjV2Dy8QPkYWmc-f2cg3XqBORHE-FnmCgkpEZiHRaTqTj6kFhJcqBBbIyowMbLHO8BUNX2YqITLiFOgeV50Wg8z3tmOoxAq9o',
                          ),
                          backgroundColor: Colors.white.withOpacity(0.1),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Created by $owner',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.darkOnSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Stats
                    Text(
                      '${tracks.length} songs • ${(tracks.length * 3.5).toInt()} mins',
                      textAlign: TextAlign.center,
                      style: AppTypography.caption.copyWith(color: AppColors.darkOutline),
                    ),
                    const SizedBox(height: 24),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Play Button
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24.0),
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, Color(0xFF6750A4)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // Play whole playlist queue
                                ref.read(playerProvider.notifier).setQueue(tracks, startIndex: 0);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24.0),
                                ),
                              ),
                              icon: const Icon(Icons.play_arrow, color: Colors.black),
                              label: Text(
                                'Play',
                                style: AppTypography.titleMedium.copyWith(
                                  color: Colors.black,
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Shuffle Button
                        _CircularActionButton(
                          icon: Icons.shuffle,
                          onTap: () {
                            // Shuffle tracks and play
                            final shuffled = List<SearchTrack>.from(tracks)..shuffle();
                            ref.read(playerProvider.notifier).setQueue(shuffled, startIndex: 0);
                          },
                        ),
                        const SizedBox(width: 12),
                        // Download Button
                        _CircularActionButton(
                          icon: Icons.download,
                          onTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Tracks List
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: tracks.length,
                      itemBuilder: (context, index) {
                        final track = tracks[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: InkWell(
                            onTap: () {
                              // Play selected track from playlist queue
                              ref.read(playerProvider.notifier).setQueue(tracks, startIndex: index);
                            },
                            borderRadius: BorderRadius.circular(8.0),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6.0),
                                  child: CachedNetworkImage(
                                    imageUrl: track.thumbnail,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        track.title,
                                        style: AppTypography.titleMedium.copyWith(color: Colors.white, fontSize: 15),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        track.author,
                                        style: AppTypography.caption.copyWith(color: AppColors.darkOnSurfaceVariant),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.more_horiz, color: AppColors.darkOnSurfaceVariant),
                                  onPressed: () {},
                                ),
                                const Icon(Icons.drag_handle, color: AppColors.darkSurfaceVariant, size: 20),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircularActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircularActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24.0),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.darkSurfaceVariant),
        ),
        child: Icon(icon, color: AppColors.darkOnSurfaceVariant, size: 20),
      ),
    );
  }
}
