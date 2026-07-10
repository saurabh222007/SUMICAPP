import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/themes/app_colors.dart';
import '../../../../shared/themes/app_typography.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../player/presentation/providers/player_providers.dart';
import '../../../playlist/presentation/providers/playlist_providers.dart';
import '../providers/search_providers.dart';
import '../../../../shared/widgets/error_state_widget.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  Timer? _debounce;
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Songs', 'Artists', 'Albums', 'Playlists'];

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() {
        _query = query;
      });
    });
  }

  void _showImportPlaylistDialog() {
    final urlController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) {
        bool isImporting = false;
        String? errorText;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: GlassContainer(
                borderRadius: 24.0,
                backgroundColor: AppColors.darkSurfaceContainer.withValues(alpha: 0.9),
                borderColor: AppColors.primary.withValues(alpha: 0.2),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Import Playlist',
                      style: AppTypography.titleMedium.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Convert Spotify or Apple Music playlists directly into a playable SUMIC playlist.',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.darkOnSurfaceVariant, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: urlController,
                      enabled: !isImporting,
                      style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Paste playlist link...',
                        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.darkOnSurfaceVariant.withValues(alpha: 0.5)),
                        filled: true,
                        fillColor: const Color(0xFF0D0D12),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.darkSurfaceVariant),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary),
                        ),
                        errorText: errorText,
                      ),
                    ),
                    if (isImporting)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          'Importing tracks... (this may take up to a minute)',
                          style: AppTypography.caption.copyWith(color: AppColors.primary),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isImporting ? null : () => Navigator.pop(context),
                          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: isImporting
                              ? null
                              : () async {
                                  final url = urlController.text.trim();
                                  if (url.isEmpty) {
                                    setDialogState(() => errorText = 'Link cannot be empty');
                                    return;
                                  }

                                  setDialogState(() {
                                    isImporting = true;
                                    errorText = null;
                                  });

                                  try {
                                    // Trigger import provider future
                                    final imported = await ref.read(importPlaylistProvider(url).future);
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      // Route to imported playlist detail screen
                                      context.push('/playlist/${imported.id}');
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      setDialogState(() {
                                        isImporting = false;
                                        errorText = 'Import failed. Check URL & try again.';
                                      });
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: isImporting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                                )
                              : const Text('Import', style: TextStyle(color: Colors.black)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchAsync = ref.watch(searchResultsProvider(_query));

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Search', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          // Import playlist option trigger
          IconButton(
            icon: const Icon(Icons.playlist_add, color: AppColors.primary, size: 28),
            tooltip: 'Import Playlist',
            onPressed: _showImportPlaylistDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Input Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            key: const ValueKey('search_input_container'),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: AppTypography.bodyMedium.copyWith(color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: AppColors.darkOnSurfaceVariant),
                hintText: 'Artists, songs, or playlists',
                hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.darkOnSurfaceVariant.withValues(alpha: 0.5)),
                filled: true,
                fillColor: AppColors.darkSurfaceContainerHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, color: AppColors.darkOnSurfaceVariant),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Filters Category Bar
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: SizedBox(
              height: 40,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = _selectedFilter == filter;
                  return Container(
                    margin: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.darkSurfaceContainerHigh,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.black : AppColors.darkOnSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? Colors.transparent : AppColors.darkSurfaceVariant.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Results Section
          Expanded(
            child: _query.trim().isEmpty
                ? _buildEmptyState()
                : searchAsync.when(
                    data: (tracks) {
                      if (tracks.isEmpty) {
                        return const Center(child: Text('No results found.', style: TextStyle(color: Colors.white60)));
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                        itemCount: tracks.length,
                        itemBuilder: (context, index) {
                          final track = tracks[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: CachedNetworkImage(
                                  imageUrl: track.thumbnail,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: AppColors.darkSurfaceVariant,
                                    width: 48,
                                    height: 48,
                                    child: const Icon(Icons.music_note, color: Colors.white38),
                                  ),
                                ),
                              ),
                              title: Text(
                                track.title,
                                style: AppTypography.titleMedium.copyWith(color: Colors.white, fontSize: 15),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '${track.author} • ${track.duration}',
                                style: AppTypography.caption.copyWith(color: AppColors.darkOnSurfaceVariant),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.more_vert, color: AppColors.darkOnSurfaceVariant),
                                onPressed: () {},
                              ),
                              onTap: () {
                                // Add track to playback queue and play immediately
                                ref.read(playerProvider.notifier).playTrack(track);
                              },
                            ),
                          );
                        },
                      );
                    },
                    loading: () => ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                      itemCount: 5,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.darkSurfaceVariant.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          title: Container(
                            height: 14,
                            width: 150,
                            color: AppColors.darkSurfaceVariant.withValues(alpha: 0.5),
                          ),
                          subtitle: Container(
                            height: 10,
                            width: 100,
                            margin: const EdgeInsets.only(top: 8),
                            color: AppColors.darkSurfaceVariant.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    ),
                    error: (error, stack) => ErrorStateWidget(
                      onRetry: () => ref.refresh(searchResultsProvider(_query)),
                      message: 'Failed to search tracks.',
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: AppColors.darkOnSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            'Search for songs on YouTube',
            style: AppTypography.titleMedium.copyWith(color: AppColors.darkOnSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            'Type a query above or click the + icon to import a Spotify playlist.',
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(color: AppColors.darkOnSurfaceVariant.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}
