import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/playlist.dart';
import '../../data/models/song.dart';
import '../../providers/library_provider.dart';
import '../../providers/music_provider.dart';
import '../../providers/playlist_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/song_tile.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({Key? key, required this.playlist}) : super(key: key);

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  List<Song> _songs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    final songs = await context.read<PlaylistProvider>().getSongsForPlaylist(widget.playlist.id!);
    if (mounted) {
      setState(() {
        _songs = songs;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final music = context.read<MusicProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlist.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.primary),
            tooltip: 'Add songs to this folder',
            onPressed: () => _showAddSongsModal(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error),
            tooltip: 'Delete folder',
            onPressed: () => _confirmDeletePlaylist(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : CustomScrollView(
              slivers: [
                // Header with Mosaic / Playlist Art and Play Buttons
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            gradient: AppTheme.albumGradient(widget.playlist.name),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.queue_music_rounded,
                            size: 64,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.playlist.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (widget.playlist.description != null && widget.playlist.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.playlist.description!,
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          '${_songs.length} tracks',
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        ),
                        const SizedBox(height: 16),

                        // Play All & Shuffle Buttons
                        if (_songs.isNotEmpty)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                ),
                                icon: const Icon(Icons.play_arrow_rounded, size: 24),
                                label: const Text('Play All', style: TextStyle(fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  music.playSong(_songs.first, contextQueue: _songs);
                                },
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.textPrimary,
                                  side: const BorderSide(color: Colors.white24),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                ),
                                icon: const Icon(Icons.shuffle_rounded, size: 20),
                                label: const Text('Shuffle'),
                                onPressed: () {
                                  final shuffled = List<Song>.from(_songs)..shuffle();
                                  music.playSong(shuffled.first, contextQueue: shuffled);
                                },
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),

                // Track List
                if (_songs.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.folder_open_rounded, size: 54, color: AppTheme.textMuted),
                          const SizedBox(height: 12),
                          const Text(
                            'This folder is empty',
                            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Add your songs to this collection',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            ),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add Songs'),
                            onPressed: () => _showAddSongsModal(context),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final song = _songs[index];
                        return SongTile(
                          song: song,
                          contextQueue: _songs,
                          index: index,
                        );
                      },
                      childCount: _songs.length,
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
    );
  }

  void _showAddSongsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            final allSongs = context.read<LibraryProvider>().allSongs;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Text(
                    'Add Songs to "${widget.playlist.name}"',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: allSongs.isEmpty
                        ? const Center(
                            child: Text(
                              'No tracks found in library.\nImport some songs first!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: allSongs.length,
                            itemBuilder: (context, index) {
                              final song = allSongs[index];
                              final isAlreadyIn = _songs.any((s) => s.id == song.id);

                              return ListTile(
                                leading: const Icon(Icons.music_note_rounded, color: AppTheme.primary),
                                title: Text(song.title, style: const TextStyle(color: AppTheme.textPrimary)),
                                subtitle: Text(song.artist, style: const TextStyle(color: AppTheme.textSecondary)),
                                trailing: isAlreadyIn
                                    ? const Icon(Icons.check_circle_rounded, color: AppTheme.primary)
                                    : const Icon(Icons.add_circle_outline_rounded, color: AppTheme.textSecondary),
                                onTap: isAlreadyIn
                                    ? null
                                    : () async {
                                        await context.read<PlaylistProvider>().addSongToPlaylist(widget.playlist.id!, song);
                                        await _loadSongs();
                                        Navigator.pop(ctx);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Added "${song.title}" to ${widget.playlist.name}'),
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
      },
    );
  }

  void _confirmDeletePlaylist(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Playlist'),
        content: Text('Are you sure you want to delete "${widget.playlist.name}"?'),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: const Text('Delete', style: TextStyle(color: AppTheme.error)),
            onPressed: () async {
              await context.read<PlaylistProvider>().deletePlaylist(widget.playlist.id!);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
