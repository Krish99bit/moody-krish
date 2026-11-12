import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/playback_state.dart';
import '../../providers/music_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_visualizer.dart';
import '../widgets/artwork_widget.dart';
import '../widgets/equalizer_sheet.dart';
import '../widgets/lyrics_sheet.dart';
import '../widgets/queue_sheet.dart';
import '../widgets/sleep_timer_sheet.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final currentSong = musicProvider.currentSong;

    if (currentSong == null) {
      return const Scaffold(
        body: Center(child: Text('No song selected', style: TextStyle(color: AppTheme.textSecondary))),
      );
    }

    final duration = musicProvider.duration;
    final position = musicProvider.position;
    final durationMs = duration.inMilliseconds.toDouble();
    final positionMs = position.inMilliseconds.toDouble().clamp(0.0, durationMs > 0 ? durationMs : 0.0);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            children: [
              // 1. Top Action Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Column(
                    children: [
                      const Text(
                        'PLAYING FROM MOODY KRISH VAULT',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currentSong.album,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      musicProvider.showVisualizer ? Icons.graphic_eq_rounded : Icons.equalizer_rounded,
                      color: musicProvider.showVisualizer ? AppTheme.primary : AppTheme.textSecondary,
                    ),
                    tooltip: 'Toggle Visualizer',
                    onPressed: () => musicProvider.toggleVisualizer(),
                  ),
                ],
              ),
              const Spacer(flex: 1),

              // 2. High-Res Artwork / Animated Visualizer Switch
              Center(
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(musicProvider.isPlaying ? 0.35 : 0.15),
                            blurRadius: 35,
                            spreadRadius: 2,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: ArtworkWidget(
                        artworkPath: currentSong.artworkPath,
                        seed: currentSong.title,
                        size: MediaQuery.of(context).size.width * 0.78,
                        borderRadius: 24,
                      ),
                    ),
                    if (musicProvider.showVisualizer) ...[
                      const SizedBox(height: 12),
                      const AnimatedVisualizer(height: 40),
                    ],
                  ],
                ),
              ),
              const Spacer(flex: 1),

              // 3. Track Title & Artist & Favorite Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentSong.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentSong.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      currentSong.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: currentSong.isFavorite ? AppTheme.primary : AppTheme.textSecondary,
                      size: 28,
                    ),
                    onPressed: () => musicProvider.toggleFavorite(currentSong),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 4. Scrubber / Slider
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppTheme.primary,
                  inactiveTrackColor: Colors.white12,
                  thumbColor: Colors.white,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  trackHeight: 3.5,
                ),
                child: Slider(
                  value: positionMs,
                  min: 0.0,
                  max: durationMs > 0 ? durationMs : 1.0,
                  onChanged: (val) {
                    musicProvider.seek(Duration(milliseconds: val.toInt()));
                  },
                ),
              ),

              // Time labels
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDuration(position), style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                    Text(_formatDuration(duration), style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // 5. Main Playback Controls (Shuffle, Prev, Play/Pause, Next, Repeat)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.shuffle_rounded,
                      color: musicProvider.isShuffle ? AppTheme.primary : AppTheme.textMuted,
                      size: 24,
                    ),
                    tooltip: 'Smart Non-Repeating Shuffle',
                    onPressed: () => musicProvider.toggleShuffle(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_previous_rounded, size: 40, color: AppTheme.textPrimary),
                    onPressed: () => musicProvider.skipPrevious(),
                  ),
                  GestureDetector(
                    onTap: () => musicProvider.togglePlayPause(),
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: const BoxDecoration(
                        color: AppTheme.textPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        musicProvider.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.black,
                        size: 40,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded, size: 40, color: AppTheme.textPrimary),
                    onPressed: () => musicProvider.skipNext(),
                  ),
                  IconButton(
                    icon: _buildRepeatIcon(musicProvider.repeatMode),
                    tooltip: 'Repeat Mode',
                    onPressed: () => musicProvider.cycleRepeatMode(),
                  ),
                ],
              ),
              const Spacer(flex: 1),

              // 6. Secondary Toolbar (Lyrics with Karaoke, Equalizer, Sleep Timer, Queue)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      tooltip: 'Lyrics & Karaoke',
                      icon: const Icon(Icons.lyrics_rounded, color: AppTheme.textSecondary, size: 22),
                      onPressed: () => _showModal(context, const LyricsSheet()),
                    ),
                    IconButton(
                      tooltip: 'Equalizer',
                      icon: const Icon(Icons.tune_rounded, color: AppTheme.textSecondary, size: 22),
                      onPressed: () => _showModal(context, const EqualizerSheet()),
                    ),
                    IconButton(
                      tooltip: 'Sleep Timer',
                      icon: const Icon(Icons.bedtime_outlined, color: AppTheme.textSecondary, size: 22),
                      onPressed: () => _showModal(context, const SleepTimerSheet()),
                    ),
                    IconButton(
                      tooltip: 'Up Next Queue',
                      icon: const Icon(Icons.queue_music_rounded, color: AppTheme.textSecondary, size: 22),
                      onPressed: () => _showModal(context, const QueueSheet()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRepeatIcon(CustomRepeatMode mode) {
    switch (mode) {
      case CustomRepeatMode.off:
        return const Icon(Icons.repeat_rounded, color: AppTheme.textMuted, size: 24);
      case CustomRepeatMode.all:
        return const Icon(Icons.repeat_rounded, color: AppTheme.primary, size: 24);
      case CustomRepeatMode.one:
        return const Icon(Icons.repeat_one_rounded, color: AppTheme.primary, size: 24);
    }
  }

  void _showModal(BuildContext context, Widget sheet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => sheet,
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
