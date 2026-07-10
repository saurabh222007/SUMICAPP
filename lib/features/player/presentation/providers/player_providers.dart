import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import '../../../search/domain/entities/search_track.dart';
import '../../../../core/network/api_config.dart';
import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// State representation of the audio player.
class PlayerState {
  final SearchTrack? currentTrack;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final List<SearchTrack> queue;
  final int currentIndex;

  const PlayerState({
    this.currentTrack,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.queue = const [],
    this.currentIndex = -1,
  });

  PlayerState copyWith({
    SearchTrack? currentTrack,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    List<SearchTrack>? queue,
    int? currentIndex,
  }) {
    return PlayerState(
      currentTrack: currentTrack ?? this.currentTrack,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }
}

/// Notifier class managing the audio player state using just_audio.
class PlayerNotifier extends Notifier<PlayerState> {
  late final AudioPlayer _audioPlayer;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  int _consecutiveFailures = 0;
  static const int _maxConsecutiveFailures = 3;

  @override
  PlayerState build() {
    _audioPlayer = AudioPlayer();
    _audioPlayer.setVolume(1.0);
    _initAudioPlayerListeners();
    
    ref.onDispose(() {
      _positionSubscription?.cancel();
      _durationSubscription?.cancel();
      _audioPlayer.dispose();
    });

    return const PlayerState();
  }

  void _initAudioPlayerListeners() {
    // Listen to play/pause state
    _audioPlayer.playingStream.listen((playing) {
      state = state.copyWith(isPlaying: playing);
    });

    // Listen to position changes
    _positionSubscription = _audioPlayer.positionStream.listen((pos) {
      state = state.copyWith(position: pos);
    });

    // Listen to duration changes
    _durationSubscription = _audioPlayer.durationStream.listen((dur) {
      if (dur != null) {
        state = state.copyWith(duration: dur);
      }
    });

    // Listen to playback completion
    _audioPlayer.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        _consecutiveFailures = 0; // Reset on successful completion
        next();
      }
    });
  }

  /// Sets the queue and starts playing from the specified index.
  Future<void> setQueue(List<SearchTrack> tracks, {int startIndex = 0}) async {
    if (tracks.isEmpty) return;
    
    state = state.copyWith(
      queue: tracks,
      currentIndex: startIndex,
      currentTrack: tracks[startIndex],
    );

    await _playTrack(tracks[startIndex]);
  }

  /// Plays a single track.
  Future<void> playTrack(SearchTrack track) async {
    _consecutiveFailures = 0; // Reset on user-initiated play
    final newQueue = List<SearchTrack>.from(state.queue);
    int index = newQueue.indexWhere((t) => t.id == track.id);
    
    if (index == -1) {
      newQueue.add(track);
      index = newQueue.length - 1;
    }

    state = state.copyWith(
      queue: newQueue,
      currentIndex: index,
      currentTrack: track,
    );

    await _playTrack(track);
  }

  Future<void> _playTrack(SearchTrack track) async {
    try {
      String? streamUrl;

      // ── Tier 1: Client-side resolution via youtube_explode_dart ──
      try {
        debugPrint('[Tier1] Trying youtube_explode for ${track.id}...');
        final yt = YoutubeExplode();
        final manifest = await yt.videos.streamsClient.getManifest(track.id);
        final streams = manifest.streams;
        if (streams.isNotEmpty) {
          final audioStream = manifest.audioOnly.isNotEmpty
              ? manifest.audioOnly.withHighestBitrate()
              : (manifest.muxed.isNotEmpty ? manifest.muxed.withHighestBitrate() : streams.first);
          streamUrl = audioStream.url.toString();
          debugPrint('[Tier1] youtube_explode resolved stream OK');
        }
        yt.close();
      } catch (err) {
        debugPrint('[Tier1] youtube_explode failed: $err');
      }

      // ── Tier 2: Backend /yt-stream endpoint (yt-dlp → SoundCloud fallback) ──
      if (streamUrl == null) {
        try {
          debugPrint('[Tier2] Trying /yt-stream/${track.id} ...');
          final response = await http.get(
            Uri.parse('${ApiConfig.baseUrl}/yt-stream/${track.id}'),
          ).timeout(const Duration(seconds: 25));
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            final audioUrl = data['audio_url'] as String?;
            if (audioUrl != null && audioUrl.isNotEmpty) {
              streamUrl = audioUrl;
              debugPrint('[Tier2] /yt-stream resolved OK');
            }
          } else {
            debugPrint('[Tier2] /yt-stream returned status ${response.statusCode}');
          }
        } catch (err) {
          debugPrint('[Tier2] /yt-stream failed: $err');
        }
      }

      // ── Tier 3: Existing SoundCloud HLS redirect via /api/stream.m3u8 ──
      if (streamUrl == null) {
        debugPrint('[Tier3] Falling back to /api/stream.m3u8 ...');
        final encodedTitle = Uri.encodeComponent(track.title);
        final encodedArtist = Uri.encodeComponent(track.author);
        streamUrl = '${ApiConfig.baseUrl}/api/stream.m3u8?id=${track.id}&title=$encodedTitle&artist=$encodedArtist';
      }

      final uri = Uri.parse(streamUrl);
      final logLen = streamUrl.length < 80 ? streamUrl.length : 80;
      debugPrint('[Player] Loading source: ${streamUrl.substring(0, logLen)}...');

      // just_audio handles both progressive and HLS URLs natively via AudioSource.uri()
      await _audioPlayer.setAudioSource(AudioSource.uri(uri));
      _audioPlayer.play();
      _consecutiveFailures = 0; // Reset on successful load
    } catch (e) {
      debugPrint('Stream resolution and playback failed: $e');
      if (e.toString().contains('interrupted')) {
        return;
      }
      _audioPlayer.stop();
      
      // Guard against infinite skip loop
      _consecutiveFailures++;
      if (_consecutiveFailures < _maxConsecutiveFailures) {
        await Future.delayed(const Duration(milliseconds: 1000));
        next();
      } else {
        debugPrint('[Player] Stopped auto-skip after $_maxConsecutiveFailures consecutive failures.');
        _consecutiveFailures = 0;
      }
    }
  }

  /// Pause/Resume toggle.
  void togglePlay() {
    if (state.currentTrack == null) return;
    
    if (_audioPlayer.playing) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.play();
    }
  }

  /// Seek to a specific duration position.
  void seek(Duration duration) {
    _audioPlayer.seek(duration);
  }

  /// Plays the next song in the queue.
  void next() {
    if (state.queue.isEmpty || state.currentIndex == -1) return;
    
    final nextIndex = (state.currentIndex + 1) % state.queue.length;
    state = state.copyWith(
      currentIndex: nextIndex,
      currentTrack: state.queue[nextIndex],
    );
    _playTrack(state.queue[nextIndex]);
  }

  /// Plays the previous song in the queue.
  void previous() {
    if (state.queue.isEmpty || state.currentIndex == -1) return;

    final prevIndex = (state.currentIndex - 1 + state.queue.length) % state.queue.length;
    state = state.copyWith(
      currentIndex: prevIndex,
      currentTrack: state.queue[prevIndex],
    );
    _playTrack(state.queue[prevIndex]);
  }
}

/// Central Riverpod Provider for accessing the player state and controls.
final playerProvider = NotifierProvider<PlayerNotifier, PlayerState>(PlayerNotifier.new);
