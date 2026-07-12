import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import '../../../search/domain/entities/search_track.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/network/local_audio_proxy.dart';
import 'package:flutter/foundation.dart';

/// State representation of the audio player.
class PlayerState {
  final SearchTrack? currentTrack;
  final bool isPlaying;
  final bool isLoading;
  final String? errorMessage;
  final Duration position;
  final Duration duration;
  final List<SearchTrack> queue;
  final int currentIndex;

  const PlayerState({
    this.currentTrack,
    this.isPlaying = false,
    this.isLoading = false,
    this.errorMessage,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.queue = const [],
    this.currentIndex = -1,
  });

  PlayerState copyWith({
    SearchTrack? currentTrack,
    bool? isPlaying,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    Duration? position,
    Duration? duration,
    List<SearchTrack>? queue,
    int? currentIndex,
  }) {
    return PlayerState(
      currentTrack: currentTrack ?? this.currentTrack,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
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
  int _playGeneration = 0; // Monotonic counter to cancel stale plays

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

  /// Cleans a YouTube title by stripping common suffixes that confuse SoundCloud search
  /// e.g. "Adele - Rolling in the Deep (Official Music Video)" -> "Rolling in the Deep"
  String _cleanTitle(String title) {
    var cleaned = title;
    final patterns = [
      RegExp(r'\s*\(Official\s+(Music\s+)?Video\)', caseSensitive: false),
      RegExp(r'\s*\(Official\s+Lyric\s+Video\)', caseSensitive: false),
      RegExp(r'\s*\(Official\s+Audio\)', caseSensitive: false),
      RegExp(r'\s*\(Lyrics?\)', caseSensitive: false),
      RegExp(r'\s*\(Audio\)', caseSensitive: false),
      RegExp(r'\s*\(Music\s+Video\)', caseSensitive: false),
      RegExp(r'\s*\(Official\)', caseSensitive: false),
      RegExp(r'\s*\[Official\s+(Music\s+)?Video\]', caseSensitive: false),
      RegExp(r'\s*\|.*$', caseSensitive: false),
      RegExp(r'^\s*[\w\s]+\s+-\s+', caseSensitive: false), // "Artist - " prefix
    ];
    for (final p in patterns) {
      cleaned = cleaned.replaceAll(p, '');
    }
    return cleaned.trim();
  }

  /// Strips ft./feat./featuring credits from artist name for cleaner SoundCloud matching
  String _cleanArtist(String artist) {
    return artist
        .replaceAll(RegExp(r'\s+ft\.?\s+.*$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+feat\.?\s+.*$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+featuring\s+.*$', caseSensitive: false), '')
        .trim();
  }

  /// Resolves a working stream URL for a track by trying multiple backend strategies.
  /// Returns null if all strategies fail.
  Future<String?> _resolveStreamUrl(SearchTrack track) async {
    final cleanedTitle = _cleanTitle(track.title);
    final cleanedArtist = _cleanArtist(track.author);
    final encodedTitle = Uri.encodeComponent(cleanedTitle);
    final encodedArtist = Uri.encodeComponent(cleanedArtist);

    // Strategy 1: LocalAudioProxy
    if (LocalAudioProxy.instance.port != null) {
      debugPrint('[Stream] Using LocalAudioProxy for "${track.id}"');
      return 'http://127.0.0.1:${LocalAudioProxy.instance.port}/?id=${track.id}';
    }

    // Strategy 2: Backend SoundCloud via /api/stream?json=true (most reliable)
    try {
      debugPrint('[Stream] Trying /api/stream (SoundCloud) for "$cleanedTitle" by "$cleanedArtist"...');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/stream?json=true&id=${track.id}&title=$encodedTitle&artist=$encodedArtist'),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final audioUrl = data['url'] as String?;
        if (audioUrl != null && audioUrl.isNotEmpty) {
          final isHls = data['isHls'] == true;
          debugPrint('[Stream] /api/stream resolved (isHls=$isHls)');
          return audioUrl;
        }
      } else {
        debugPrint('[Stream] /api/stream status=${response.statusCode}: ${response.body.substring(0, response.body.length < 200 ? response.body.length : 200)}');
      }
    } catch (err) {
      debugPrint('[Stream] /api/stream failed: $err');
    }

    // Strategy 2: Backend yt-dlp worker /yt-stream
    try {
      debugPrint('[Stream] Trying /yt-stream for "${track.id}"...');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/yt-stream/${track.id}?title=$encodedTitle&artist=$encodedArtist'),
      ).timeout(const Duration(seconds: 25));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final audioUrl = data['audio_url'] as String?;
        if (audioUrl != null && audioUrl.isNotEmpty) {
          debugPrint('[Stream] /yt-stream resolved');
          return audioUrl;
        }
      } else {
        debugPrint('[Stream] /yt-stream status=${response.statusCode}');
      }
    } catch (err) {
      debugPrint('[Stream] /yt-stream failed: $err');
    }

