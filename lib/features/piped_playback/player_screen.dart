import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'piped_service.dart';
import 'audio_handler.dart';

// Global singleton instance for standalone Piped playback
PipedAudioHandler? _pipedAudioHandler;

class PipedPlayerScreen extends StatefulWidget {
  const PipedPlayerScreen({super.key});

  @override
  State<PipedPlayerScreen> createState() => _PipedPlayerScreenState();
}

class _PipedPlayerScreenState extends State<PipedPlayerScreen> {
  final TextEditingController _searchController = TextEditingController();
  final PipedService _pipedService = PipedService();
  
  PipedAudioHandler? _handler;
  PipedSong? _currentSong;
  bool _isLoading = false;
  String _statusMessage = 'Search for a song to begin playback';

  @override
  void initState() {
    super.initState();
    _initAudioHandler();
  }

  Future<void> _initAudioHandler() async {
    if (_pipedAudioHandler == null) {
      try {
        _pipedAudioHandler = await AudioService.init(
          builder: () => PipedAudioHandler(),
          config: const AudioServiceConfig(
            androidNotificationChannelId: 'com.sumic.channel.audio.piped',
            androidNotificationChannelName: 'SUMIC Piped Playback',
            androidNotificationOngoing: true,
            androidShowNotificationBadge: true,
          ),
        );
      } catch (e) {
        debugPrint('[PipedPlayer] AudioService already initialized or failed: $e');
      }
    }
    if (mounted) {
      setState(() {
        _handler = _pipedAudioHandler;
      });
    }
  }

  Future<void> _performSearchAndPlay() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Searching Piped API...';
    });

    try {
      // 1. Search Piped
      final song = await _pipedService.searchSong(query);
      if (song == null) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'No songs found for "$query"';
        });
        return;
      }

      setState(() {
        _currentSong = song;
        _statusMessage = 'Resolving audio stream...';
      });

      // 2. Resolve Stream
      final streamUrl = await _pipedService.fetchAudioStream(song.id);
      if (streamUrl == null || streamUrl.isEmpty) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Could not extract audio stream';
        });
        return;
      }

      // 3. Play stream via AudioHandler
      if (_handler != null) {
        final mediaItem = MediaItem(
          id: song.id,
          title: song.title,
          artist: song.artist,
          artUri: Uri.parse(song.thumbnail),
          duration: Duration(seconds: song.durationSeconds),
        );
        
        setState(() {
          _statusMessage = 'Buffering stream...';
        });

        await _handler!.playStream(streamUrl, mediaItem);
      }

      setState(() {
        _isLoading = false;
        _statusMessage = 'Playing: ${song.title}';
      });
    } catch (e) {
      debugPrint('[PipedPlayer] Search/Play failed: $e');
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error occurred: $e';
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        title: const Text('Piped Music Streamer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF161626),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _handler == null
          ? const Center(child: CircularProgressIndicator(color: Colors.purpleAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Search Field
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter song title or artist...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF1E1E30),
                      prefixIcon: const Icon(Icons.music_note, color: Colors.purpleAccent),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search, color: Colors.purpleAccent),
                        onPressed: _performSearchAndPlay,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _performSearchAndPlay(),
                  ),
                  const SizedBox(height: 24),

                  // Status / Logs
                  Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 14, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 24),

                  // Album Art Card
                  Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E30),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purpleAccent.withOpacity(0.2),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        )
                      ],
                      image: _currentSong != null && _currentSong!.thumbnail.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(_currentSong!.thumbnail),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _currentSong == null
                        ? const Icon(Icons.music_video_rounded, size: 80, color: Colors.white24)
                        : null,
                  ),
                  const SizedBox(height: 32),

                  // Metadata Info
                  if (_currentSong != null) ...[
                    Text(
                      _currentSong!.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentSong!.artist,
                      style: const TextStyle(color: Colors.purpleAccent, fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ],
                  const SizedBox(height: 32),

                  // Progress & Sliders
                  StreamBuilder<PlaybackState>(
                    stream: _handler!.playbackState,
                    builder: (context, snapshot) {
                      final state = snapshot.data;
                      final processingState = state?.processingState ?? AudioProcessingState.idle;
                      final isBuffering = processingState == AudioProcessingState.buffering ||
                          processingState == AudioProcessingState.loading;
                      
                      return Column(
                        children: [
                          // Buffering spinner inside progress layout
                          if (isBuffering || _isLoading)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 12.0),
                              child: SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.purpleAccent),
                              ),
                            )
                          else
                            const SizedBox(height: 36),

                          // Current Position / Seek slider
                          StreamBuilder<Duration>(
                            stream: _handler!.player.positionStream,
                            builder: (context, posSnapshot) {
                              final currentPosition = posSnapshot.data ?? Duration.zero;
                              final totalDuration = _handler!.player.duration ?? Duration.zero;
                              
                              double sliderValue = 0.0;
                              if (totalDuration.inMilliseconds > 0) {
                                sliderValue = currentPosition.inMilliseconds / totalDuration.inMilliseconds;
                              }
                              sliderValue = sliderValue.clamp(0.0, 1.0);

                              return Column(
                                children: [
                                  SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      activeTrackColor: Colors.purpleAccent,
                                      inactiveTrackColor: Colors.white10,
                                      thumbColor: Colors.white,
                                      overlayColor: Colors.purpleAccent.withOpacity(0.1),
                                      trackHeight: 4,
                                    ),
                                    child: Slider(
                                      value: sliderValue,
                                      onChanged: (val) {
                                        final targetMs = (val * totalDuration.inMilliseconds).toInt();
                                        _handler!.seek(Duration(milliseconds: targetMs));
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _formatDuration(currentPosition),
                                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                                        ),
                                        Text(
                                          _formatDuration(totalDuration),
                                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Media Playback Controls
                  StreamBuilder<PlaybackState>(
                    stream: _handler!.playbackState,
                    builder: (context, snapshot) {
                      final state = snapshot.data;
                      final isPlaying = state?.playing ?? false;

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.replay_10, color: Colors.white, size: 32),
                            onPressed: () {
                              final current = _handler!.player.position;
                              _handler!.seek(current - const Duration(seconds: 10));
                            },
                          ),
                          const SizedBox(width: 24),
                          GestureDetector(
                            onTap: () {
                              if (isPlaying) {
                                _handler!.pause();
                              } else {
                                _handler!.play();
                              }
                            },
                            child: Container(
                              height: 72,
                              width: 72,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.purpleAccent,
                              ),
                              child: Icon(
                                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          IconButton(
                            icon: const Icon(Icons.forward_10, color: Colors.white, size: 32),
                            onPressed: () {
                              final current = _handler!.player.position;
                              _handler!.seek(current + const Duration(seconds: 10));
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
