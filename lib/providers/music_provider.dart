import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/database/db_helper.dart';
import '../data/models/playback_state.dart';
import '../data/models/song.dart';
import '../services/audio_handler.dart';
import '../services/sleep_timer_service.dart';

class MusicProvider extends ChangeNotifier {
  final AudioPlayerHandler _audioHandler;
  final SleepTimerService _sleepTimerService;

  Song? _currentSong;
  List<Song> _queue = [];
  int _queueIndex = 0;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isShuffle = false;
  CustomRepeatMode _repeatMode = CustomRepeatMode.off;
  double _playbackSpeed = 1.0;

  // Visualizer & Karaoke States
  bool _showVisualizer = false;
  List<double> _visualizerFrequencies = [0.2, 0.4, 0.7, 0.5, 0.8, 0.6, 0.3, 0.5];
  List<LrcLine> _parsedLyrics = [];
  int _currentLyricIndex = -1;

  Song? get currentSong => _currentSong;
  List<Song> get queue => List.unmodifiable(_queue);
  int get queueIndex => _queueIndex;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isShuffle => _isShuffle;
  CustomRepeatMode get repeatMode => _repeatMode;
  double get playbackSpeed => _playbackSpeed;
  bool get showVisualizer => _showVisualizer;
  List<double> get visualizerFrequencies => List.unmodifiable(_visualizerFrequencies);
  List<LrcLine> get parsedLyrics => List.unmodifiable(_parsedLyrics);
  int get currentLyricIndex => _currentLyricIndex;

  StreamSubscription? _playerStateSub;
  StreamSubscription? _mediaItemSub;
  StreamSubscription? _posSub;
  StreamSubscription? _queueSub;
  StreamSubscription? _endOfTrackSub;
  Timer? _visualizerTimer;

  MusicProvider(this._audioHandler, this._sleepTimerService) {
    _initListeners();
    _sleepTimerService.initialize(onTimerComplete: () {
      pause();
    });
    restoreLastSession();
  }

  void _initListeners() {
    // 1. Playback state changes
    _playerStateSub = _audioHandler.playbackState.listen((state) {
      final playing = state.playing;
      if (_isPlaying != playing) {
        _isPlaying = playing;
        if (_isPlaying) {
          _startVisualizerSimulation();
        } else {
          _stopVisualizerSimulation();
        }
        notifyListeners();
      }
    });

    // 2. MediaItem changes
    _mediaItemSub = _audioHandler.mediaItem.listen((item) async {
      if (item != null) {
        _duration = item.duration ?? Duration.zero;
        Song? matchedSong;
        final index = _queue.indexWhere((s) => s.filePath == item.id);
        if (index != -1) {
          _queueIndex = index;
          matchedSong = _queue[index];
        } else {
          matchedSong = await DatabaseHelper.instance.getSongByPath(item.id);
        }

        if (matchedSong != null && matchedSong.id != _currentSong?.id) {
          _currentSong = matchedSong;
          _parseSongLyrics(_currentSong?.lyrics);
          if (_currentSong!.id != null) {
            DatabaseHelper.instance.recordPlay(_currentSong!.id!);
          }
        }
        notifyListeners();
      }
    });

    // 3. Audio position stream
    _posSub = _audioHandler.player.positionStream.listen((pos) {
      _position = pos;
      _updateKaraokeIndex(pos);
      notifyListeners();
    });

    // 4. Audio queue updates
    _queueSub = _audioHandler.queue.listen((mediaQueue) {
      if (mediaQueue.isNotEmpty) {
        final List<Song> updatedSongs = [];
        for (final item in mediaQueue) {
          final existing = _queue.firstWhere(
            (s) => s.filePath == item.id,
            orElse: () => Song(
              title: item.title,
              artist: item.artist ?? 'Unknown Artist',
              album: item.album ?? 'Unknown Album',
              duration: item.duration?.inMilliseconds ?? 0,
              filePath: item.id,
              fileSize: 0,
              dateAdded: DateTime.now(),
            ),
          );
          updatedSongs.add(existing);
        }
        _queue = updatedSongs;
        if (_currentSong != null) {
          _queueIndex = _queue.indexWhere((s) => s.filePath == _currentSong!.filePath);
          if (_queueIndex == -1) _queueIndex = 0;
        }
        notifyListeners();
      }
    });

    // End of track detection
    _endOfTrackSub = _audioHandler.playbackState.listen((state) {
      if (state.processingState == AudioProcessingState.completed) {
        _sleepTimerService.onSongEnded();
      }
    });
  }

