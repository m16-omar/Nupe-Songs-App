import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  SharedPreferences? _prefs;

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      if (kDebugMode) {
        print('StorageService initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing StorageService: $e');
      }
    }
  }

  Future<bool> setBool(String key, bool value) async {
    if (_prefs == null) return false;
    return await _prefs!.setBool(key, value);
  }

  bool getBool(String key, {bool defaultValue = false}) {
    if (_prefs == null) return defaultValue;
    return _prefs!.getBool(key) ?? defaultValue;
  }

  Future<bool> setString(String key, String value) async {
    if (_prefs == null) return false;
    return await _prefs!.setString(key, value);
  }

  String? getString(String key) {
    if (_prefs == null) return null;
    return _prefs!.getString(key);
  }

  Future<bool> setInt(String key, int value) async {
    if (_prefs == null) return false;
    return await _prefs!.setInt(key, value);
  }

  int getInt(String key, {int defaultValue = 0}) {
    if (_prefs == null) return defaultValue;
    return _prefs!.getInt(key) ?? defaultValue;
  }

  Future<bool> remove(String key) async {
    if (_prefs == null) return false;
    return await _prefs!.remove(key);
  }

  Future<bool> clear() async {
    if (_prefs == null) return false;
    return await _prefs!.clear();
  }
}
