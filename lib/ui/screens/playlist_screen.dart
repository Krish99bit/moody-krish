import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../data/database/db_helper.dart';
import '../../providers/library_provider.dart';
import '../../providers/music_provider.dart';
import '../../providers/playlist_provider.dart';
import '../theme/app_theme.dart';
import 'playlist_detail_screen.dart';

class PlaylistScreen extends StatelessWidget {
  const PlaylistScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final playlistProvider = context.watch<PlaylistProvider>();
    final libraryProvider = context.watch<LibraryProvider>();
    final playlists = playlistProvider.playlists;
    final favoriteSongs = libraryProvider.favoriteSongs;
    final mostPlayed = libraryProvider.mostPlayed;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlists & Folders'),
        actions: [
          // Backup & Restore button
          IconButton(
            icon: const Icon(Icons.backup_rounded, color: AppTheme.textSecondary),
            tooltip: 'Backup / Restore Library',
            onPressed: () => _showBackupRestoreDialog(context),
          ),
          // Top Plus (+) Icon to create folder
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 28, color: AppTheme.primary),
            tooltip: 'Create Custom Folder',
            onPressed: () => _showCreatePlaylistDialog(context, playlistProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.create_new_folder_rounded),
        label: const Text('New Folder', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _showCreatePlaylistDialog(context, playlistProvider),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          // 1. Smart Playlist: Liked Songs
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF450AF5), Color(0xFF8E8EE5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 28),
            ),
            title: const Text('Liked Songs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            subtitle: Text('${favoriteSongs.length} songs • Smart collection', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textMuted, size: 14),
            onTap: () {
              if (favoriteSongs.isNotEmpty) {
                context.read<MusicProvider>().playSong(favoriteSongs.first, contextQueue: favoriteSongs);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No liked songs yet. Tap heart on any song!')),
                );
              }
            },
          ),

          // 2. Smart Playlist: Most Played
          if (mostPlayed.isNotEmpty)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE65100), Color(0xFFFF9800)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 28),
              ),
              title: const Text('Most Played', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              subtitle: Text('${mostPlayed.length} songs • Top hits', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textMuted, size: 14),
              onTap: () {
                context.read<MusicProvider>().playSong(mostPlayed.first, contextQueue: mostPlayed);
              },
            ),

          const Divider(color: AppTheme.dividerColor, indent: 16, endIndent: 16),

          // 3. User Custom Folders Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'YOUR CUSTOM FOLDERS',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 16, color: AppTheme.primary),
                  label: const Text('Add Folder', style: TextStyle(color: AppTheme.primary, fontSize: 12)),
                  onPressed: () => _showCreatePlaylistDialog(context, playlistProvider),
                ),
              ],
            ),
          ),

          if (playlists.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.create_new_folder_outlined, size: 52, color: AppTheme.textMuted),
                    const SizedBox(height: 12),
                    const Text('Create your first custom folder', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    const Text('Group your songs into folders like "Punjabi", "Gym", etc.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.surfaceElevated, foregroundColor: AppTheme.textPrimary),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Create Folder (e.g. Punjabi)'),
                      onPressed: () => _showCreatePlaylistDialog(context, playlistProvider),
                    ),
                  ],
                ),
              ),
            )
          else
            ...playlists.map((playlist) {
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: AppTheme.albumGradient(playlist.name),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.folder_special_rounded, color: Colors.white70, size: 28),
                ),
                title: Text(playlist.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                subtitle: Text('${playlist.songCount} songs • Custom Folder', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textMuted, size: 14),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => PlaylistDetailScreen(playlist: playlist)));
                },
              );
            }),
        ],
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, PlaylistProvider playlistProvider) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Custom Folder', style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'e.g. Punjabi, Gym, Romantic',
                labelText: 'Folder Name',
                labelStyle: TextStyle(color: AppTheme.textSecondary),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primary)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descController,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                labelStyle: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(ctx)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.black),
            child: const Text('Create'),
            onPressed: () async {
              final name = titleController.text.trim();
              if (name.isNotEmpty) {
                await playlistProvider.createPlaylist(name, description: descController.text.trim());
                Navigator.pop(ctx);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showBackupRestoreDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Backup & Restore Library', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Export your custom folders, playlists, and favorites to transfer between devices.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 18),
            ListTile(
              leading: const Icon(Icons.file_upload_rounded, color: AppTheme.primary, size: 28),
              title: const Text('Export Library Backup', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Saves backup JSON file into device documents folder'),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  final json = await DatabaseHelper.instance.exportBackupData();
                  final appDocDir = await getApplicationDocumentsDirectory();
                  final timestamp = DateTime.now().millisecondsSinceEpoch;
                  final backupFile = File(p.join(appDocDir.path, 'moody_krish_backup_$timestamp.json'));
                  await backupFile.writeAsString(json);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Backup exported to ${p.basename(backupFile.path)}!'),
                      backgroundColor: AppTheme.primary,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to export backup'), backgroundColor: AppTheme.error),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_download_rounded, color: Color(0xFF1E88E5), size: 28),
              title: const Text('Restore Library Backup', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Pick and restore backup JSON file'),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['json'],
                  );
                  if (result != null && result.files.single.path != null) {
                    final file = File(result.files.single.path!);
                    final jsonString = await file.readAsString();
                    final success = await DatabaseHelper.instance.restoreBackupData(jsonString);
                    if (success) {
                      await context.read<LibraryProvider>().refreshLibrary();
                      await context.read<PlaylistProvider>().loadPlaylists();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Playlists and favorites restored successfully!'),
                          backgroundColor: AppTheme.primary,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invalid backup file format'), backgroundColor: AppTheme.error),
                      );
                    }
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not restore backup file'), backgroundColor: AppTheme.error),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
