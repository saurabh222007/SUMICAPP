import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/themes/app_colors.dart';
import '../../../../shared/themes/app_typography.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../player/presentation/providers/player_providers.dart';
import '../providers/lyrics_providers.dart';
import '../../../../shared/widgets/error_state_widget.dart';

class LyricsScreen extends ConsumerStatefulWidget {
  const LyricsScreen({super.key});

  @override
  ConsumerState<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends ConsumerState<LyricsScreen> {
  final ScrollController _scrollController = ScrollController();
  int _activeLineIndex = -1;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToActiveLine(int index, int totalLines) {
    if (!_scrollController.hasClients || index == -1 || index == _activeLineIndex) return;

    _activeLineIndex = index;
    
    // Each line is roughly 80dp tall including spacing.
    // We animate to center the item.
    final double viewportHeight = _scrollController.position.viewportDimension;
    final double targetOffset = (index * 80.0) - (viewportHeight / 2) + 40.0;

    _scrollController.animateTo(
      max(0.0, targetOffset),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTrack = ref.watch(playerProvider.select((s) => s.currentTrack));

    if (currentTrack == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0D13),
        body: Center(
          child: Text('No song playing.', style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    // Load lyrics from server/database
    final lyricsAsync = ref.watch(lyricsProvider(LyricsQueryParams(
      track: currentTrack.title,
      artist: currentTrack.author,
    )));

    return Scaffold(
      body: Stack(
        children: [
          // Immersive Ambient Background (Radial Gradients)
          Positioned.fill(
            child: Container(
              color: const Color(0xFF0F0D13),
            ),
          ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _scrollController, // subtle shift on scroll
              builder: (context, child) {
                return Opacity(
                  opacity: 0.8,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(0.0, -0.2),
                        radius: 1.5,
                        colors: [
                          Color(0x666750A4), // Purple
                          Color(0x33C9A74D), // Gold
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xCC0F0D13),
                    Colors.transparent,
                    Color(0xE60F0D13),
                  ],
                ),
              ),
            ),
          ),

          // Main Screen Layout
          SafeArea(
            child: Column(
              children: [
                // Top Navigation Controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: GlassContainer(
                          borderRadius: 24.0,
                          width: 48,
                          height: 48,
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          child: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 24),
                        ),
                      ),
                      Text(
                        currentTrack.title,
                        style: AppTypography.titleMedium.copyWith(color: Colors.white, fontSize: 15),
                      ),
                      GlassContainer(
                        borderRadius: 24.0,
                        width: 48,
                        height: 48,
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        child: const Icon(Icons.share, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ),

                // Lyrics Content Area
                Expanded(
                  child: lyricsAsync.when(
                    data: (lyrics) {
                      if (lyrics.lines.isEmpty) {
                        return Center(
                          child: Text(
                            'Lyrics not available for this song.',
                            style: AppTypography.titleMedium.copyWith(color: AppColors.darkOnSurfaceVariant),
                          ),
                        );
                      }

                      // Dynamic Position-based child isolation
                      return Consumer(
                        builder: (context, ref, child) {
                          final position = ref.watch(playerProvider.select((s) => s.position));
                          
                          // Compute active line index
                          int activeIndex = -1;
                          if (lyrics.isSynced) {
                            final currentSec = position.inMilliseconds / 1000.0;
                            for (int i = 0; i < lyrics.lines.length; i++) {
                              final lineTime = lyrics.lines[i].time ?? 0.0;
                              if (currentSec >= lineTime) {
                                activeIndex = i;
                              } else {
                                break;
                              }
                            }
                            // Animate scroll to active line
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _scrollToActiveLine(activeIndex, lyrics.lines.length);
                            });
                          }

                          return ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 120.0),
                            itemCount: lyrics.lines.length,
                            itemBuilder: (context, index) {
                              final line = lyrics.lines[index];
                              final isActive = index == activeIndex;
                              final isNear = (index - (activeIndex)).abs() <= 1;

                              double opacity = 0.3;
                              if (!lyrics.isSynced) {
                                opacity = 1.0;
                              } else if (isActive) {
                                opacity = 1.0;
                              } else if (isNear && activeIndex != -1) {
                                opacity = 0.5;
                              }

                              return GestureDetector(
                                onTap: () {
                                  if (line.time != null) {
                                    ref.read(playerProvider.notifier).seek(
                                          Duration(milliseconds: (line.time! * 1000).toInt()),
                                        );
                                  }
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  height: 80,
                                  alignment: Alignment.center,
                                  child: Text(
                                    line.text,
                                    textAlign: TextAlign.center,
                                    style: isActive
                                        ? AppTypography.headlineMedium.copyWith(
                                            color: const Color(0xFFCFBCFF), // Synced Gold-purple shade
                                            fontWeight: FontWeight.w800,
                                            shadows: [
                                              Shadow(
                                                color: AppColors.primary.withValues(alpha: 0.5),
                                                blurRadius: 20,
                                              )
                                            ],
                                          )
                                        : AppTypography.titleMedium.copyWith(
                                            color: Colors.white.withValues(alpha: opacity),
                                            fontWeight: FontWeight.bold,
                                          ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                    error: (err, stack) {
                      if (err.toString().contains('404')) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.music_off, color: Colors.white54, size: 48),
                              const SizedBox(height: 16),
                              Text(
                                'No lyrics found for this track.',
                                style: AppTypography.titleMedium.copyWith(color: AppColors.darkOnSurfaceVariant),
                              ),
                            ],
                          ),
                        );
                      }
                      return ErrorStateWidget(
                        onRetry: () => ref.refresh(lyricsProvider(LyricsQueryParams(
                          track: currentTrack.title,
                          artist: currentTrack.author,
                        ))),
                        message: 'Failed to load lyrics.',
                      );
                    },
                  ),
                ),

                // Bottom Miniature Progress Line
                lyricsAsync.maybeWhen(
                  data: (lyrics) {
                    return Consumer(
                      builder: (context, ref, child) {
                        final position = ref.watch(playerProvider.select((s) => s.position));
                        final duration = ref.watch(playerProvider.select((s) => s.duration));
                        final progress = duration.inMilliseconds > 0
                            ? position.inMilliseconds / duration.inMilliseconds
                            : 0.0;
                        return Container(
                          width: double.infinity,
                          height: 2,
                          color: AppColors.darkSurfaceVariant,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: progress.clamp(0.0, 1.0),
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [AppColors.primary, AppColors.tertiary],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
