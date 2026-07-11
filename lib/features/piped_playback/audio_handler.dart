import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// Background Audio Handler using just_audio and audio_service.
class PipedAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  PipedAudioHandler() {
    // Forward playback events to audio_service listeners
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);

    // Monitor position stream to update position changes
    _player.positionStream.listen((pos) {
      final state = playbackState.value;
      playbackState.add(state.copyWith(updatePosition: pos));
    });

    // Monitor duration stream to update media item duration
    _player.durationStream.listen((dur) {
      if (dur != null && mediaItem.value != null) {
        mediaItem.add(mediaItem.value!.copyWith(duration: dur));
      }
    });

    // Handle completed state
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        stop();
      }
    });
  }

  /// Plays a stream URL.
  Future<void> playStream(String url, MediaItem item) async {
    mediaItem.add(item);
    try {
      await _player.setAudioSource(AudioSource.uri(Uri.parse(url)));
      play();
    } catch (e) {
      playbackState.add(playbackState.value.copyWith(
        errorMessage: e.toString(),
      ));
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    await playbackState.firstWhere((state) => state.processingState == AudioProcessingState.idle);
  }

  /// Expose the just_audio player instance for custom status queries
  AudioPlayer get player => _player;

  /// Helper mapping just_audio events to audio_service state representation
  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }
}
