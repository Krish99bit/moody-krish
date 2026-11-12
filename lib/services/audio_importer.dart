import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../data/database/db_helper.dart';
import '../data/models/song.dart';

class AudioImporter {
  static const List<String> supportedExtensions = [
    'mp3',
    'm4a',
    'wav',
    'flac',
    'aac',
    'ogg',
    'opus',
  ];

  /// Request runtime permissions for audio files depending on Android SDK
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final audioStatus = await Permission.audio.request();
      if (audioStatus.isGranted) return true;

      final storageStatus = await Permission.storage.request();
      if (storageStatus.isGranted) return true;

      // Check media library if Android 13+
      final mediaStatus = await Permission.mediaLibrary.request();
      if (mediaStatus.isGranted) return true;

      return audioStatus.isGranted || storageStatus.isGranted || mediaStatus.isGranted;
    }
    return true;
  }

  /// Let user select single or multiple audio files to import into the app
  static Future<List<Song>> pickAndImportFiles({
    bool copyToAppVault = true,
    Function(int current, int total)? onProgress,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: supportedExtensions,
      allowMultiple: true,
    );

    if (result == null || result.files.isEmpty) {
      return [];
    }

    final validPaths = result.files
        .map((f) => f.path)
        .whereType<String>()
        .where((path) => File(path).existsSync())
        .toList();

    return await _processAudioFiles(validPaths, copyToAppVault, onProgress);
  }

  /// Let user pick an entire folder and recursively scan all audio files
  static Future<List<Song>> pickAndImportFolder({
    bool copyToAppVault = false,
    Function(int current, int total)? onProgress,
  }) async {
    final selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory == null) return [];

    final dir = Directory(selectedDirectory);
    if (!await dir.exists()) return [];

    final List<String> audioPaths = [];
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        final ext = p.extension(entity.path).toLowerCase().replaceAll('.', '');
        if (supportedExtensions.contains(ext)) {
          audioPaths.add(entity.path);
        }
      }
    }

    return await _processAudioFiles(audioPaths, copyToAppVault, onProgress);
  }

  /// Processes files: copies to vault (if desired), parses tags/covers, and saves to SQLite
  static Future<List<Song>> _processAudioFiles(
    List<String> filePaths,
    bool copyToAppVault,
    Function(int current, int total)? onProgress,
  ) async {
    final List<Song> importedSongs = [];
    final appDocDir = await getApplicationDocumentsDirectory();
    final vaultDir = Directory(p.join(appDocDir.path, 'offline_music'));
    final artDir = Directory(p.join(appDocDir.path, 'album_art_cache'));

    if (!await vaultDir.exists()) await vaultDir.create(recursive: true);
    if (!await artDir.exists()) await artDir.create(recursive: true);

    for (int i = 0; i < filePaths.length; i++) {
      final originalPath = filePaths[i];
      if (onProgress != null) {
        onProgress(i + 1, filePaths.length);
      }

      try {
        final originalFile = File(originalPath);
        if (!await originalFile.exists()) continue;

        String targetPath = originalPath;
        if (copyToAppVault) {
          final fileName = p.basename(originalPath);
          final destinationPath = p.join(vaultDir.path, fileName);
          // Only copy if not already in vault
          if (originalPath != destinationPath) {
            await originalFile.copy(destinationPath);
            targetPath = destinationPath;
          }
        }

        // Check if song already exists in database
        final existing = await DatabaseHelper.instance.getSongByPath(targetPath);
        if (existing != null) {
          importedSongs.add(existing);
          continue;
        }

        // Extract metadata & artwork
        final metadata = await _extractMetadata(targetPath, artDir.path);
        final fileStat = await File(targetPath).stat();

        final song = Song(
          title: metadata.title,
          artist: metadata.artist,
          album: metadata.album,
          duration: metadata.durationMs,
          filePath: targetPath,
          fileSize: fileStat.size,
          dateAdded: DateTime.now(),
          artworkPath: metadata.artworkPath,
          lyrics: metadata.lyrics,
        );

        final id = await DatabaseHelper.instance.insertSong(song);
        importedSongs.add(song.copyWith(id: id));
      } catch (e) {
        // Fallback gracefully on corrupt or unreadable files
        continue;
      }
    }

    return importedSongs;
  }

  /// Pure Dart metadata and ID3 parser
  static Future<_AudioMeta> _extractMetadata(String filePath, String artCacheDirPath) async {
    final file = File(filePath);
    final fileName = p.basenameWithoutExtension(filePath);

    String title = fileName;
    String artist = 'Unknown Artist';
    String album = 'Local Audio';
    String? artworkPath;
    String? lyrics;
    int durationMs = 180000; // 3 min default fallback if length cannot be read directly

    // Guess artist and title from filename pattern: "Artist - Title"
    if (fileName.contains(' - ')) {
      final parts = fileName.split(' - ');
      if (parts.length >= 2) {
        artist = parts[0].trim();
        title = parts.sublist(1).join(' - ').trim();
      }
    }

    try {
      final List<int> bytes = [];
      await for (final chunk in file.openRead(0, 1024 * 128)) {
        bytes.addAll(chunk);
        if (bytes.length >= 1024 * 128) break;
      }

      if (bytes.length > 10 && bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33) {
        // ID3v2 detected
        final majorVersion = bytes[3]; // 3 for ID3v2.3, 4 for ID3v2.4
        int offset = 10;
        while (offset + 10 < bytes.length) {
          if (bytes[offset] == 0) break;
          final frameId = String.fromCharCodes(bytes.sublist(offset, offset + 4));
          
          final int frameSize;
          if (majorVersion == 4) {
            // ID3v2.4 uses syncsafe 7-bit encoding
            frameSize = (bytes[offset + 4] << 21) |
                (bytes[offset + 5] << 14) |
                (bytes[offset + 6] << 7) |
                bytes[offset + 7];
          } else {
            // ID3v2.3 uses standard big-endian 32-bit integer
            frameSize = (bytes[offset + 4] << 24) |
                (bytes[offset + 5] << 16) |
                (bytes[offset + 6] << 8) |
                bytes[offset + 7];
          }

          offset += 10; // Skip frame header
          if (frameSize <= 0 || offset + frameSize > bytes.length) break;

          final frameData = bytes.sublist(offset, offset + frameSize);

          if (frameId == 'TIT2') {
            title = _decodeString(frameData);
          } else if (frameId == 'TPE1') {
            artist = _decodeString(frameData);
          } else if (frameId == 'TALB') {
            album = _decodeString(frameData);
          } else if (frameId == 'USLT') {
            lyrics = _decodeString(frameData);
          } else if (frameId == 'APIC') {
            // Embedded artwork image
            artworkPath = await _saveCoverArt(frameData, artCacheDirPath, fileName);
          }

          offset += frameSize;
        }
      }
    } catch (_) {
      // Keep filename fallbacks
    }

    // Clean up empty strings
    if (title.trim().isEmpty) title = fileName;
    if (artist.trim().isEmpty) artist = 'Unknown Artist';
    if (album.trim().isEmpty) album = 'Local Audio';

    return _AudioMeta(
      title: title,
      artist: artist,
      album: album,
      durationMs: durationMs,
      artworkPath: artworkPath,
      lyrics: lyrics,
    );
  }

  static String _decodeString(List<int> bytes) {
    if (bytes.isEmpty) return '';
    final encoding = bytes[0];
    final textBytes = bytes.sublist(1);
    try {
      if (encoding == 0) {
        return latin1.decode(textBytes).replaceAll('\x00', '').trim();
      } else if (encoding == 1 || encoding == 2) {
        final decoded = _decodeUtf16(textBytes);
        if (decoded.isNotEmpty) return decoded.replaceAll('\x00', '').trim();
        return utf8.decode(textBytes, allowMalformed: true).replaceAll('\x00', '').trim();
      } else {
        return utf8.decode(textBytes, allowMalformed: true).replaceAll('\x00', '').trim();
      }
    } catch (_) {
      return '';
    }
  }

  static String _decodeUtf16(List<int> bytes) {
    if (bytes.length < 2) return '';
    bool isLittleEndian = true;
    int start = 0;
    if (bytes[0] == 0xFF && bytes[1] == 0xFE) {
      isLittleEndian = true;
      start = 2;
    } else if (bytes[0] == 0xFE && bytes[1] == 0xFF) {
      isLittleEndian = false;
      start = 2;
    }
    final codeUnits = <int>[];
    for (int i = start; i + 1 < bytes.length; i += 2) {
      final codeUnit = isLittleEndian
          ? bytes[i] | (bytes[i + 1] << 8)
          : (bytes[i] << 8) | bytes[i + 1];
      if (codeUnit == 0) continue;
      codeUnits.add(codeUnit);
    }
    return String.fromCharCodes(codeUnits);
  }

  static Future<String?> _saveCoverArt(List<int> apicBytes, String artCacheDirPath, String fileName) async {
    try {
      if (apicBytes.length < 10) return null;
      // Search for JPEG (0xFF 0xD8) or PNG (0x89 0x50 0x4E 0x47) header
      int imageStartIndex = -1;
      bool isPng = false;

      for (int i = 0; i < apicBytes.length - 4; i++) {
        if (apicBytes[i] == 0xFF && apicBytes[i + 1] == 0xD8) {
          imageStartIndex = i;
          break;
        }
        if (apicBytes[i] == 0x89 &&
            apicBytes[i + 1] == 0x50 &&
            apicBytes[i + 2] == 0x4E &&
            apicBytes[i + 3] == 0x47) {
          imageStartIndex = i;
          isPng = true;
          break;
        }
      }

      if (imageStartIndex != -1) {
        final imageBytes = apicBytes.sublist(imageStartIndex);
        final safeName = fileName.replaceAll(RegExp(r'[^\w\s\.-]'), '_');
        final ext = isPng ? 'png' : 'jpg';
        final artFile = File(p.join(artCacheDirPath, 'art_${safeName}_${DateTime.now().millisecondsSinceEpoch}.$ext'));
        await artFile.writeAsBytes(imageBytes);
        return artFile.path;
      }
    } catch (_) {}
    return null;
  }
}

class _AudioMeta {
  final String title;
  final String artist;
  final String album;
  final int durationMs;
  final String? artworkPath;
  final String? lyrics;

  _AudioMeta({
    required this.title,
    required this.artist,
    required this.album,
    required this.durationMs,
    this.artworkPath,
    this.lyrics,
  });
}
