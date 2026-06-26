import 'package:flutter/foundation.dart';
import '../models/playlist_model.dart';
import '../services/playlist_service.dart';

class PlaylistController extends ChangeNotifier {
  final PlaylistService _playlistService = PlaylistService();
  List<PlaylistModel> _playlists = [];
  bool _isLoading = false;
  bool _isServiceInitialized = false;

  List<PlaylistModel> get playlists => _playlists;
  bool get isLoading => _isLoading;

  Future<void> _ensureInitialized() async {
    if (!_isServiceInitialized) {
      await _playlistService.init();
      _isServiceInitialized = true;
    }
  }

  Future<void> loadPlaylists() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _ensureInitialized();
      _playlists = await _playlistService.getPlaylists();
      
      if (_playlists.isEmpty) {
        final defaultFav = PlaylistModel(
          id: 'p1',
          name: 'My Favorites',
          description: 'Songs I love',
          songIds: [],
          createdAt: DateTime.now(),
        );
        _playlists = [defaultFav];
        await _playlistService.savePlaylist(defaultFav);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading playlists: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void createPlaylist(String name, String? description) async {
    final newPlaylist = PlaylistModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      songIds: [],
      createdAt: DateTime.now(),
    );
    _playlists.add(newPlaylist);
    notifyListeners();
    await _ensureInitialized();
    await _playlistService.savePlaylist(newPlaylist);
  }

  void deletePlaylist(String id) async {
    _playlists.removeWhere((playlist) => playlist.id == id);
    notifyListeners();
    await _ensureInitialized();
    await _playlistService.deletePlaylist(id);
  }

  void clearPlaylist(String id) async {
    final index = _playlists.indexWhere((playlist) => playlist.id == id);
    if (index != -1) {
      final cleared = _playlists[index].copyWith(songIds: const []);
      _playlists[index] = cleared;
      notifyListeners();
      await _ensureInitialized();
      await _playlistService.savePlaylist(cleared);
    }
  }

  void addSongToPlaylist(String playlistId, String songId) async {
    final index = _playlists.indexWhere(
      (playlist) => playlist.id == playlistId,
    );
    if (index != -1) {
      final playlist = _playlists[index];
      if (!playlist.songIds.contains(songId)) {
        final updatedSongs = List<String>.from(playlist.songIds)..add(songId);
        final updatedPlaylist = playlist.copyWith(songIds: updatedSongs);
        _playlists[index] = updatedPlaylist;
        notifyListeners();
        await _ensureInitialized();
        await _playlistService.savePlaylist(updatedPlaylist);
      }
    }
  }

  void removeSongFromPlaylist(String playlistId, String songId) async {
    final index = _playlists.indexWhere(
      (playlist) => playlist.id == playlistId,
    );
    if (index != -1) {
      final playlist = _playlists[index];
      if (playlist.songIds.contains(songId)) {
        final updatedSongs = List<String>.from(playlist.songIds)
          ..remove(songId);
        final updatedPlaylist = playlist.copyWith(songIds: updatedSongs);
        _playlists[index] = updatedPlaylist;
        notifyListeners();
        await _ensureInitialized();
        await _playlistService.savePlaylist(updatedPlaylist);
      }
    }
  }
}
