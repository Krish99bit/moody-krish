import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../data/database/db_helper.dart';

class StorageAnalytics {
  final int totalSongs;
  final int totalSizeBytes;
  final int vaultSizeBytes;
  final int artCacheSizeBytes;
  final Map<String, int> formatBreakdown;
  final bool isLowStorage;

  StorageAnalytics({
    required this.totalSongs,
    required this.totalSizeBytes,
    required this.vaultSizeBytes,
    required this.artCacheSizeBytes,
    required this.formatBreakdown,
    required this.isLowStorage,
  });

  String get totalSizeFormatted => _formatBytes(totalSizeBytes);
  String get vaultSizeFormatted => _formatBytes(vaultSizeBytes);
  String get artCacheSizeFormatted => _formatBytes(artCacheSizeBytes);

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

class StorageService extends ChangeNotifier {
  StorageAnalytics? _analytics;
  bool _isLoading = false;

  StorageAnalytics? get analytics => _analytics;
  bool get isLoading => _isLoading;

  Future<void> refreshAnalytics() async {
    _isLoading = true;
    notifyListeners();

    final songs = await DatabaseHelper.instance.getAllSongs();
    int totalBytes = 0;
    final Map<String, int> formatCount = {};

    for (final song in songs) {
      totalBytes += song.fileSize;
      final ext = p.extension(song.filePath).toLowerCase().replaceAll('.', '');
      formatCount[ext] = (formatCount[ext] ?? 0) + 1;
    }

    final appDocDir = await getApplicationDocumentsDirectory();
    final vaultDir = Directory(p.join(appDocDir.path, 'offline_music'));
    final artDir = Directory(p.join(appDocDir.path, 'album_art_cache'));

    int vaultBytes = await _getDirSize(vaultDir);
    int artBytes = await _getDirSize(artDir);

    _analytics = StorageAnalytics(
      totalSongs: songs.length,
      totalSizeBytes: totalBytes,
      vaultSizeBytes: vaultBytes,
      artCacheSizeBytes: artBytes,
      formatBreakdown: formatCount,
      isLowStorage: false,
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<int> _getDirSize(Directory dir) async {
    int total = 0;
    if (await dir.exists()) {
      try {
        await for (final file in dir.list(recursive: true, followLinks: false)) {
          if (file is File) {
            total += await file.length();
          }
        }
      } catch (_) {}
    }
    return total;
  }

  Future<void> clearAlbumArtCache() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final artDir = Directory(p.join(appDocDir.path, 'album_art_cache'));
    if (await artDir.exists()) {
      try {
        await for (final file in artDir.list()) {
          if (file is File) await file.delete();
        }
      } catch (_) {}
    }
    await refreshAnalytics();
  }
}
