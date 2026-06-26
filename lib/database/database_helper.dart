import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class DatabaseHelper {
  // Singleton instance
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    await initDatabase();
    return _database!;
  }

  Future<void> initDatabase() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = p.join(databasesPath, 'nupe_songs.db');

      _database = await openDatabase(
        path,
        version: 1,
        onCreate: (Database db, int version) async {
          // Create playlists table
          await db.execute('''
            CREATE TABLE playlists (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              description TEXT,
              songIds TEXT NOT NULL,
              artworkPath TEXT,
              createdAt TEXT NOT NULL
            )
          ''');
        },
      );

      if (kDebugMode) {
        print('DatabaseHelper initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing database: $e');
      }
    }
  }

  Future<void> clearDatabase() async {
    try {
      final db = await database;
      await db.delete('playlists');
      if (kDebugMode) {
        print('Database cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing database: $e');
      }
    }
  }
}
