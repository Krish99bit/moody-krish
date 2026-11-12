import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/playback_state.dart';
import 'audio_handler.dart';

class EqualizerService extends ChangeNotifier {
  AudioPlayerHandler? _audioHandler;

  bool _enabled = true;
  EqualizerPreset _currentPreset = EqualizerPreset.defaultPresets[0];
  List<double> _bandGains = [0.0, 0.0, 0.0, 0.0, 0.0];
  double _bassBoost = 0.0; // 0.0 to 1.0
  double _virtualizer = 0.0; // 0.0 to 1.0
  
  // Audio Quality Enhancements
  int _crossfadeSeconds = 3; // 0 to 12s
  bool _gaplessPlayback = true;
  bool _volumeNormalization = true;

  bool get enabled => _enabled;
  EqualizerPreset get currentPreset => _currentPreset;
  List<double> get bandGains => List.unmodifiable(_bandGains);
  double get bassBoost => _bassBoost;
  double get virtualizer => _virtualizer;
  int get crossfadeSeconds => _crossfadeSeconds;
  bool get gaplessPlayback => _gaplessPlayback;
  bool get volumeNormalization => _volumeNormalization;

  EqualizerService() {
    _loadFromPreferences();
  }

  void attachAudioHandler(AudioPlayerHandler handler) {
    _audioHandler = handler;
    syncToAudioHandler();
  }

  void syncToAudioHandler() {
    if (_audioHandler == null) return;
    _audioHandler!.setEqualizerEnabled(_enabled);
    if (_enabled) {
      _audioHandler!.setEqualizerGains(_bandGains);
      _audioHandler!.setBassBoostGain(_bassBoost);
    }
  }

  Future<void> _loadFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool('eq_enabled') ?? true;
      _bassBoost = prefs.getDouble('eq_bass_boost') ?? 0.0;
      _virtualizer = prefs.getDouble('eq_virtualizer') ?? 0.0;
      _crossfadeSeconds = prefs.getInt('eq_crossfade') ?? 3;
      _gaplessPlayback = prefs.getBool('eq_gapless') ?? true;
      _volumeNormalization = prefs.getBool('eq_norm') ?? true;

      final gainsJson = prefs.getString('eq_band_gains');
      if (gainsJson != null) {
        final List<dynamic> decoded = jsonDecode(gainsJson);
        _bandGains = decoded.map((e) => (e as num).toDouble()).toList();
      }

      final presetName = prefs.getString('eq_preset_name');
      if (presetName != null) {
        _currentPreset = EqualizerPreset.defaultPresets.firstWhere(
          (p) => p.name == presetName,
          orElse: () => EqualizerPreset(
            name: 'Custom',
            type: EqualizerPresetType.custom,
            gains: List.from(_bandGains),
          ),
        );
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveToPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('eq_enabled', _enabled);
      await prefs.setDouble('eq_bass_boost', _bassBoost);
      await prefs.setDouble('eq_virtualizer', _virtualizer);
      await prefs.setInt('eq_crossfade', _crossfadeSeconds);
      await prefs.setBool('eq_gapless', _gaplessPlayback);
      await prefs.setBool('eq_norm', _volumeNormalization);
      await prefs.setString('eq_band_gains', jsonEncode(_bandGains));
      await prefs.setString('eq_preset_name', _currentPreset.name);
    } catch (_) {}
  }

  void toggleEnabled(bool value) {
    _enabled = value;
    _audioHandler?.setEqualizerEnabled(value);
    _saveToPreferences();
    notifyListeners();
  }

  void selectPreset(EqualizerPreset preset) {
    _currentPreset = preset;
    _bandGains = List.from(preset.gains);
    if (_enabled) {
      _audioHandler?.setEqualizerGains(_bandGains);
    }
    _saveToPreferences();
    notifyListeners();
  }

  void setBandGain(int bandIndex, double gain) {
    if (bandIndex >= 0 && bandIndex < _bandGains.length) {
      _bandGains[bandIndex] = gain.clamp(-10.0, 10.0);
      _currentPreset = EqualizerPreset(
        name: 'Custom',
        type: EqualizerPresetType.custom,
        gains: List.from(_bandGains),
      );
      if (_enabled) {
        _audioHandler?.setEqualizerBandGain(bandIndex, _bandGains[bandIndex]);
      }
      _saveToPreferences();
      notifyListeners();
    }
  }

  void setBassBoost(double value) {
    _bassBoost = value.clamp(0.0, 1.0);
    if (_enabled) {
      _audioHandler?.setBassBoostGain(_bassBoost);
    }
    _saveToPreferences();
    notifyListeners();
  }

  void setVirtualizer(double value) {
    _virtualizer = value.clamp(0.0, 1.0);
    _saveToPreferences();
    notifyListeners();
  }

  void setCrossfadeSeconds(int seconds) {
    _crossfadeSeconds = seconds.clamp(0, 12);
    _saveToPreferences();
    notifyListeners();
  }

  void toggleGapless(bool value) {
    _gaplessPlayback = value;
    _saveToPreferences();
    notifyListeners();
  }

  void toggleVolumeNormalization(bool value) {
    _volumeNormalization = value;
    _saveToPreferences();
    notifyListeners();
  }

  void resetToFlat() {
    selectPreset(EqualizerPreset.defaultPresets[0]);
    _bassBoost = 0.0;
    _virtualizer = 0.0;
    if (_enabled) {
      _audioHandler?.setBassBoostGain(0.0);
    }
    _saveToPreferences();
    notifyListeners();
  }
}