  void _parseSongLyrics(String? raw) {
    if (raw != null && raw.contains('[')) {
      _parsedLyrics = LrcLine.parseLrc(raw);
    } else {
      _parsedLyrics = [];
    }
    _currentLyricIndex = -1;
  }

  void _updateKaraokeIndex(Duration currentPos) {
    if (_parsedLyrics.isEmpty) return;
    int foundIndex = -1;
    for (int i = 0; i < _parsedLyrics.length; i++) {
      if (currentPos >= _parsedLyrics[i].timestamp) {
        foundIndex = i;
      } else {
        break;
      }
    }
    if (_currentLyricIndex != foundIndex) {
      _currentLyricIndex = foundIndex;
      notifyListeners();
    }
  }

  void toggleVisualizer() {
    _showVisualizer = !_showVisualizer;
    notifyListeners();
  }

  void _startVisualizerSimulation() {
    _visualizerTimer?.cancel();
    _visualizerTimer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      if (_isPlaying) {
        _visualizerFrequencies = List.generate(8, (i) {
          final base = 0.2 + (i % 3) * 0.2;
          final rand = (DateTime.now().millisecond % 50) / 100.0;
          return (base + rand).clamp(0.1, 1.0);
        });
        notifyListeners();
      }
    });
  }

  void _stopVisualizerSimulation() {
    _visualizerTimer?.cancel();
    _visualizerFrequencies = [0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1];
    notifyListeners();
  }

  Future<void> restoreLastSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSongPath = prefs.getString('last_played_song_path');
      final lastPosMs = prefs.getInt('last_playback_pos_ms') ?? 0;

      if (lastSongPath != null) {
        final song = await DatabaseHelper.instance.getSongByPath(lastSongPath);
        if (song != null) {
          _currentSong = song;
          _parseSongLyrics(song.lyrics);
          _position = Duration(milliseconds: lastPosMs);
          _duration = Duration(milliseconds: song.duration);
          _queue = [song];
          _queueIndex = 0;

          await _audioHandler.updateQueue([song.toMediaItem()]);
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  Future<void> playSong(Song song, {List<Song>? contextQueue, int? startIndex}) async {
    if (contextQueue != null && contextQueue.isNotEmpty) {
      _queue = List.from(contextQueue);
      _queueIndex = startIndex ?? _queue.indexWhere((s) => s.filePath == song.filePath);
      if (_queueIndex == -1) _queueIndex = 0;
    } else {
      _queue = [song];
      _queueIndex = 0;
    }

    _currentSong = song;
    _parseSongLyrics(song.lyrics);
    notifyListeners();

    final mediaItems = _queue.map((s) => s.toMediaItem()).toList();
    await _audioHandler.updateQueue(mediaItems);
    await _audioHandler.skipToQueueItem(_queueIndex);
  }

  Future<void> togglePlayPause() async {
    if (_currentSong == null && _queue.isNotEmpty) {
      await playSong(_queue[0]);
      return;
    }
    if (_isPlaying) {
      await _audioHandler.pause();
    } else {
      await _audioHandler.play();
    }
  }

  Future<void> pause() async {
    await _audioHandler.pause();
  }

  Future<void> skipNext() async {
    await _audioHandler.skipToNext();
  }

  Future<void> skipPrevious() async {
    await _audioHandler.skipToPrevious();
  }

  Future<void> seek(Duration pos) async {
    _position = pos;
    notifyListeners();
    await _audioHandler.seek(pos);
  }

  Future<void> toggleShuffle() async {
    _isShuffle = !_isShuffle;
    await _audioHandler.setShuffleMode(
      _isShuffle ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none,
    );
    notifyListeners();
  }

  Future<void> cycleRepeatMode() async {
    switch (_repeatMode) {
      case CustomRepeatMode.off:
        _repeatMode = CustomRepeatMode.all;
        await _audioHandler.setRepeatMode(AudioServiceRepeatMode.all);
        break;
      case CustomRepeatMode.all:
        _repeatMode = CustomRepeatMode.one;
        await _audioHandler.setRepeatMode(AudioServiceRepeatMode.one);
        break;
      case CustomRepeatMode.one:
        _repeatMode = CustomRepeatMode.off;
        await _audioHandler.setRepeatMode(AudioServiceRepeatMode.none);
        break;
    }
    notifyListeners();
  }

  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed;
    await _audioHandler.player.setSpeed(speed);
    notifyListeners();
  }

  Future<void> toggleFavorite(Song song) async {
    if (song.id == null) return;
    final newFavorite = !song.isFavorite;
    await DatabaseHelper.instance.toggleFavorite(song.id!, newFavorite);

    final updated = song.copyWith(isFavorite: newFavorite);
    if (_currentSong?.id == song.id) {
      _currentSong = updated;
    }

    final index = _queue.indexWhere((s) => s.id == song.id);
    if (index != -1) {
      _queue[index] = updated;
    }

    notifyListeners();
  }

  Future<void> updateLyrics(Song song, String newLyrics) async {
    if (song.id == null) return;
    await DatabaseHelper.instance.updateLyrics(song.id!, newLyrics);
    final updated = song.copyWith(lyrics: newLyrics);

    if (_currentSong?.id == song.id) {
      _currentSong = updated;
      _parseSongLyrics(newLyrics);
    }
    notifyListeners();
  }

  Future<void> addToQueue(Song song) async {
    _queue.add(song);
    await _audioHandler.addQueueItem(song.toMediaItem());
    notifyListeners();
  }

  Future<void> playNext(Song song) async {
    final nextIndex = (_queueIndex + 1).clamp(0, _queue.length);
    _queue.insert(nextIndex, song);
    await _audioHandler.insertNextInQueue(song.toMediaItem());
    notifyListeners();
  }

  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) newIndex -= 1;
    final song = _queue.removeAt(oldIndex);
    _queue.insert(newIndex, song);

    if (_queueIndex == oldIndex) {
      _queueIndex = newIndex;
    } else if (oldIndex < _queueIndex && newIndex >= _queueIndex) {
      _queueIndex--;
    } else if (oldIndex > _queueIndex && newIndex <= _queueIndex) {
      _queueIndex++;
    }

    await _audioHandler.reorderQueue(oldIndex, newIndex);
    notifyListeners();
  }

  Future<void> removeQueueItem(int index) async {
    if (index < 0 || index >= _queue.length) return;
    final song = _queue[index];
    _queue.removeAt(index);
    if (index < _queueIndex) {
      _queueIndex--;
    }
    await _audioHandler.removeQueueItem(song.toMediaItem());
    notifyListeners();
  }

  Future<int> saveCurrentQueueAsPlaylist(String playlistName) async {
    if (_queue.isEmpty) return 0;
    final id = await DatabaseHelper.instance.createPlaylist(playlistName, description: 'Saved from play queue');
    for (final song in _queue) {
      if (song.id != null) {
        await DatabaseHelper.instance.addSongToPlaylist(id, song.id!);
      }
    }
    return id;
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _mediaItemSub?.cancel();
    _posSub?.cancel();
    _queueSub?.cancel();
    _endOfTrackSub?.cancel();
    _visualizerTimer?.cancel();
    super.dispose();
  }
}