    // Strategy 3: Retry /api/stream with title-only (drops artist if it was confusing the search)
    try {
      debugPrint('[Stream] Retrying /api/stream with title only...');
      final encodedTitleOnly = Uri.encodeComponent(cleanedTitle);
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/stream?json=true&id=${track.id}&title=$encodedTitleOnly'),
      ).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final audioUrl = data['url'] as String?;
        if (audioUrl != null && audioUrl.isNotEmpty) {
          debugPrint('[Stream] /api/stream (title-only) resolved');
          return audioUrl;
        }
      }
    } catch (err) {
      debugPrint('[Stream] /api/stream title-only failed: $err');
    }

    return null;
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
      isLoading: true,
      clearError: true,
    );

    await _playTrack(track);
  }

  Future<void> _playTrack(SearchTrack track) async {
    final generation = ++_playGeneration;

    try {
      final streamUrl = await _resolveStreamUrl(track);

      // If user already started playing another track, abandon this one
      if (generation != _playGeneration) {
        debugPrint('[Player] Aborting stale play for ${track.id}');
        return;
      }

      if (streamUrl == null || streamUrl.isEmpty) {
        throw Exception('Could not resolve a playable stream URL for "${track.title}" by "${track.author}"');
      }

      final uri = Uri.parse(streamUrl);
      final logLen = streamUrl.length < 100 ? streamUrl.length : 100;
      debugPrint('[Player] Loading: ${streamUrl.substring(0, logLen)}...');

      // CRITICAL: Stop and clear any currently playing source first.
      // Without this, setAudioSource can race with the previous load and
      // the old source keeps playing.
      await _audioPlayer.stop();
      if (generation != _playGeneration) return;

      // just_audio handles both progressive MP3 and HLS .m3u8 natively via AudioSource.uri()
      await _audioPlayer.setAudioSource(AudioSource.uri(uri));
      if (generation != _playGeneration) {
        await _audioPlayer.stop();
        return;
      }

      state = state.copyWith(isLoading: false, clearError: true);
      await _audioPlayer.play();
      _consecutiveFailures = 0; // Reset on successful load
    } catch (e) {
      // Race protection
      if (generation != _playGeneration) {
        debugPrint('[Player] Suppressing error from stale play: $e');
        return;
      }
      debugPrint('[Player] Stream resolution/playback failed: $e');
      if (e.toString().contains('interrupted')) {
        return;
      }
      try {
        await _audioPlayer.stop();
      } catch (_) {}

      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Couldn\'t play "${track.title}". Skipping to next...',
      );

      // Guard against infinite skip loop
      _consecutiveFailures++;
      if (_consecutiveFailures < _maxConsecutiveFailures) {
        await Future.delayed(const Duration(milliseconds: 1500));
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
      isLoading: true,
      clearError: true,
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
      isLoading: true,
      clearError: true,
    );
    _playTrack(state.queue[prevIndex]);
  }
}

/// Central Riverpod Provider for accessing the player state and controls.
final playerProvider = NotifierProvider<PlayerNotifier, PlayerState>(PlayerNotifier.new);
