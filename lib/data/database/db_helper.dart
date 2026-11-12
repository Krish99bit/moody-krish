import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/song.dart';
import '../models/playlist.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('moody_krish_offline_music.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Songs table with advanced metadata
    await db.execute('''
      CREATE TABLE songs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        artist TEXT NOT NULL,
        album TEXT NOT NULL,
        duration INTEGER NOT NULL,
        file_path TEXT NOT NULL UNIQUE,
        file_size INTEGER NOT NULL,
        date_added INTEGER NOT NULL,
        artwork_path TEXT,
        lyrics TEXT,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        play_count INTEGER NOT NULL DEFAULT 0,
        last_played_at INTEGER,
        genre TEXT NOT NULL DEFAULT 'Unknown Genre',
        year INTEGER,
        language TEXT NOT NULL DEFAULT 'Universal',
        file_hash TEXT
      )
    ''');

    // 2. Playlists / Folders table
    await db.execute('''
      CREATE TABLE playlists (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        created_at INTEGER NOT NULL,
        artwork_path TEXT
      )
    ''');

    // 3. Playlist songs join table
    await db.execute('''
      CREATE TABLE playlist_songs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        playlist_id INTEGER NOT NULL,
        song_id INTEGER NOT NULL,
        order_index INTEGER NOT NULL,
        FOREIGN KEY (playlist_id) REFERENCES playlists (id) ON DELETE CASCADE,
        FOREIGN KEY (song_id) REFERENCES songs (id) ON DELETE CASCADE,
        UNIQUE (playlist_id, song_id)
      )
    ''');

    // 4. Playback history table
    await db.execute('''
      CREATE TABLE playback_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        song_id INTEGER NOT NULL,
        played_at INTEGER NOT NULL,
        duration_played INTEGER DEFAULT 0,
        FOREIGN KEY (song_id) REFERENCES songs (id) ON DELETE CASCADE
      )
    ''');

    // Indexes for high performance querying
    await db.execute('CREATE INDEX idx_songs_title ON songs (title)');
    await db.execute('CREATE INDEX idx_songs_artist ON songs (artist)');
    await db.execute('CREATE INDEX idx_songs_album ON songs (album)');
    await db.execute('CREATE INDEX idx_songs_genre ON songs (genre)');
    await db.execute('CREATE INDEX idx_songs_is_favorite ON songs (is_favorite)');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute("ALTER TABLE songs ADD COLUMN genre TEXT NOT NULL DEFAULT 'Unknown Genre'");
        await db.execute("ALTER TABLE songs ADD COLUMN year INTEGER");
        await db.execute("ALTER TABLE songs ADD COLUMN language TEXT NOT NULL DEFAULT 'Universal'");
        await db.execute("ALTER TABLE songs ADD COLUMN file_hash TEXT");
      } catch (_) {}
    }
  }

  // --- SONGS CRUD ---

  Future<int> insertSong(Song song) async {
    final db = await instance.database;
    return await db.insert(
      'songs',
      song.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Song>> getAllSongs({String sortBy = 'date_added', bool ascending = false}) async {
    final db = await instance.database;
    final order = ascending ? 'ASC' : 'DESC';
    const allowedSortColumns = {'date_added', 'title', 'artist', 'album', 'duration', 'play_count'};
    final safeSort = allowedSortColumns.contains(sortBy) ? sortBy : 'date_added';
    final result = await db.query(
      'songs',
      orderBy: '$safeSort $order',
    );
    return result.map((json) {
      final path = json['file_path'] as String? ?? '';
      final exists = File(path).existsSync();
      return Song.fromMap(json, existsOnDisk: exists);
    }).toList();
  }

  Future<Song?> getSongById(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'songs',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      final path = maps.first['file_path'] as String? ?? '';
      return Song.fromMap(maps.first, existsOnDisk: File(path).existsSync());
    }
    return null;
  }

  Future<Song?> getSongByPath(String filePath) async {
    final db = await instance.database;
    final maps = await db.query(
      'songs',
      where: 'file_path = ?',
      whereArgs: [filePath],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Song.fromMap(maps.first, existsOnDisk: File(filePath).existsSync());
    }
    return null;
  }

  Future<List<Song>> getFavoriteSongs() async {
    final db = await instance.database;
    final result = await db.query(
      'songs',
      where: 'is_favorite = 1',
      orderBy: 'title ASC',
    );
    return result.map((json) {
      final path = json['file_path'] as String? ?? '';
      return Song.fromMap(json, existsOnDisk: File(path).existsSync());
    }).toList();
  }

  // --- SMART PLAYLISTS ---

  Future<List<Song>> getContinueListening() async {
    final db = await instance.database;
    final result = await db.query(
      'songs',
      where: 'last_played_at IS NOT NULL',
      orderBy: 'last_played_at DESC',
      limit: 10,
    );
    return result.map((json) {
      final path = json['file_path'] as String? ?? '';
      return Song.fromMap(json, existsOnDisk: File(path).existsSync());
    }).toList();
  }

  Future<List<Song>> getRecentlyPlayedSongs({int limit = 30}) async {
    final db = await instance.database;
    final result = await db.query(
      'songs',
      where: 'last_played_at IS NOT NULL',
      orderBy: 'last_played_at DESC',
      limit: limit,
    );
    return result.map((json) => Song.fromMap(json)).toList();
  }

  Future<List<Song>> getRecentlyAddedSongs({int limit = 30}) async {
    final db = await instance.database;
    final result = await db.query(
      'songs',
      orderBy: 'date_added DESC',
      limit: limit,
    );
    return result.map((json) => Song.fromMap(json)).toList();
  }

  Future<List<Song>> getMostPlayedSongs({int limit = 30}) async {
    final db = await instance.database;
    final result = await db.query(
      'songs',
      where: 'play_count > 0',
      orderBy: 'play_count DESC',
      limit: limit,
    );
    return result.map((json) => Song.fromMap(json)).toList();
  }

  // --- ADVANCED SEARCH & MULTI-FILTERS ---

  Future<List<Song>> searchSongsWithFilters({
    String query = '',
    String? genre,
    String? language,
    int? year,
    String? artist,
    String? album,
  }) async {
    final db = await instance.database;
    final List<String> whereClauses = [];
    final List<dynamic> whereArgs = [];

    if (query.trim().isNotEmpty) {
      final cleanQuery = '%$query%';
      whereClauses.add('(title LIKE ? OR artist LIKE ? OR album LIKE ? OR genre LIKE ?)');
      whereArgs.addAll([cleanQuery, cleanQuery, cleanQuery, cleanQuery]);
    }

    if (genre != null && genre.isNotEmpty) {
      whereClauses.add('genre = ?');
      whereArgs.add(genre);
    }

    if (language != null && language.isNotEmpty) {
      whereClauses.add('language = ?');
      whereArgs.add(language);
    }

    if (year != null) {
      whereClauses.add('year = ?');
      whereArgs.add(year);
    }

    if (artist != null && artist.isNotEmpty) {
      whereClauses.add('artist = ?');
      whereArgs.add(artist);
    }

    if (album != null && album.isNotEmpty) {
      whereClauses.add('album = ?');
      whereArgs.add(album);
    }

    final whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final result = await db.query(
      'songs',
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'title ASC',
    );

    return result.map((json) {
      final path = json['file_path'] as String? ?? '';
      return Song.fromMap(json, existsOnDisk: File(path).existsSync());
    }).toList();
  }

  // --- DUPLICATE & MISSING FILES MANAGEMENT ---

  Future<List<Song>> getDuplicateSongs() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT * FROM songs 
      WHERE title IN (
        SELECT title FROM songs GROUP BY title HAVING COUNT(*) > 1
      )
      ORDER BY title ASC, date_added DESC
    ''');
    return result.map((json) => Song.fromMap(json)).toList();
  }

  Future<List<Song>> checkMissingFiles() async {
    final allSongs = await getAllSongs();
    return allSongs.where((s) => !File(s.filePath).existsSync()).toList();
  }

  Future<int> removeMissingFiles() async {
    final missing = await checkMissingFiles();
    int count = 0;
    for (final song in missing) {
      if (song.id != null) {
        await deleteSong(song.id!);
        count++;
      }
    }
    return count;
  }

  Future<int> updateSongMetadata(int id, {
    required String title,
    required String artist,
    required String album,
    String? genre,
    int? year,
    String? language,
  }) async {
    final db = await instance.database;
    final Map<String, dynamic> updateValues = {
      'title': title,
      'artist': artist,
      'album': album,
    };
    if (genre != null) updateValues['genre'] = genre;
    if (year != null) updateValues['year'] = year;
    if (language != null) updateValues['language'] = language;

    return await db.update(
      'songs',
      updateValues,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> toggleFavorite(int songId, bool isFavorite) async {
    final db = await instance.database;
    return await db.update(
      'songs',
      {'is_favorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [songId],
    );
  }

  Future<int> updateLyrics(int songId, String lyrics) async {
    final db = await instance.database;
    return await db.update(
      'songs',
      {'lyrics': lyrics},
      where: 'id = ?',
      whereArgs: [songId],
    );
  }

  Future<void> recordPlay(int songId) async {
    final db = await instance.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.rawUpdate('''
      UPDATE songs 
      SET play_count = play_count + 1, last_played_at = ? 
      WHERE id = ?
    ''', [now, songId]);

    await db.insert('playback_history', {
      'song_id': songId,
      'played_at': now,
    });
  }

  Future<int> deleteSong(int songId, {bool deleteFileFromDisk = false}) async {
    final db = await instance.database;
    final song = await getSongById(songId);
    if (song != null && deleteFileFromDisk) {
      final file = File(song.filePath);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
    }
    return await db.delete(
      'songs',
      where: 'id = ?',
      whereArgs: [songId],
    );
  }

  // --- PLAYLISTS & CUSTOM FOLDERS CRUD ---

  Future<int> createPlaylist(String name, {String? description, String? artworkPath}) async {
    final db = await instance.database;
    return await db.insert('playlists', {
      'name': name,
      'description': description,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'artwork_path': artworkPath,
    });
  }

  Future<List<Playlist>> getAllPlaylists() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT p.*, COUNT(ps.song_id) as song_count
      FROM playlists p
      LEFT JOIN playlist_songs ps ON p.id = ps.playlist_id
      GROUP BY p.id
      ORDER BY p.created_at DESC
    ''');

    return result.map((row) {
      final songCount = (row['song_count'] as int?) ?? 0;
      return Playlist.fromMap(row, songCount: songCount);
    }).toList();
  }

  Future<int> deletePlaylist(int playlistId) async {
    final db = await instance.database;
    await db.delete('playlist_songs', where: 'playlist_id = ?', whereArgs: [playlistId]);
    return await db.delete('playlists', where: 'id = ?', whereArgs: [playlistId]);
  }

  Future<int> addSongToPlaylist(int playlistId, int songId) async {
    final db = await instance.database;
    final maxOrderResult = await db.rawQuery(
      'SELECT MAX(order_index) as max_order FROM playlist_songs WHERE playlist_id = ?',
      [playlistId],
    );
    final nextOrder = ((maxOrderResult.first['max_order'] as int?) ?? 0) + 1;

    return await db.insert(
      'playlist_songs',
      {
        'playlist_id': playlistId,
        'song_id': songId,
        'order_index': nextOrder,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<int> removeSongFromPlaylist(int playlistId, int songId) async {
    final db = await instance.database;
    return await db.delete(
      'playlist_songs',
      where: 'playlist_id = ? AND song_id = ?',
      whereArgs: [playlistId, songId],
    );
  }

  Future<List<Song>> getSongsForPlaylist(int playlistId) async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT s.*
      FROM songs s
      INNER JOIN playlist_songs ps ON s.id = ps.song_id
      WHERE ps.playlist_id = ?
      ORDER BY ps.order_index ASC
    ''', [playlistId]);

    return result.map((json) {
      final path = json['file_path'] as String? ?? '';
      return Song.fromMap(json, existsOnDisk: File(path).existsSync());
    }).toList();
  }

  Future<void> reorderPlaylistSongs(int playlistId, List<int> songIds) async {
    final db = await instance.database;
    final batch = db.batch();
    for (int i = 0; i < songIds.length; i++) {
      batch.update(
        'playlist_songs',
        {'order_index': i + 1},
        where: 'playlist_id = ? AND song_id = ?',
        whereArgs: [playlistId, songIds[i]],
      );
    }
    await batch.commit(noResult: true);
  }

  // --- BACKUP & RESTORE ---

  Future<String> exportBackupData() async {
    final songs = await getAllSongs();
    final playlists = await getAllPlaylists();

    final List<Map<String, dynamic>> playlistData = [];
    for (final p in playlists) {
      final pSongs = await getSongsForPlaylist(p.id!);
      playlistData.add({
        'name': p.name,
        'description': p.description,
        'songs': pSongs.map((s) => s.filePath).toList(),
      });
    }

    final backup = {
      'app': 'Moody Krish',
      'version': '2.0',
      'exported_at': DateTime.now().toIso8601String(),
      'playlists': playlistData,
      'favorites': songs.where((s) => s.isFavorite).map((s) => s.filePath).toList(),
      'play_counts': songs.map((s) => {'path': s.filePath, 'count': s.playCount}).toList(),
    };

    return jsonEncode(backup);
  }

  Future<bool> restoreBackupData(String jsonString) async {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonString);
      final playlists = (data['playlists'] as List<dynamic>?) ?? [];
      final favorites = (data['favorites'] as List<dynamic>?) ?? [];

      // Restore favorites
      final db = await instance.database;
      for (final favPath in favorites) {
        await db.update('songs', {'is_favorite': 1}, where: 'file_path = ?', whereArgs: [favPath]);
      }

      // Restore playlists
      for (final pMap in playlists) {
        final name = pMap['name'] as String;
        final desc = pMap['description'] as String?;
        final songPaths = (pMap['songs'] as List<dynamic>?) ?? [];

        final pId = await createPlaylist(name, description: desc);
        for (final path in songPaths) {
          final song = await getSongByPath(path);
          if (song != null && song.id != null) {
            await addSongToPlaylist(pId, song.id!);
          }
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  // --- ALBUMS, ARTISTS, GENRES GROUPING ---

  Future<List<Map<String, dynamic>>> getAlbums() async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT album, artist, COUNT(*) as song_count, artwork_path
      FROM songs
      GROUP BY album
      ORDER BY album ASC
    ''');
  }

  Future<List<Map<String, dynamic>>> getArtists() async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT artist, COUNT(*) as song_count, COUNT(DISTINCT album) as album_count
      FROM songs
      GROUP BY artist
      ORDER BY artist ASC
    ''');
  }

  Future<List<Map<String, dynamic>>> getGenres() async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT genre, COUNT(*) as song_count
      FROM songs
      GROUP BY genre
      ORDER BY song_count DESC
    ''');
  }
}
