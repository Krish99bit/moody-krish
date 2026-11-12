import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../data/database/db_helper.dart';
import '../data/models/song.dart';

class LibraryProvider extends ChangeNotifier {
  List<Song> _allSongs = [];
  List<Song> _favoriteSongs = [];
  List<Song> _continueListening = [];
  List<Song> _recentlyPlayed = [];
  List<Song> _recentlyAdded = [];
  List<Song> _mostPlayed = [];
  List<Song> _duplicates = [];
  List<Song> _missingFiles = [];
  List<Map<String, dynamic>> _albums = [];
  List<Map<String, dynamic>> _artists = [];
  List<Map<String, dynamic>> _genres = [];
  Map<String, List<Song>> _folders = {};

  List<Song> _searchResults = [];
  String _searchQuery = '';
  String? _selectedGenre;
  String? _selectedLanguage;
  int? _selectedYear;
  bool _isLoading = false;

  String _sortBy = 'title'; // 'title', 'artist', 'date_added', 'duration'
  bool _sortAscending = true;

  List<Song> get allSongs => List.unmodifiable(_allSongs);
  List<Song> get favoriteSongs => List.unmodifiable(_favoriteSongs);
  List<Song> get continueListening => List.unmodifiable(_continueListening);
  List<Song> get recentlyPlayed => List.unmodifiable(_recentlyPlayed);
  List<Song> get recentlyAdded => List.unmodifiable(_recentlyAdded);
  List<Song> get mostPlayed => List.unmodifiable(_mostPlayed);
  List<Song> get duplicates => List.unmodifiable(_duplicates);
  List<Song> get missingFiles => List.unmodifiable(_missingFiles);
  List<Map<String, dynamic>> get albums => List.unmodifiable(_albums);
  List<Map<String, dynamic>> get artists => List.unmodifiable(_artists);
  List<Map<String, dynamic>> get genres => List.unmodifiable(_genres);
  Map<String, List<Song>> get folders => Map.unmodifiable(_folders);

  List<Song> get searchResults => List.unmodifiable(_searchResults);
  String get searchQuery => _searchQuery;
  String? get selectedGenre => _selectedGenre;
  String? get selectedLanguage => _selectedLanguage;
  int? get selectedYear => _selectedYear;
  bool get isLoading => _isLoading;
  String get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;

  LibraryProvider() {
    refreshLibrary();
  }

  Future<void> refreshLibrary() async {
    _isLoading = true;
    notifyListeners();

    _allSongs = await DatabaseHelper.instance.getAllSongs(
      sortBy: _sortBy,
      ascending: _sortAscending,
    );
    _favoriteSongs = await DatabaseHelper.instance.getFavoriteSongs();
    _continueListening = await DatabaseHelper.instance.getContinueListening();
    _recentlyPlayed = await DatabaseHelper.instance.getRecentlyPlayedSongs(limit: 20);
    _recentlyAdded = await DatabaseHelper.instance.getRecentlyAddedSongs(limit: 20);
    _mostPlayed = await DatabaseHelper.instance.getMostPlayedSongs(limit: 20);
    _duplicates = await DatabaseHelper.instance.getDuplicateSongs();
    _missingFiles = await DatabaseHelper.instance.checkMissingFiles();
    _albums = await DatabaseHelper.instance.getAlbums();
    _artists = await DatabaseHelper.instance.getArtists();
    _genres = await DatabaseHelper.instance.getGenres();

    // Group songs into local storage folders
    final Map<String, List<Song>> folderMap = {};
    for (final song in _allSongs) {
      final folder = p.dirname(song.filePath);
      folderMap.putIfAbsent(folder, () => []).add(song);
    }
    _folders = folderMap;

    _isLoading = false;
    notifyListeners();
  }

  void setSorting(String criteria, bool ascending) {
    _sortBy = criteria;
    _sortAscending = ascending;
    refreshLibrary();
  }

  Future<void> searchWithFilters({
    String query = '',
    String? genre,
    String? language,
    int? year,
  }) async {
    _searchQuery = query;
    _selectedGenre = genre;
    _selectedLanguage = language;
    _selectedYear = year;

    if (query.trim().isEmpty && genre == null && language == null && year == null) {
      _searchResults = [];
    } else {
      _searchResults = await DatabaseHelper.instance.searchSongsWithFilters(
        query: query,
        genre: genre,
        language: language,
        year: year,
      );
    }
    notifyListeners();
  }

  Future<void> updateMetadata(Song song, {
    required String title,
    required String artist,
    required String album,
    String? genre,
    int? year,
  }) async {
    if (song.id == null) return;
    await DatabaseHelper.instance.updateSongMetadata(
      song.id!,
      title: title,
      artist: artist,
      album: album,
      genre: genre,
      year: year,
    );
    await refreshLibrary();
  }

  Future<int> cleanupMissingSongs() async {
    final count = await DatabaseHelper.instance.removeMissingFiles();
    await refreshLibrary();
    return count;
  }

  Future<void> deleteSong(Song song) async {
    if (song.id == null) return;
    await DatabaseHelper.instance.deleteSong(song.id!);
    await refreshLibrary();
  }
}
