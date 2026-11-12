import 'package:audio_service/audio_service.dart';

class Song {
  final int? id;
  final String title;
  final String artist;
  final String album;
  final int duration; // in milliseconds
  final String filePath;
  final int fileSize;
  final DateTime dateAdded;
  final String? artworkPath;
  final String? lyrics;
  final bool isFavorite;
  final int playCount;
  final DateTime? lastPlayedAt;
  
  // Advanced metadata & library fields
  final String genre;
  final int? year;
  final String language;
  final String? fileHash;
  final bool existsOnDisk;

  Song({
    this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.filePath,
    required this.fileSize,
    required this.dateAdded,
    this.artworkPath,
    this.lyrics,
    this.isFavorite = false,
    this.playCount = 0,
    this.lastPlayedAt,
    this.genre = 'Unknown Genre',
    this.year,
    this.language = 'Universal',
    this.fileHash,
    this.existsOnDisk = true,
  });

  Song copyWith({
    int? id,
    String? title,
    String? artist,
    String? album,
    int? duration,
    String? filePath,
    int? fileSize,
    DateTime? dateAdded,
    String? artworkPath,
    String? lyrics,
    bool? isFavorite,
    int? playCount,
    DateTime? lastPlayedAt,
    String? genre,
    int? year,
    String? language,
    String? fileHash,
    bool? existsOnDisk,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      dateAdded: dateAdded ?? this.dateAdded,
      artworkPath: artworkPath ?? this.artworkPath,
      lyrics: lyrics ?? this.lyrics,
      isFavorite: isFavorite ?? this.isFavorite,
      playCount: playCount ?? this.playCount,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      genre: genre ?? this.genre,
      year: year ?? this.year,
      language: language ?? this.language,
      fileHash: fileHash ?? this.fileHash,
      existsOnDisk: existsOnDisk ?? this.existsOnDisk,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'duration': duration,
      'file_path': filePath,
      'file_size': fileSize,
      'date_added': dateAdded.millisecondsSinceEpoch,
      'artwork_path': artworkPath,
      'lyrics': lyrics,
      'is_favorite': isFavorite ? 1 : 0,
      'play_count': playCount,
      'last_played_at': lastPlayedAt?.millisecondsSinceEpoch,
      'genre': genre,
      'year': year,
      'language': language,
      'file_hash': fileHash,
    };
  }

  factory Song.fromMap(Map<String, dynamic> map, {bool existsOnDisk = true}) {
    return Song(
      id: map['id'] as int?,
      title: map['title'] as String? ?? 'Unknown Title',
      artist: map['artist'] as String? ?? 'Unknown Artist',
      album: map['album'] as String? ?? 'Unknown Album',
      duration: map['duration'] as int? ?? 0,
      filePath: map['file_path'] as String? ?? '',
      fileSize: map['file_size'] as int? ?? 0,
      dateAdded: map['date_added'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['date_added'] as int)
          : DateTime.now(),
      artworkPath: map['artwork_path'] as String?,
      lyrics: map['lyrics'] as String?,
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      playCount: map['play_count'] as int? ?? 0,
      lastPlayedAt: map['last_played_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_played_at'] as int)
          : null,
      genre: map['genre'] as String? ?? 'Unknown Genre',
      year: map['year'] as int?,
      language: map['language'] as String? ?? 'Universal',
      fileHash: map['file_hash'] as String?,
      existsOnDisk: existsOnDisk,
    );
  }

  MediaItem toMediaItem() {
    return MediaItem(
      id: filePath,
      title: title,
      artist: artist,
      album: album,
      genre: genre,
      duration: Duration(milliseconds: duration),
      artUri: artworkPath != null ? Uri.file(artworkPath!) : null,
      extras: {
        'id': id,
        'filePath': filePath,
        'isFavorite': isFavorite,
        'year': year,
        'language': language,
      },
    );
  }

  String get durationFormatted {
    final totalSeconds = duration ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedFileSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Model for Synchronized Karaoke Lyrics
class LrcLine {
  final Duration timestamp;
  final String text;

  const LrcLine({required this.timestamp, required this.text});

  static List<LrcLine> parseLrc(String rawLyrics) {
    final List<LrcLine> lines = [];
    final regExp = RegExp(r'\[(\d{2}):(\d{2})\.?(\d{2,3})?\](.*)');
    for (final line in rawLyrics.split('\n')) {
      final match = regExp.firstMatch(line.trim());
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final millis = match.group(3) != null
            ? int.parse(match.group(3)!.padRight(3, '0'))
            : 0;
        final text = match.group(4)?.trim() ?? '';
        lines.add(LrcLine(
          timestamp: Duration(minutes: minutes, seconds: seconds, milliseconds: millis),
          text: text,
        ));
      }
    }
    lines.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return lines;
  }
}
