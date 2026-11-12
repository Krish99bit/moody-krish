import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/music_provider.dart';
import '../theme/app_theme.dart';

class AnimatedVisualizer extends StatelessWidget {
  final double height;
  const AnimatedVisualizer({Key? key, this.height = 70.0}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final music = context.watch<MusicProvider>();
    final freqs = music.visualizerFrequencies;
    final isPlaying = music.isPlaying;

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(freqs.length, (index) {
          final level = isPlaying ? freqs[index] : 0.08;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 8,
            height: (height * level).clamp(6.0, height),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary,
                  AppTheme.primaryBright.withOpacity(0.8),
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                if (isPlaying && level > 0.4)
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
