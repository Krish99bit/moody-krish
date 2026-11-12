enum CustomRepeatMode {
  off,
  all,
  one,
}

enum EqualizerPresetType {
  flat,
  bassBoost,
  bassExtreme,
  rock,
  pop,
  jazz,
  classical,
  electronic,
  vocal,
  hipHop,
  acoustic,
  trebleBoost,
  custom,
}

class EqualizerPreset {
  final String name;
  final EqualizerPresetType type;
  final List<double> gains; // 5 bands in dB: -10.0 to +10.0

  const EqualizerPreset({
    required this.name,
    required this.type,
    required this.gains,
  });

  static const List<String> bandLabels = [
    '60 Hz',
    '230 Hz',
    '910 Hz',
    '3.6 kHz',
    '14 kHz',
  ];

  static const List<EqualizerPreset> defaultPresets = [
    EqualizerPreset(
      name: 'Flat',
      type: EqualizerPresetType.flat,
      gains: [0.0, 0.0, 0.0, 0.0, 0.0],
    ),
    EqualizerPreset(
      name: 'Bass Boost',
      type: EqualizerPresetType.bassBoost,
      gains: [6.0, 4.0, 1.0, 0.0, -1.0],
    ),
    EqualizerPreset(
      name: 'Bass Extreme',
      type: EqualizerPresetType.bassExtreme,
      gains: [9.5, 7.0, 2.0, -1.0, -2.5],
    ),
    EqualizerPreset(
      name: 'Rock',
      type: EqualizerPresetType.rock,
      gains: [4.5, 2.0, -1.0, 2.5, 4.0],
    ),
    EqualizerPreset(
      name: 'Pop',
      type: EqualizerPresetType.pop,
      gains: [-1.0, 2.0, 4.0, 2.0, -1.0],
    ),
    EqualizerPreset(
      name: 'Hip-Hop',
      type: EqualizerPresetType.hipHop,
      gains: [7.0, 4.5, 0.0, 2.0, 3.5],
    ),
    EqualizerPreset(
      name: 'Electronic',
      type: EqualizerPresetType.electronic,
      gains: [5.0, 3.5, 0.0, 2.0, 4.5],
    ),
    EqualizerPreset(
      name: 'Vocal Clarity',
      type: EqualizerPresetType.vocal,
      gains: [-2.0, 1.0, 5.0, 4.0, 1.0],
    ),
    EqualizerPreset(
      name: 'Acoustic',
      type: EqualizerPresetType.acoustic,
      gains: [3.5, 2.0, 1.0, 3.0, 3.5],
    ),
    EqualizerPreset(
      name: 'Treble Boost',
      type: EqualizerPresetType.trebleBoost,
      gains: [-2.0, -1.0, 1.0, 4.5, 8.0],
    ),
    EqualizerPreset(
      name: 'Jazz',
      type: EqualizerPresetType.jazz,
      gains: [3.0, 1.5, -1.5, 2.0, 3.5],
    ),
    EqualizerPreset(
      name: 'Classical',
      type: EqualizerPresetType.classical,
      gains: [4.0, 2.5, 0.0, 2.0, 3.0],
    ),
  ];
}

enum AppColorTheme {
  spotifyGreen,
  amoledBlack,
  cyberpunkPurple,
  oceanBlue,
}
