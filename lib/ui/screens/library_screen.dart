import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/song.dart';
import '../../providers/library_provider.dart';
import '../../providers/music_provider.dart';
import '../../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/artwork_widget.dart';
import '../widgets/song_tile.dart';
import 'import_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Library'),
        actions: [
          // Missing files cleaner
          if (library.missingFiles.isNotEmpty)
            IconButton(
              icon: Badge(
                label: Text('${library.missingFiles.length}'),
                child: const Icon(Icons.cleaning_services_rounded, color: Colors.amber),
              ),
              tooltip: 'Clean missing files',
              onPressed: () => _confirmCleanMissing(context, library),
            ),
          // Storage Management & Library Size Tracking
          IconButton(
            icon: const Icon(Icons.pie_chart_outline_rounded),
            tooltip: 'Storage & Library Size',
            onPressed: () => _showStorageSheet(context),
          ),
          // Sort Options Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort by',
            color: AppTheme.surfaceElevated,
            onSelected: (criteria) {
              final isCurrent = library.sortBy == criteria;
              final newAsc = isCurrent ? !library.sortAscending : true;
              library.setSorting(criteria, newAsc);
            },
            itemBuilder: (context) => [
              _buildSortItem('title', 'Title', library),
              _buildSortItem('artist', 'Artist', library),
              _buildSortItem('date_added', 'Date Added', library),
              _buildSortItem('duration', 'Duration', library),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 28),
            tooltip: 'Add songs',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ImportScreen()));
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppTheme.primary,
          indicatorWeight: 3,
          labelColor: AppTheme.textPrimary,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            const Tab(text: 'Songs'),
            const Tab(text: 'Albums'),
            const Tab(text: 'Artists'),
            const Tab(text: 'Folders'),
            Tab(
              child: Row(
                children: [
                  const Text('Duplicates'),
                  if (library.duplicates.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(10)),
                      child: Text('${library.duplicates.length}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSongsTab(library),
          _buildAlbumsTab(library),
          _buildArtistsTab(library),
          _buildFoldersTab(library),
          _buildDuplicatesTab(library),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildSortItem(String criteria, String label, LibraryProvider library) {
    final isSelected = library.sortBy == criteria;
    return PopupMenuItem(
      value: criteria,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isSelected ? AppTheme.primary : AppTheme.textPrimary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          if (isSelected)
            Icon(library.sortAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: AppTheme.primary, size: 16),
        ],
      ),
    );
  }

  Widget _buildSongsTab(LibraryProvider library) {
    if (library.isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    if (library.allSongs.isEmpty) return _buildEmptyState('No tracks in library yet');

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 120),
      itemCount: library.allSongs.length,
      itemBuilder: (context, index) {
        final song = library.allSongs[index];
        return SongTile(
          song: song,
          contextQueue: library.allSongs,
          index: index,
        );
      },
    );
  }

  Widget _buildAlbumsTab(LibraryProvider library) {
    final albums = library.albums;
    if (albums.isEmpty) return _buildEmptyState('No albums found');

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.78,
      ),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        final albumName = album['album'] as String? ?? 'Unknown Album';
        final artist = album['artist'] as String? ?? 'Unknown Artist';
        final songCount = album['song_count'] as int? ?? 0;
        final artworkPath = album['artwork_path'] as String?;

        return GestureDetector(
          onTap: () {
            final albumSongs = library.allSongs.where((s) => s.album == albumName).toList();
            if (albumSongs.isNotEmpty) {
              context.read<MusicProvider>().playSong(albumSongs.first, contextQueue: albumSongs);
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ArtworkWidget(artworkPath: artworkPath, seed: albumName, size: double.infinity, borderRadius: 10, fallbackIcon: Icons.album_rounded),
              ),
              const SizedBox(height: 8),
              Text(albumName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text('$artist • $songCount tracks', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildArtistsTab(LibraryProvider library) {
    final artists = library.artists;
    if (artists.isEmpty) return _buildEmptyState('No artists found');

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 120),
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists[index];
        final artistName = artist['artist'] as String? ?? 'Unknown Artist';
        final songCount = artist['song_count'] as int? ?? 0;

        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: AppTheme.surfaceElevated,
            child: Icon(Icons.person_rounded, color: AppTheme.primary),
          ),
          title: Text(artistName, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('$songCount songs', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          onTap: () {
            final artistSongs = library.allSongs.where((s) => s.artist == artistName).toList();
            if (artistSongs.isNotEmpty) {
              context.read<MusicProvider>().playSong(artistSongs.first, contextQueue: artistSongs);
            }
          },
        );
      },
    );
  }

  Widget _buildFoldersTab(LibraryProvider library) {
    final folders = library.folders;
    if (folders.isEmpty) return _buildEmptyState('No folders found');

    final entries = folders.entries.toList();
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 120),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final path = entries[index].key;
        final songs = entries[index].value;
        final folderName = path.split(RegExp(r'[\\/]')).last;

        return ListTile(
          leading: const Icon(Icons.folder_rounded, color: AppTheme.primary, size: 36),
          title: Text(folderName, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('$path\n${songs.length} songs', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          isThreeLine: true,
          onTap: () {
            if (songs.isNotEmpty) {
              context.read<MusicProvider>().playSong(songs.first, contextQueue: songs);
            }
          },
        );
      },
    );
  }

  Widget _buildDuplicatesTab(LibraryProvider library) {
    final duplicates = library.duplicates;
    if (duplicates.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline_rounded, color: AppTheme.primary, size: 54),
            SizedBox(height: 12),
            Text('No duplicate songs found!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 4),
            Text('Your library is clean and organized.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 120),
      itemCount: duplicates.length,
      itemBuilder: (context, index) {
        final song = duplicates[index];
        return SongTile(song: song);
      },
    );
  }

  void _confirmCleanMissing(BuildContext context, LibraryProvider library) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clean Missing Files'),
        content: Text('Remove ${library.missingFiles.length} missing tracks that no longer exist on your phone?'),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(ctx)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Remove'),
            onPressed: () async {
              await library.cleanupMissingSongs();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cleaned missing tracks!'), backgroundColor: AppTheme.surfaceElevated),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.music_note_rounded, size: 48, color: AppTheme.textMuted),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
        ],
      ),
    );
  }

  void _showStorageSheet(BuildContext context) {
    final storage = context.read<StorageService>();
    storage.refreshAnalytics();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer<StorageService>(
          builder: (context, svc, _) {
            final a = svc.analytics;
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                  const Row(
                    children: [
                      Icon(Icons.pie_chart_rounded, color: AppTheme.primary, size: 24),
                      SizedBox(width: 10),
                      Text(
                        'Storage & Library Size',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (svc.isLoading || a == null)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                    )
                  else ...[
                    _buildStorageRow('Total Tracks in Vault', '${a.totalSongs} songs'),
                    _buildStorageRow('Total Music Library Size', a.totalSizeFormatted),
                    _buildStorageRow('App Offline Vault Folder', a.vaultSizeFormatted),
                    _buildStorageRow('Album Art Cache Size', a.artCacheSizeFormatted),
                    if (a.formatBreakdown.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Audio Formats Detected:',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: a.formatBreakdown.entries.map((e) {
                          return Chip(
                            backgroundColor: AppTheme.cardColor,
                            label: Text(
                              '${e.key.toUpperCase()}: ${e.value}',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textPrimary,
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.cleaning_services_rounded, size: 18),
                        label: const Text('Clear Album Art Cache'),
                        onPressed: () async {
                          await svc.clearAlbumArtCache();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Album art cache cleared!'), backgroundColor: AppTheme.surfaceElevated),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStorageRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
