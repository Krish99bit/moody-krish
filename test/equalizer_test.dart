import 'package:flutter_test/flutter_test.dart';
import 'package:moody_krish/data/models/playback_state.dart';
import 'package:moody_krish/services/equalizer_service.dart';

void main() {
  group('Equalizer Model & Presets Tests', () {
    test('12 Presets are defined with valid 5-band gain values within -10dB to +10dB', () {
      expect(EqualizerPreset.defaultPresets.length, 12);

      for (final preset in EqualizerPreset.defaultPresets) {
        expect(preset.gains.length, 5);
        for (final gain in preset.gains) {
          expect(gain >= -10.0 && gain <= 10.0, isTrue,
              reason: '${preset.name} gain $gain is out of -10..+10 range');
        }
      }
    });

    test('Band labels are 5 distinct frequency centers', () {
      expect(EqualizerPreset.bandLabels.length, 5);
      expect(EqualizerPreset.bandLabels, ['60 Hz', '230 Hz', '910 Hz', '3.6 kHz', '14 kHz']);
    });
  });

  group('EqualizerService State Tests', () {
    test('Clamps band gain to -10dB and +10dB limits', () {
      final service = EqualizerService();

      service.setBandGain(0, 15.0);
      expect(service.bandGains[0], 10.0);

      service.setBandGain(0, -25.0);
      expect(service.bandGains[0], -10.0);

      service.setBandGain(0, 4.5);
      expect(service.bandGains[0], 4.5);
    });

    test('Bass boost clamps between 0.0 and 1.0', () {
      final service = EqualizerService();

      service.setBassBoost(1.5);
      expect(service.bassBoost, 1.0);

      service.setBassBoost(-0.5);
      expect(service.bassBoost, 0.0);

      service.setBassBoost(0.65);
      expect(service.bassBoost, 0.65);
    });

    test('Reset to flat restores 0.0 dB across all bands and Flat preset', () {
      final service = EqualizerService();
      service.selectPreset(EqualizerPreset.defaultPresets[1]); // Bass Boost
      service.setBassBoost(0.8);

      service.resetToFlat();
      expect(service.currentPreset.name, 'Flat');
      expect(service.bassBoost, 0.0);
      for (final gain in service.bandGains) {
        expect(gain, 0.0);
      }
    });
  });
}
