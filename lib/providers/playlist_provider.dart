import 'package:flutter/foundation.dart';
import '../data/database/db_helper.dart';
import '../data/models/playlist.dart';
import '../data/models/song.dart';

class PlaylistProvider extends ChangeNotifier {
  List<Playlist> _playlists = [];
  bool _isLoading = false;

  List<Playlist> get playlists => List.unmodifiable(_playlists);
  bool get isLoading => _isLoading;

  PlaylistProvider() {
    loadPlaylists();
  }

  Future<void> loadPlaylists() async {
    _isLoading = true;
    notifyListeners();
    _playlists = await DatabaseHelper.instance.getAllPlaylists();
    _isLoading = false;
    notifyListeners();
  }

  Future<int> createPlaylist(String name, {String? description}) async {
    final id = await DatabaseHelper.instance.createPlaylist(name, description: description);
    await loadPlaylists();
    return id;
  }

  Future<void> deletePlaylist(int playlistId) async {
    await DatabaseHelper.instance.deletePlaylist(playlistId);
    await loadPlaylists();
  }

  Future<List<Song>> getSongsForPlaylist(int playlistId) async {
    return await DatabaseHelper.instance.getSongsForPlaylist(playlistId);
  }

  Future<void> addSongToPlaylist(int playlistId, Song song) async {
    if (song.id == null) return;
    await DatabaseHelper.instance.addSongToPlaylist(playlistId, song.id!);
    await loadPlaylists();
  }

  Future<void> removeSongFromPlaylist(int playlistId, Song song) async {
    if (song.id == null) return;
    await DatabaseHelper.instance.removeSongFromPlaylist(playlistId, song.id!);
    await loadPlaylists();
  }

  Future<void> reorderPlaylistSongs(int playlistId, List<Song> songs) async {
    final ids = songs.map((s) => s.id).whereType<int>().toList();
    await DatabaseHelper.instance.reorderPlaylistSongs(playlistId, ids);
  }
}
