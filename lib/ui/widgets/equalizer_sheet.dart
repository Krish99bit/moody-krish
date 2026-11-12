import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/playback_state.dart';
import '../../services/equalizer_service.dart';
import '../theme/app_theme.dart';

class EqualizerSheet extends StatelessWidget {
  const EqualizerSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final eq = context.watch<EqualizerService>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header & Master Switch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Equalizer',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Switch(
                value: eq.enabled,
                activeColor: AppTheme.primary,
                onChanged: (val) => eq.toggleEnabled(val),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Presets Horizontal List
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: EqualizerPreset.defaultPresets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final preset = EqualizerPreset.defaultPresets[index];
                final isSelected = eq.currentPreset.name == preset.name;
                return ChoiceChip(
                  label: Text(preset.name),
                  selected: isSelected,
                  selectedColor: AppTheme.primary,
                  backgroundColor: AppTheme.cardColor,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : AppTheme.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  onSelected: eq.enabled ? (_) => eq.selectPreset(preset) : null,
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // 5-Band Vertical Equalizer Sliders
          Expanded(
            child: Opacity(
              opacity: eq.enabled ? 1.0 : 0.35,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (index) {
                  final gain = eq.bandGains[index];
                  final label = EqualizerPreset.bandLabels[index];

                  return Column(
                    children: [
                      Text(
                        '${gain > 0 ? '+' : ''}${gain.toStringAsFixed(1)} dB',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: Slider(
                            value: gain,
                            min: -10.0,
                            max: 10.0,
                            activeColor: AppTheme.primary,
                            inactiveColor: Colors.white12,
                            onChanged: eq.enabled
                                ? (val) => eq.setBandGain(index, val)
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Bass Boost & Virtualizer Knobs/Sliders
          Opacity(
            opacity: eq.enabled ? 1.0 : 0.35,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.speaker_rounded, color: AppTheme.primary, size: 20),
                      const SizedBox(width: 8),
                      const Text('Bass Boost', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text('${(eq.bassBoost * 100).toInt()}%', style: const TextStyle(color: AppTheme.primary, fontSize: 13)),
                    ],
                  ),
                  Slider(
                    value: eq.bassBoost,
                    min: 0.0,
                    max: 1.0,
                    activeColor: AppTheme.primary,
                    inactiveColor: Colors.white12,
                    onChanged: eq.enabled ? (val) => eq.setBassBoost(val) : null,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.surround_sound_rounded, color: AppTheme.primary, size: 20),
                      const SizedBox(width: 8),
                      const Text('3D Virtualizer', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text('${(eq.virtualizer * 100).toInt()}%', style: const TextStyle(color: AppTheme.primary, fontSize: 13)),
                    ],
                  ),
                  Slider(
                    value: eq.virtualizer,
                    min: 0.0,
                    max: 1.0,
                    activeColor: AppTheme.primary,
                    inactiveColor: Colors.white12,
                    onChanged: eq.enabled ? (val) => eq.setVirtualizer(val) : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Reset button
          TextButton.icon(
            icon: const Icon(Icons.restart_alt_rounded, color: AppTheme.textSecondary, size: 18),
            label: const Text('Reset to Flat', style: TextStyle(color: AppTheme.textSecondary)),
            onPressed: eq.enabled ? () => eq.resetToFlat() : null,
          ),
        ],
      ),
    );
  }
}
