import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/library_provider.dart';
import '../../providers/music_provider.dart';
import '../../providers/playlist_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/artwork_widget.dart';
import '../widgets/song_tile.dart';
import '../widgets/equalizer_sheet.dart';
import 'import_screen.dart';
import 'playlist_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good morning ☀️';
    } else if (hour >= 12 && hour < 17) {
      return 'Good afternoon 🌤️';
    } else if (hour >= 17 && hour < 22) {
      return 'Good evening 🌆';
    } else {
      return 'Good night 🌙';
    }
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final music = context.watch<MusicProvider>();
    final playlistProvider = context.watch<PlaylistProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_getGreeting()),
        actions: [
          IconButton(
            tooltip: 'Equalizer',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const EqualizerSheet(),
              );
            },
          ),
          // Plus (+) Icon on Home Screen
          IconButton(
            tooltip: 'Add / Create',
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.primary, size: 26),
            onPressed: () => _showHomeAddOptions(context, playlistProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        backgroundColor: AppTheme.surfaceElevated,
        onRefresh: () => library.refreshLibrary(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.only(bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Quick Jump Cards (Liked Songs & Custom Folders)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildQuickCard(
                        title: 'Liked Songs',
                        icon: Icons.favorite_rounded,
                        count: '${library.favoriteSongs.length} tracks',
                        gradient: const LinearGradient(
                          colors: [Color(0xFF450AF5), Color(0xFF8E8EE5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        onTap: () {
                          if (library.favoriteSongs.isNotEmpty) {
                            music.playSong(library.favoriteSongs.first, contextQueue: library.favoriteSongs);
                          } else {
                            _showSnackbar(context, 'No liked songs yet');
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildQuickCard(
                        title: 'Create Folder',
                        icon: Icons.create_new_folder_rounded,
                        count: 'e.g. Punjabi',
                        gradient: const LinearGradient(
                          colors: [Color(0xFF006450), Color(0xFF1DB954)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        onTap: () => _showCreateFolderDialog(context, playlistProvider),
                      ),
                    ),
                  ],
                ),
              ),

              // Empty Library Welcome
              if (library.allSongs.isEmpty && !library.isLoading)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.music_off_rounded, size: 54, color: AppTheme.textMuted),
                      const SizedBox(height: 12),
                      const Text(
                        'Your Vault is Empty',
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Upload your downloaded audio tracks or folders to start listening offline.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add Offline Songs', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ImportScreen()));
                        },
                      ),
                    ],
                  ),
                ),

              // 2. Continue Listening (Smart Playlist)
              if (library.continueListening.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 18, 16, 10),
                  child: Text(
                    'Continue Listening',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                ),
                SizedBox(
                  height: 175,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: library.continueListening.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final song = library.continueListening[index];
                      return GestureDetector(
                        onTap: () => music.playSong(song, contextQueue: library.continueListening, startIndex: index),
                        child: SizedBox(
                          width: 120,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  ArtworkWidget(artworkPath: song.artworkPath, seed: song.title, size: 120, borderRadius: 10),
                                  Container(
                                    margin: const EdgeInsets.all(6),
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                                    child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 18),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],

              // 3. Custom User Folders (e.g. Punjabi, Gym)
              if (playlistProvider.playlists.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Your Custom Folders',
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 16, color: AppTheme.primary),
                        label: const Text('New Folder', style: TextStyle(color: AppTheme.primary, fontSize: 12)),
                        onPressed: () => _showCreateFolderDialog(context, playlistProvider),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: playlistProvider.playlists.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final p = playlistProvider.playlists[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => PlaylistDetailScreen(playlist: p)));
                        },
                        child: Container(
                          width: 150,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.folder_special_rounded, color: AppTheme.primary, size: 28),
                              const SizedBox(height: 6),
                              Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text('${p.songCount} tracks', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],

              // 4. Recently Added
              if (library.recentlyAdded.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Text(
                    'Recently Added to Vault',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: library.recentlyAdded.length.clamp(0, 10),
                  itemBuilder: (context, index) {
                    final song = library.recentlyAdded[index];
                    return SongTile(song: song, contextQueue: library.recentlyAdded, index: index);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showHomeAddOptions(BuildContext context, PlaylistProvider playlistProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.audio_file_rounded, color: AppTheme.primary, size: 28),
              title: const Text('Import Downloaded Songs', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Add MP3s or scan local folders to vault'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ImportScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.create_new_folder_rounded, color: AppTheme.primary, size: 28),
              title: const Text('Create Custom Folder (e.g. Punjabi)', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Group specific songs into your own custom folder'),
              onTap: () {
                Navigator.pop(ctx);
                _showCreateFolderDialog(context, playlistProvider);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateFolderDialog(BuildContext context, PlaylistProvider playlistProvider) {
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Custom Folder', style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: titleController,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'e.g. Punjabi, Gym, Romantic',
            labelText: 'Folder Name',
            labelStyle: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(ctx)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.black),
            child: const Text('Create'),
            onPressed: () async {
              final name = titleController.text.trim();
              if (name.isNotEmpty) {
                await playlistProvider.createPlaylist(name);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Created folder "$name"!'), backgroundColor: AppTheme.surfaceElevated),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCard({
    required String title,
    required IconData icon,
    required String count,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(color: AppTheme.surfaceElevated, borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(gradient: gradient, borderRadius: const BorderRadius.horizontal(left: Radius.circular(8))),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(count, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.surfaceElevated),
    );
  }
}
