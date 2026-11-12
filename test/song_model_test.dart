import 'package:flutter_test/flutter_test.dart';
import 'package:moody_krish/data/models/song.dart';

void main() {
  group('Song Model Tests', () {
    test('Song model serialization and deserialization', () {
      final now = DateTime.now();
      final song = Song(
        id: 1,
        title: 'Born to Shine',
        artist: 'Diljit Dosanjh',
        album: 'G.O.A.T.',
        duration: 212000,
        filePath: '/storage/emulated/0/Music/born_to_shine.mp3',
        fileSize: 5242880,
        dateAdded: now,
        genre: 'Punjabi',
        year: 2020,
        language: 'Punjabi',
        isFavorite: true,
        playCount: 15,
      );

      final map = song.toMap();
      expect(map['title'], 'Born to Shine');
      expect(map['artist'], 'Diljit Dosanjh');
      expect(map['genre'], 'Punjabi');
      expect(map['is_favorite'], 1);
      expect(map['play_count'], 15);

      final restored = Song.fromMap(map);
      expect(restored.title, song.title);
      expect(restored.artist, song.artist);
      expect(restored.genre, song.genre);
      expect(restored.isFavorite, true);
      expect(restored.playCount, 15);
    });

    test('durationFormatted formats milliseconds to mm:ss correctly', () {
      final song1 = Song(
        title: 'Test',
        artist: 'Test',
        album: 'Test',
        duration: 212000, // 3:32
        filePath: '/test.mp3',
        fileSize: 100,
        dateAdded: DateTime.now(),
      );
      expect(song1.durationFormatted, '03:32');

      final song2 = song1.copyWith(duration: 65000); // 1:05
      expect(song2.durationFormatted, '01:05');

      final song3 = song1.copyWith(duration: 9000); // 0:09
      expect(song3.durationFormatted, '00:09');
    });

    test('formattedFileSize formats B, KB, MB cleanly', () {
      final song1 = Song(
        title: 'T', artist: 'A', album: 'Al', duration: 1000, filePath: '/p', fileSize: 500, dateAdded: DateTime.now(),
      );
      expect(song1.formattedFileSize, '500 B');

      final song2 = song1.copyWith(fileSize: 153600); // 150 KB
      expect(song2.formattedFileSize, '150.0 KB');

      final song3 = song1.copyWith(fileSize: 5242880); // 5.0 MB
      expect(song3.formattedFileSize, '5.0 MB');
    });
  });

  group('Synchronized Karaoke LRC Parser Tests', () {
    test('Parses standard [mm:ss.xx] timestamped lines in chronological order', () {
      const rawLyrics = '''
[00:05.20] First line of song
[00:12.80] Second line of song
[00:01.50] Intro line out of order
[00:25.00] Chorus begins
''';

      final parsed = LrcLine.parseLrc(rawLyrics);
      expect(parsed.length, 4);

      // Verify sorted order
      expect(parsed[0].text, 'Intro line out of order');
      expect(parsed[0].timestamp.inMilliseconds, 1500);

      expect(parsed[1].text, 'First line of song');
      expect(parsed[1].timestamp.inMilliseconds, 5200);

      expect(parsed[2].text, 'Second line of song');
      expect(parsed[2].timestamp.inMilliseconds, 12800);

      expect(parsed[3].text, 'Chorus begins');
      expect(parsed[3].timestamp.inMilliseconds, 25000);
    });

    test('Handles empty and invalid lyrics gracefully without throwing', () {
      expect(LrcLine.parseLrc(''), isEmpty);
      expect(LrcLine.parseLrc('Plain lyrics without any timestamp headers'), isEmpty);
      expect(LrcLine.parseLrc('[[invalid]] formatting'), isEmpty);
    });
  });
}
