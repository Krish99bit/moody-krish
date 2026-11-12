import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/music_provider.dart';
import '../screens/player_screen.dart';
import '../theme/app_theme.dart';
import 'artwork_widget.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final currentSong = musicProvider.currentSong;

    if (currentSong == null) {
      return const SizedBox.shrink();
    }

    final durationMs = musicProvider.duration.inMilliseconds;
    final positionMs = musicProvider.position.inMilliseconds;
    final progress = durationMs > 0 ? (positionMs / durationMs).clamp(0.0, 1.0) : 0.0;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const PlayerScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              const curve = Curves.easeOutCubic;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(position: animation.drive(tween), child: child);
            },
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Slim Progress Bar
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 2.5,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                children: [
                  // Artwork
                  ArtworkWidget(
                    artworkPath: currentSong.artworkPath,
                    seed: currentSong.title,
                    size: 44,
                    borderRadius: 6,
                  ),
                  const SizedBox(width: 12),

                  // Song Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          currentSong.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentSong.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Quick Favorite
                  IconButton(
                    icon: Icon(
                      currentSong.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: currentSong.isFavorite ? AppTheme.primary : AppTheme.textMuted,
                      size: 22,
                    ),
                    onPressed: () => musicProvider.toggleFavorite(currentSong),
                  ),

                  // Play / Pause
                  IconButton(
                    icon: Icon(
                      musicProvider.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: AppTheme.textPrimary,
                      size: 30,
                    ),
                    onPressed: () => musicProvider.togglePlayPause(),
                  ),

                  // Skip Next
                  IconButton(
                    icon: const Icon(
                      Icons.skip_next_rounded,
                      color: AppTheme.textPrimary,
                      size: 26,
                    ),
                    onPressed: () => musicProvider.skipNext(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
