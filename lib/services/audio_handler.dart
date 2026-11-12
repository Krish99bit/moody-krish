import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AudioPlayerHandler> initAudioService() async {
  return await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.moodykrish.music.audio',
      androidNotificationChannelName: 'Moody Krish Music Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      androidNotificationIcon: 'mipmap/ic_launcher',
      androidShowNotificationBadge: true,
    ),
  );
}

class AudioPlayerHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AndroidEqualizer _equalizer = AndroidEqualizer();
  final AndroidLoudnessEnhancer _loudnessEnhancer = AndroidLoudnessEnhancer();
  late final AudioPlayer _player;
  int _currentIndex = 0;
  List<MediaItem> _currentQueue = [];
  List<MediaItem> _originalQueue = [];
  bool _isShuffle = false;
  bool _isHandlingCompletion = false;
  AudioServiceRepeatMode _currentRepeatMode = AudioServiceRepeatMode.none;

  AudioPlayer get player => _player;
  int get currentIndex => _currentIndex;
  bool get isShuffle => _isShuffle;
  AndroidEqualizer get equalizer => _equalizer;
  AndroidLoudnessEnhancer get loudnessEnhancer => _loudnessEnhancer;

  AudioPlayerHandler() {
    _player = AudioPlayer(
      audioPipeline: AudioPipeline(
        androidAudioEffects: [_equalizer, _loudnessEnhancer],
      ),
    );
    _initAudioSession();
    _listenToPlaybackEvents();
  }

  Future<void> setEqualizerEnabled(bool enabled) async {
    try {
      await _equalizer.setEnabled(enabled);
    } catch (_) {}
  }

  Future<void> setEqualizerBandGain(int bandIndex, double gainDb) async {
    try {
      final params = await _equalizer.parameters;
      if (bandIndex >= 0 && bandIndex < params.bands.length) {
        await params.bands[bandIndex].setGain(gainDb);
      }
    } catch (_) {}
  }

  Future<void> setEqualizerGains(List<double> gains) async {
    try {
      final params = await _equalizer.parameters;
      for (int i = 0; i < gains.length && i < params.bands.length; i++) {
        await params.bands[i].setGain(gains[i]);
      }
    } catch (_) {}
  }

  Future<void> setBassBoostGain(double boostNormalized) async {
    try {
      final targetGainMb = (boostNormalized * 1000.0).round();
      await _loudnessEnhancer.setEnabled(boostNormalized > 0.05);
      await _loudnessEnhancer.setTargetGain(targetGainMb.toDouble());
    } catch (_) {}
  }

  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // Pause when headphones are unplugged
    session.becomingNoisyEventStream.listen((_) {
      pause();
    });

    // Handle incoming phone calls or other audio focus changes
    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        switch (event.type) {
          case AudioInterruptionType.duck:
            _player.setVolume(0.3);
            break;
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            pause();
            break;
        }
      } else {
        switch (event.type) {
          case AudioInterruptionType.duck:
            _player.setVolume(1.0);
            break;
          case AudioInterruptionType.pause:
            play();
            break;
          case AudioInterruptionType.unknown:
            break;
        }
      }
    });
  }

  void _listenToPlaybackEvents() {
    // Broadcast player state changes to audio_service
    _player.playbackEventStream.listen((PlaybackEvent event) {
      final playing = _player.playing;
      final processingState = const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!;

      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
          MediaAction.setShuffleMode,
          MediaAction.setRepeatMode,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: processingState,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _currentIndex,
      ));

      // Handle song completion with guard against re-entrant calls
      if (_player.processingState == ProcessingState.completed) {
        if (!_isHandlingCompletion) {
          _isHandlingCompletion = true;
          skipToNext().then((_) {
            _isHandlingCompletion = false;
          }).catchError((_) {
            _isHandlingCompletion = false;
          });
        }
      }
    });

    // Save playback position periodically (throttled to avoid flash disk thrashing)
    DateTime lastSave = DateTime.fromMillisecondsSinceEpoch(0);
    _player.positionStream.listen((pos) {
      final now = DateTime.now();
      if (now.difference(lastSave).inSeconds >= 5) {
        lastSave = now;
        _savePositionToPreferences(pos.inMilliseconds);
      }
    });
  }

  Future<void> _savePositionToPreferences(int posMs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_playback_pos_ms', posMs);
    } catch (_) {}
  }

  // --- PLAYBACK COMMANDS ---

  @override
  Future<void> play() async {
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    if (_currentQueue.isEmpty) return;

    // If Repeat One is active, restart current track
    if (_currentRepeatMode == AudioServiceRepeatMode.one) {
      await seek(Duration.zero);
      await play();
      return;
    }

    if (_currentIndex < _currentQueue.length - 1) {
      await skipToQueueItem(_currentIndex + 1);
    } else {
      // Reached the end of queue
      if (_currentRepeatMode == AudioServiceRepeatMode.all || _currentRepeatMode == AudioServiceRepeatMode.group) {
        if (_isShuffle && _currentQueue.length > 1) {
          // Re-shuffle for a fresh cycle
          final items = List<MediaItem>.from(_currentQueue)..shuffle();
          _currentQueue = items;
          queue.add(_currentQueue);
        }
        await skipToQueueItem(0);
      } else {
        // Repeat off: stop at end of playlist
        await pause();
        await seek(Duration.zero);
      }
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_currentQueue.isEmpty) return;
    // If played more than 3 seconds, restart current track
    if (_player.position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }
    if (_currentIndex > 0) {
      await skipToQueueItem(_currentIndex - 1);
    } else {
      await skipToQueueItem(_currentQueue.length - 1);
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _currentQueue.length) return;
    _currentIndex = index;
    final item = _currentQueue[index];
    mediaItem.add(item);

    try {
      await _player.setFilePath(item.id);
      final duration = _player.duration;
      if (duration != null && duration.inMilliseconds > 0) {
        mediaItem.add(item.copyWith(duration: duration));
      }
      await play();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_played_song_path', item.id);
    } catch (e) {
      // Failed to play file, skip to next
      if (_currentQueue.length > 1 && _currentIndex < _currentQueue.length - 1) {
        await skipToNext();
      }
    }
  }

  @override
  Future<void> updateQueue(List<MediaItem> newQueue) async {
    _originalQueue = List.from(newQueue);
    if (_isShuffle && newQueue.length > 1) {
      final current = (_currentIndex >= 0 && _currentIndex < newQueue.length)
          ? newQueue[_currentIndex]
          : newQueue[0];
      final others = List<MediaItem>.from(newQueue)..remove(current)..shuffle();
      _currentQueue = [current, ...others];
      _currentIndex = 0;
    } else {
      _currentQueue = List.from(newQueue);
    }
    queue.add(_currentQueue);
  }

  @override
  Future<void> addQueueItem(MediaItem item) async {
    _originalQueue.add(item);
    _currentQueue.add(item);
    queue.add(_currentQueue);
  }

  Future<void> insertNextInQueue(MediaItem item) async {
    final insertIndex = (_currentIndex + 1).clamp(0, _currentQueue.length);
    _currentQueue.insert(insertIndex, item);
    _originalQueue.add(item);
    queue.add(_currentQueue);
  }

  @override
  Future<void> removeQueueItem(MediaItem item) async {
    _originalQueue.removeWhere((i) => i.id == item.id);
    final index = _currentQueue.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _currentQueue.removeAt(index);
      if (index < _currentIndex) {
        _currentIndex--;
      }
      queue.add(_currentQueue);
    }
  }

  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _currentQueue.removeAt(oldIndex);
    _currentQueue.insert(newIndex, item);

    if (_currentIndex == oldIndex) {
      _currentIndex = newIndex;
    } else if (oldIndex < _currentIndex && newIndex >= _currentIndex) {
      _currentIndex--;
    } else if (oldIndex > _currentIndex && newIndex <= _currentIndex) {
      _currentIndex++;
    }

    queue.add(_currentQueue);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    _currentRepeatMode = repeatMode;
    LoopMode loopMode;
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        loopMode = LoopMode.off;
        break;
      case AudioServiceRepeatMode.one:
        loopMode = LoopMode.one;
        break;
      case AudioServiceRepeatMode.all:
      case AudioServiceRepeatMode.group:
        loopMode = LoopMode.all;
        break;
    }
    await _player.setLoopMode(loopMode);
    playbackState.add(playbackState.value.copyWith(repeatMode: repeatMode));
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    final enableShuffle = shuffleMode != AudioServiceShuffleMode.none;
    _isShuffle = enableShuffle;

    if (_currentQueue.length > 1) {
      final currentItem = (_currentIndex >= 0 && _currentIndex < _currentQueue.length)
          ? _currentQueue[_currentIndex]
          : null;

      if (_isShuffle) {
        // Shuffle everything except the currently playing song
        final remaining = List<MediaItem>.from(_currentQueue);
        if (currentItem != null) {
          remaining.remove(currentItem);
        }
        remaining.shuffle();
        if (currentItem != null) {
          _currentQueue = [currentItem, ...remaining];
          _currentIndex = 0;
        } else {
          _currentQueue = remaining;
          _currentIndex = 0;
        }
      } else {
        // Restore original unshuffled queue
        if (_originalQueue.isNotEmpty) {
          _currentQueue = List.from(_originalQueue);
          if (currentItem != null) {
            final originalIdx = _currentQueue.indexWhere((i) => i.id == currentItem.id);
            _currentIndex = originalIdx != -1 ? originalIdx : 0;
          }
        }
      }
      queue.add(_currentQueue);
    }

    playbackState.add(playbackState.value.copyWith(shuffleMode: shuffleMode));
  }
}
