import 'dart:async';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class SettingsController extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _isFirstLaunch = true;
  bool _useEqualizer = false;
  String _equalizerPreset = 'Normal';
  int _crossfadeSeconds = 0;
  String _audioQuality = 'High'; // Low, Medium, High
  Duration? _sleepTimerDuration;
  bool _isSleepTimerActive = false;
  Timer? _timer;
  VoidCallback? onSleepTimerExpired;

  String _downloadQuality = 'High';
  bool _downloadOverWifi = true;
  String _downloadLocation = 'Internal Storage/Music';
  int _downloadedBytes = 1288490188;
  bool _hasUnreadNotifications = true;

  final StorageService _storage = StorageService();
  bool _isStorageInitialized = false;

  ThemeMode get themeMode => _themeMode;
  bool get useEqualizer => _useEqualizer;
  String get equalizerPreset => _equalizerPreset;
  int get crossfadeSeconds => _crossfadeSeconds;
  String get audioQuality => _audioQuality;
  Duration? get sleepTimerDuration => _sleepTimerDuration;
  bool get isSleepTimerActive => _isSleepTimerActive;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isFirstLaunch => _isFirstLaunch;

  String get downloadQuality => _downloadQuality;
  bool get downloadOverWifi => _downloadOverWifi;
  String get downloadLocation => _downloadLocation;
  int get downloadedBytes => _downloadedBytes;
  bool get hasUnreadNotifications => _hasUnreadNotifications;

  Future<void> _ensureStorage() async {
    if (!_isStorageInitialized) {
      await _storage.init();
      _isStorageInitialized = true;
    }
  }

  Future<void> loadSettings() async {
    await _ensureStorage();
    _isFirstLaunch = _storage.getBool('settings_is_first_launch', defaultValue: true);
    
    final themeStr = _storage.getString('settings_theme_mode') ?? 'system';
    if (themeStr == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (themeStr == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }
    
    _useEqualizer = _storage.getBool('settings_use_equalizer', defaultValue: false);
    _equalizerPreset = _storage.getString('settings_equalizer_preset') ?? 'Normal';
    _crossfadeSeconds = _storage.getInt('settings_crossfade_seconds', defaultValue: 0);
    _audioQuality = _storage.getString('settings_audio_quality') ?? 'High';
    _downloadQuality = _storage.getString('settings_download_quality') ?? 'High';
    _downloadOverWifi = _storage.getBool('settings_download_over_wifi', defaultValue: true);
    _downloadLocation = _storage.getString('settings_download_location') ?? 'Internal Storage/Music';
    _downloadedBytes = _storage.getInt('settings_downloaded_bytes', defaultValue: 1288490188);
    _hasUnreadNotifications = _storage.getBool('settings_has_unread_notifications', defaultValue: true);
    notifyListeners();
  }

  void completeOnboarding() async {
    _isFirstLaunch = false;
    notifyListeners();
    await _ensureStorage();
    await _storage.setBool('settings_is_first_launch', false);
  }

  void toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    await _ensureStorage();
    await _storage.setString('settings_theme_mode', isDark ? 'dark' : 'light');
  }

  void setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _ensureStorage();
    String themeStr = 'system';
    if (mode == ThemeMode.dark) themeStr = 'dark';
    if (mode == ThemeMode.light) themeStr = 'light';
    await _storage.setString('settings_theme_mode', themeStr);
  }

  void toggleEqualizer(bool value) async {
    _useEqualizer = value;
    notifyListeners();
    await _ensureStorage();
    await _storage.setBool('settings_use_equalizer', value);
  }

  void setAudioQuality(String quality) async {
    _audioQuality = quality;
    notifyListeners();
    await _ensureStorage();
    await _storage.setString('settings_audio_quality', quality);
  }

  void setDownloadQuality(String quality) async {
    _downloadQuality = quality;
    notifyListeners();
    await _ensureStorage();
    await _storage.setString('settings_download_quality', quality);
  }

  void toggleDownloadOverWifi(bool value) async {
    _downloadOverWifi = value;
    notifyListeners();
    await _ensureStorage();
    await _storage.setBool('settings_download_over_wifi', value);
  }

  void setDownloadLocation(String location) async {
    _downloadLocation = location;
    notifyListeners();
    await _ensureStorage();
    await _storage.setString('settings_download_location', location);
  }

  void clearDownloads() async {
    _downloadedBytes = 0;
    notifyListeners();
    await _ensureStorage();
    await _storage.setInt('settings_downloaded_bytes', 0);
  }

  void addDownloadedBytes(int bytes) async {
    _downloadedBytes += bytes;
    notifyListeners();
    await _ensureStorage();
    await _storage.setInt('settings_downloaded_bytes', _downloadedBytes);
  }

  void removeDownloadedBytes(int bytes) async {
    _downloadedBytes = (_downloadedBytes - bytes).clamp(0, 1288490188 * 10);
    notifyListeners();
    await _ensureStorage();
    await _storage.setInt('settings_downloaded_bytes', _downloadedBytes);
  }

  void markNotificationsRead() async {
    _hasUnreadNotifications = false;
    notifyListeners();
    await _ensureStorage();
    await _storage.setBool('settings_has_unread_notifications', false);
  }

  void setEqualizerPreset(String preset) async {
    _equalizerPreset = preset;
    notifyListeners();
    await _ensureStorage();
    await _storage.setString('settings_equalizer_preset', preset);
  }

  void setCrossfadeSeconds(int seconds) async {
    _crossfadeSeconds = seconds;
    notifyListeners();
    await _ensureStorage();
    await _storage.setInt('settings_crossfade_seconds', seconds);
  }

  void startSleepTimer(Duration duration) {
    _timer?.cancel();
    _sleepTimerDuration = duration;
    _isSleepTimerActive = true;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_sleepTimerDuration == null || _sleepTimerDuration!.inSeconds <= 1) {
        _timer?.cancel();
        _timer = null;
        _sleepTimerDuration = null;
        _isSleepTimerActive = false;
        notifyListeners();
        onSleepTimerExpired?.call();
      } else {
        _sleepTimerDuration = _sleepTimerDuration! - const Duration(seconds: 1);
        notifyListeners();
      }
    });
  }

  void cancelSleepTimer() {
    _timer?.cancel();
    _timer = null;
    _sleepTimerDuration = null;
    _isSleepTimerActive = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
