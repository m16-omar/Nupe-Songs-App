import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../models/playlist_model.dart';

class PlaylistService {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  SharedPreferences? _webPrefs;

  Future<void> init() async {
    if (kIsWeb) {
      try {
        _webPrefs = await SharedPreferences.getInstance();
        if (kDebugMode) {
          print('PlaylistService (Web) initialized');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error initializing Web SharedPreferences for playlists: $e');
        }
      }
    } else {
      await _dbHelper.initDatabase();
      if (kDebugMode) {
        print('PlaylistService initialized');
      }
    }
  }

  Future<List<PlaylistModel>> getPlaylists() async {
    if (kIsWeb) {
      try {
        final listStr = _webPrefs?.getString('web_playlists');
        if (listStr == null) return [];
        final List<dynamic> listJson = jsonDecode(listStr);
        return listJson.map((x) => PlaylistModel.fromJson(x as Map<String, dynamic>)).toList();
      } catch (e) {
        if (kDebugMode) {
          print('Error getting web playlists: $e');
        }
        return [];
      }
    }

    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query('playlists');
      return List.generate(maps.length, (i) {
        return PlaylistModel(
          id: maps[i]['id'] as String,
          name: maps[i]['name'] as String,
          description: maps[i]['description'] as String?,
          songIds: List<String>.from(jsonDecode(maps[i]['songIds'] as String) as List),
          artworkPath: maps[i]['artworkPath'] as String?,
          createdAt: DateTime.parse(maps[i]['createdAt'] as String),
        );
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error getting playlists: $e');
      }
      return [];
    }
  }

  Future<void> savePlaylist(PlaylistModel playlist) async {
    if (kIsWeb) {
      try {
        final currentPlaylists = await getPlaylists();
        final index = currentPlaylists.indexWhere((p) => p.id == playlist.id);
        if (index != -1) {
          currentPlaylists[index] = playlist;
        } else {
          currentPlaylists.add(playlist);
        }
        final listJson = currentPlaylists.map((p) => p.toJson()).toList();
        await _webPrefs?.setString('web_playlists', jsonEncode(listJson));
        if (kDebugMode) {
          print('Saving web playlist: ${playlist.name}');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error saving web playlist: $e');
        }
      }
      return;
    }

    try {
      final db = await _dbHelper.database;
      final songIdsJson = jsonEncode(playlist.songIds);
      
      await db.insert(
        'playlists',
        {
          'id': playlist.id,
          'name': playlist.name,
          'description': playlist.description,
          'songIds': songIdsJson,
          'artworkPath': playlist.artworkPath,
          'createdAt': playlist.createdAt.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      if (kDebugMode) {
        print('Saving playlist: ${playlist.name}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving playlist: $e');
      }
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    if (kIsWeb) {
      try {
        final currentPlaylists = await getPlaylists();
        currentPlaylists.removeWhere((p) => p.id == playlistId);
        final listJson = currentPlaylists.map((p) => p.toJson()).toList();
        await _webPrefs?.setString('web_playlists', jsonEncode(listJson));
        if (kDebugMode) {
          print('Deleting web playlist ID: $playlistId');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error deleting web playlist: $e');
        }
      }
      return;
    }

    try {
      final db = await _dbHelper.database;
      await db.delete(
        'playlists',
        where: 'id = ?',
        whereArgs: [playlistId],
      );
      
      if (kDebugMode) {
        print('Deleting playlist ID: $playlistId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting playlist: $e');
      }
    }
  }
}
