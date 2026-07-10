import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router.dart';
import '../../../../shared/themes/app_colors.dart';
import '../../../../shared/themes/app_typography.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../providers/player_providers.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTrack = ref.watch(playerProvider.select((s) => s.currentTrack));

    if (currentTrack == null) {
      return Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: const Center(
          child: Text('No song selected.', style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        children: [
          // Subtle radial background gradient glow
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.2,
                  colors: [
                    AppColors.primaryContainer.withOpacity(0.15),
                    AppColors.darkBackground,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Column(
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 28),
                        onPressed: () => context.pop(),
                      ),
                      Column(
                        children: [
                          Text(
                            'NOW PLAYING',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.darkOnSurfaceVariant,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'SUMIC Playlist',
                            style: AppTypography.titleMedium.copyWith(color: Colors.white, fontSize: 15),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_horiz, color: Colors.white, size: 28),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const Spacer(),

                  // Artwork Hero
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 320,
                        height: 320,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28.0),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.15),
                              blurRadius: 48,
                              offset: const Offset(0, 24),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28.0),
                          child: CachedNetworkImage(
                            imageUrl: currentTrack.thumbnail,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppColors.darkSurfaceContainer,
                              child: const Icon(Icons.music_note, color: Colors.white24, size: 64),
                            ),
                          ),
                        ),
                      ),
                      // Floating Glassmorphic Lyrics Prompt
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: GestureDetector(
                          onTap: () => context.push(AppRoutePaths.lyrics),
                          child: GlassContainer(
                            borderRadius: 20.0,
                            backgroundColor: AppColors.darkSurfaceContainer.withOpacity(0.7),
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.lyrics, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Lyrics',
                                  style: AppTypography.caption.copyWith(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),

                  // Track Info (Title & Artist)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentTrack.title,
                              style: AppTypography.headlineMedium.copyWith(
                                color: Colors.white,
                                fontSize: 24,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentTrack.author,
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.darkOnSurfaceVariant,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.favorite_border, color: AppColors.primary, size: 28),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Progress Bar / Slider
                  const _PlayerProgressSection(),
                  const SizedBox(height: 24),

                  // Playback Control Cluster
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shuffle, color: AppColors.darkOnSurfaceVariant, size: 24),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_previous, color: Colors.white, size: 36),
                        onPressed: () => ref.read(playerProvider.notifier).previous(),
                      ),
                      const _PlayPauseButton(),
                      IconButton(
                        icon: const Icon(Icons.skip_next, color: Colors.white, size: 36),
                        onPressed: () => ref.read(playerProvider.notifier).next(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.repeat, color: AppColors.darkOnSurfaceVariant, size: 24),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerProgressSection extends ConsumerWidget {
  const _PlayerProgressSection();

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(playerProvider.select((s) => s.position));
    final duration = ref.watch(playerProvider.select((s) => s.duration));

    final double sliderValue = duration.inMilliseconds > 0
        ? position.inMilliseconds.toDouble()
        : 0.0;
    final double sliderMax = duration.inMilliseconds > 0
        ? duration.inMilliseconds.toDouble()
        : 100.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.darkSurfaceVariant,
            thumbColor: Colors.white,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayColor: AppColors.primary.withOpacity(0.2),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          ),
          child: Slider(
            value: sliderValue.clamp(0.0, sliderMax),
            max: sliderMax,
            onChanged: (value) {
              ref.read(playerProvider.notifier).seek(Duration(milliseconds: value.toInt()));
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(position),
                style: AppTypography.caption.copyWith(color: AppColors.darkOnSurfaceVariant),
              ),
              Text(
                _formatDuration(duration),
                style: AppTypography.caption.copyWith(color: AppColors.darkOnSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlayPauseButton extends ConsumerWidget {
  const _PlayPauseButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlaying = ref.watch(playerProvider.select((s) => s.isPlaying));
    return GestureDetector(
      onTap: () => ref.read(playerProvider.notifier).togglePlay(),
      child: Container(
        width: 72,
        height: 72,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFF6750A4), Color(0xFFCFBCFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Icon(
          isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
          size: 36,
        ),
      ),
    );
  }
}
