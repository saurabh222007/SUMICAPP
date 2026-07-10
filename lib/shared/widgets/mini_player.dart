import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';
import '../../features/player/presentation/providers/player_providers.dart';
import '../../features/search/domain/entities/search_track.dart';
import '../themes/app_colors.dart';
import '../themes/app_typography.dart';
import 'glass_container.dart';

/// Global Mini Player floating above the navigation shell.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTrack = ref.watch(playerProvider.select((s) => s.currentTrack));
    final isPlaying = ref.watch(playerProvider.select((s) => s.isPlaying));

    if (currentTrack == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GestureDetector(
        onTap: () => context.pushNamed(AppRouteNames.player),
        child: GlassContainer(
          borderRadius: 16.0,
          backgroundColor: AppColors.darkSurfaceContainer.withValues(alpha: 0.6),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    // Thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: currentTrack.thumbnail.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: currentTrack.thumbnail,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: AppColors.darkSurfaceVariant,
                                child: const Icon(Icons.music_note, color: Colors.white24),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: AppColors.darkSurfaceVariant,
                                child: const Icon(Icons.music_note, color: Colors.white24),
                              ),
                            )
                          : Container(
                              width: 40,
                              height: 40,
                              color: AppColors.darkSurfaceVariant,
                              child: const Icon(Icons.music_note, color: Colors.white24),
                            ),
                    ),
                    const SizedBox(width: 12),
                    // Track details
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentTrack.title,
                            style: AppTypography.titleMedium.copyWith(
                              color: Colors.white,
                              fontSize: 14.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currentTrack.author,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.darkOnSurfaceVariant,
                              fontSize: 12.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Actions
                    IconButton(
                      icon: const Icon(Icons.favorite_border, color: AppColors.primary, size: 20),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: AppColors.primary,
                        size: 28,
                      ),
                      onPressed: () {
                        ref.read(playerProvider.notifier).togglePlay();
                      },
                    ),
                  ],
                ),
              ),
              // Linear Progress Bar at bottom of card
              const Positioned(
                bottom: 0,
                left: 12,
                right: 12,
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(2)),
                  child: _MiniPlayerProgressBar(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniPlayerProgressBar extends ConsumerWidget {
  const _MiniPlayerProgressBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(playerProvider.select((s) => s.position));
    final duration = ref.watch(playerProvider.select((s) => s.duration));
    final double progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return LinearProgressIndicator(
      value: progress.clamp(0.0, 1.0),
      backgroundColor: AppColors.darkSurfaceVariant,
      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
      minHeight: 2,
    );
  }
}
