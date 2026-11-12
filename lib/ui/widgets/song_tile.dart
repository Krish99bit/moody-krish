import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/song.dart';
import '../../providers/music_provider.dart';
import '../../providers/playlist_provider.dart';
import '../../providers/library_provider.dart';
import '../theme/app_theme.dart';
import 'artwork_widget.dart';

class SongTile extends StatelessWidget {
  final Song song;
  final List<Song>? contextQueue;
  final int? index;
  final VoidCallback? onCustomTap;

  const SongTile({
    Key? key,
    required this.song,
    this.contextQueue,
    this.index,
    this.onCustomTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final isCurrentSong = musicProvider.currentSong?.filePath == song.filePath;
    final isPlaying = isCurrentSong && musicProvider.isPlaying;

    return InkWell(
      onTap: onCustomTap ??
          () {
            musicProvider.playSong(
              song,
              contextQueue: contextQueue,
              startIndex: index,
            );
          },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            // Artwork / playing indicator
            Stack(
              alignment: Alignment.center,
              children: [
                ArtworkWidget(
                  artworkPath: song.artworkPath,
                  seed: song.title,
                  size: 48,
                  borderRadius: 6,
                ),
                if (isPlaying)
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.equalizer_rounded,
                      color: AppTheme.primary,
                      size: 26,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),

            // Song Title and Artist
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isCurrentSong ? AppTheme.primary : AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const Text(
                        ' • ',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      ),
                      Text(
                        song.durationFormatted,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Favorite quick toggle
            IconButton(
              icon: Icon(
                song.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: song.isFavorite ? AppTheme.primary : AppTheme.textMuted,
                size: 20,
              ),
              onPressed: () {
                musicProvider.toggleFavorite(song);
                context.read<LibraryProvider>().refreshLibrary();
              },
            ),

            // More Options Menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textSecondary, size: 20),
              color: AppTheme.surfaceElevated,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (value) => _handleMenuAction(context, value),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'play_next',
                  child: Row(
                    children: [
                      Icon(Icons.playlist_play_rounded, color: AppTheme.textPrimary, size: 20),
                      SizedBox(width: 12),
                      Text('Play Next'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'add_queue',
                  child: Row(
                    children: [
                      Icon(Icons.queue_music_rounded, color: AppTheme.textPrimary, size: 20),
                      SizedBox(width: 12),
                      Text('Add to Queue'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'add_playlist',
                  child: Row(
                    children: [
                      Icon(Icons.playlist_add_rounded, color: AppTheme.textPrimary, size: 20),
                      SizedBox(width: 12),
                      Text('Add to Playlist'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit_tags',
                  child: Row(
                    children: [
                      Icon(Icons.edit_note_rounded, color: AppTheme.textPrimary, size: 20),
                      SizedBox(width: 12),
                      Text('Edit Metadata Tags'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'details',
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: AppTheme.textPrimary, size: 20),
                      SizedBox(width: 12),
                      Text('Song Info'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 20),
                      SizedBox(width: 12),
                      Text('Delete', style: TextStyle(color: AppTheme.error)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    final music = context.read<MusicProvider>();
    final library = context.read<LibraryProvider>();
    final playlist = context.read<PlaylistProvider>();

    switch (action) {
      case 'play_next':
        music.playNext(song);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Playing next: ${song.title}'),
            backgroundColor: AppTheme.surfaceElevated,
            duration: const Duration(seconds: 1),
          ),
        );
        break;
      case 'add_queue':
        music.addToQueue(song);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added to queue: ${song.title}'),
            backgroundColor: AppTheme.surfaceElevated,
            duration: const Duration(seconds: 1),
          ),
        );
        break;
      case 'add_playlist':
        _showAddToPlaylistDialog(context, playlist);
        break;
      case 'edit_tags':
        _showEditTagsDialog(context, library);
        break;
      case 'details':
        _showDetailsDialog(context);
        break;
      case 'delete':
        _confirmDelete(context, library);
        break;
    }
  }

  void _showAddToPlaylistDialog(BuildContext context, PlaylistProvider playlistProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final playlists = playlistProvider.playlists;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add to Playlist',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 12),
              if (playlists.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(
                    child: Text('No playlists created yet.', style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: playlists.length,
                    itemBuilder: (c, i) {
                      final p = playlists[i];
                      return ListTile(
                        leading: const Icon(Icons.queue_music_rounded, color: AppTheme.primary),
                        title: Text(p.name, style: const TextStyle(color: AppTheme.textPrimary)),
                        subtitle: Text('${p.songCount} songs', style: const TextStyle(color: AppTheme.textSecondary)),
                        onTap: () async {
                          await playlistProvider.addSongToPlaylist(p.id!, song);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added to ${p.name}'),
                              backgroundColor: AppTheme.surfaceElevated,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showEditTagsDialog(BuildContext context, LibraryProvider library) {
    final titleCtrl = TextEditingController(text: song.title);
    final artistCtrl = TextEditingController(text: song.artist);
    final albumCtrl = TextEditingController(text: song.album);
    final genreCtrl = TextEditingController(text: song.genre);
    final yearCtrl = TextEditingController(text: song.year != null ? '${song.year}' : '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Metadata Tags', style: TextStyle(color: AppTheme.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
              TextField(controller: artistCtrl, decoration: const InputDecoration(labelText: 'Artist')),
              TextField(controller: albumCtrl, decoration: const InputDecoration(labelText: 'Album')),
              TextField(controller: genreCtrl, decoration: const InputDecoration(labelText: 'Genre')),
              TextField(controller: yearCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Year')),
            ],
          ),
        ),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(ctx)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.black),
            child: const Text('Save'),
            onPressed: () async {
              await library.updateMetadata(
                song,
                title: titleCtrl.text.trim(),
                artist: artistCtrl.text.trim(),
                album: albumCtrl.text.trim(),
                genre: genreCtrl.text.trim(),
                year: int.tryParse(yearCtrl.text.trim()),
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tags updated!'), backgroundColor: AppTheme.surfaceElevated),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showDetailsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(song.title, style: const TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Artist', song.artist),
            _detailRow('Album', song.album),
            _detailRow('Duration', song.durationFormatted),
            _detailRow('File Size', song.formattedFileSize),
            _detailRow('Plays', '${song.playCount} times'),
            _detailRow('Location', song.filePath),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Close', style: TextStyle(color: AppTheme.primary)),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          Text(value, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, LibraryProvider libraryProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Song'),
        content: Text('Are you sure you want to remove "${song.title}" from your library?'),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: const Text('Delete', style: TextStyle(color: AppTheme.error)),
            onPressed: () async {
              await libraryProvider.deleteSong(song);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }
}
