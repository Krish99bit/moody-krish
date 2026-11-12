import 'dart:async';
import 'package:flutter/foundation.dart';

enum SleepTimerMode {
  none,
  minutes15,
  minutes30,
  minutes45,
  minutes60,
  endOfSong,
  custom,
}

class SleepTimerService extends ChangeNotifier {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  SleepTimerMode _mode = SleepTimerMode.none;
  VoidCallback? _onTimerComplete;

  bool get isActive => _timer != null && _timer!.isActive;
  Duration get remaining => _remaining;
  SleepTimerMode get mode => _mode;

  void initialize({required VoidCallback onTimerComplete}) {
    _onTimerComplete = onTimerComplete;
  }

  void startTimer(Duration duration, SleepTimerMode mode) {
    cancelTimer();
    _remaining = duration;
    _mode = mode;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining.inSeconds > 0) {
        _remaining = _remaining - const Duration(seconds: 1);
        notifyListeners();
      } else {
        cancelTimer();
        _onTimerComplete?.call();
      }
    });
  }

  void setEndOfSongMode() {
    cancelTimer();
    _mode = SleepTimerMode.endOfSong;
    notifyListeners();
  }

  void onSongEnded() {
    if (_mode == SleepTimerMode.endOfSong) {
      cancelTimer();
      _onTimerComplete?.call();
    }
  }

  void cancelTimer() {
    _timer?.cancel();
    _timer = null;
    _remaining = Duration.zero;
    _mode = SleepTimerMode.none;
    notifyListeners();
  }

  String get formattedRemaining {
    final minutes = _remaining.inMinutes;
    final seconds = _remaining.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}
