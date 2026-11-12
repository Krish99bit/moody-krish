import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/music_provider.dart';
import '../../providers/playlist_provider.dart';
import '../theme/app_theme.dart';
import 'artwork_widget.dart';

class QueueSheet extends StatelessWidget {
  const QueueSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final queue = musicProvider.queue;
    final currentSong = musicProvider.currentSong;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 14),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Play Queue',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    '${queue.length} Tracks • Drag handle to reorder',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.playlist_add_rounded, color: AppTheme.primary, size: 24),
                    tooltip: 'Save Queue as Playlist',
                    onPressed: () => _promptSaveQueue(context, musicProvider),
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear_all_rounded, color: AppTheme.textSecondary, size: 24),
                    tooltip: 'Clear Queue',
                    onPressed: () {
                      for (int i = queue.length - 1; i >= 0; i--) {
                        if (queue[i].id != currentSong?.id) {
                          musicProvider.removeQueueItem(i);
                        }
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Now Playing Section
          if (currentSong != null) ...[
            const Text(
              'NOW PLAYING',
              style: TextStyle(
                color: AppTheme.primary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  ArtworkWidget(
                    artworkPath: currentSong.artworkPath,
                    seed: currentSong.title,
                    size: 42,
                    borderRadius: 6,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentSong.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          currentSong.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.equalizer_rounded, color: AppTheme.primary, size: 22),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Up Next Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'UP NEXT',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                musicProvider.isShuffle ? 'Smart Shuffle: ON' : 'Original Order',
                style: TextStyle(
                  color: musicProvider.isShuffle ? AppTheme.primary : AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Reorderable Queue
          Expanded(
            child: queue.isEmpty
                ? const Center(child: Text('Queue is empty', style: TextStyle(color: AppTheme.textMuted)))
                : ReorderableListView.builder(
                    itemCount: queue.length,
                    onReorder: (oldIndex, newIndex) {
                      musicProvider.reorderQueue(oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final song = queue[index];
                      final isSelected = currentSong?.filePath == song.filePath;

                      return Dismissible(
                        key: ValueKey('queue_${song.filePath}_$index'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: AppTheme.error,
                          child: const Icon(Icons.delete_rounded, color: Colors.white, size: 20),
                        ),
                        onDismissed: (_) => musicProvider.removeQueueItem(index),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          leading: ArtworkWidget(
                            artworkPath: song.artworkPath,
                            seed: song.title,
                            size: 38,
                            borderRadius: 6,
                          ),
                          title: Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                          ),
                          trailing: const Icon(Icons.drag_handle_rounded, color: AppTheme.textMuted),
                          onTap: () => musicProvider.playSong(song, contextQueue: queue, startIndex: index),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _promptSaveQueue(BuildContext context, MusicProvider musicProvider) {
    final controller = TextEditingController(text: 'Queue Mix');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Queue as Folder/Playlist', style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: AppTheme.textSecondary)),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.black),
            child: const Text('Save'),
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await musicProvider.saveCurrentQueueAsPlaylist(name);
                await context.read<PlaylistProvider>().loadPlaylists();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Saved queue as "$name"!'), backgroundColor: AppTheme.surfaceElevated),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
