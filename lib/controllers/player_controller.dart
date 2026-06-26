import 'package:flutter/foundation.dart';
import '../models/song_model.dart';
import '../services/audio_service.dart';
import 'music_controller.dart';
import 'settings_controller.dart';

enum PlayerState { playing, paused, stopped }
enum RepeatMode { off, one, all }

class PlayerController extends ChangeNotifier {
  final AudioService _audioService = AudioService();
  final MusicController? _musicController;
  final SettingsController? _settingsController;
  SongModel? _currentSong;
  PlayerState _state = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  List<SongModel> _queue = [];
  int _currentIndex = -1;
  List<SongModel> _recentlyPlayed = [];
  
  bool _isShuffle = false;
  RepeatMode _repeatMode = RepeatMode.off;

  PlayerController({MusicController? musicController, SettingsController? settingsController})
      : _musicController = musicController,
        _settingsController = settingsController {
    _initAudio();
    _settingsController?.addListener(_applySettings);
  }

  void _initAudio() {
    _audioService.init(
      onSkipToNext: next,
      onSkipToPrevious: previous,
    );

    // Listen to current play position updates
    _audioService.onPositionChanged.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    // Listen to media duration updates
    _audioService.onDurationChanged.listen((dur) {
      _duration = dur;
      notifyListeners();
    });

    // Listen to playback complete event to auto-advance queue
    _audioService.onPlayerComplete.listen((_) {
      next();
    });
  }

  SongModel? get currentSong => _currentSong;
  PlayerState get state => _state;
  Duration get position => _position;
  Duration get duration => _duration;
  List<SongModel> get queue => _queue;
  List<SongModel> get recentlyPlayed => _recentlyPlayed;
  bool get isShuffle => _isShuffle;
  RepeatMode get repeatMode => _repeatMode;
  bool get isPlaying => _state == PlayerState.playing;
  double get volume => _audioService.volume;
  double _preMuteVolume = 1.0;
  String? _lastAudioQuality;

  void setVolume(double value) {
    if (value > 0.0) {
      _preMuteVolume = value;
    }
    _audioService.setVolume(value);
    notifyListeners();
  }

  void toggleMute() {
    if (volume > 0.0) {
      _preMuteVolume = volume;
      _audioService.setVolume(0.0);
    } else {
      _audioService.setVolume(_preMuteVolume > 0.0 ? _preMuteVolume : 1.0);
    }
    notifyListeners();
  }

  void _playCurrentSong() {
    if (_currentSong == null) return;
    
    _audioService.updateMetadata(
      id: _currentSong!.id,
      title: _currentSong!.title,
      artist: _currentSong!.artist,
      album: _currentSong!.album,
      durationMs: _currentSong!.duration,
      artworkPath: _currentSong!.artworkPath,
    );
    
    _audioService.play(_currentSong!.path);
    _applySettings();
    _musicController?.logPlay(_currentSong!.id);
    _addToRecentlyPlayed(_currentSong!);
  }

  void _addToRecentlyPlayed(SongModel song) {
    // Remove if already in the list (deduplicate)
    _recentlyPlayed.removeWhere((s) => s.id == song.id);
    // Add to the front (most recent first)
    _recentlyPlayed.insert(0, song);
    // Keep only the last 20
    if (_recentlyPlayed.length > 20) {
      _recentlyPlayed = _recentlyPlayed.sublist(0, 20);
    }
  }

  void playSong(SongModel song, List<SongModel> newQueue) {
    _currentSong = song;
    _queue = newQueue;
    _currentIndex = _queue.indexWhere((s) => s.id == song.id);
    _state = PlayerState.playing;
    _duration = Duration(milliseconds: song.duration);
    _position = Duration.zero;
    notifyListeners();
    
    _playCurrentSong();
  }

  void pause() {
    if (_state == PlayerState.playing) {
      _state = PlayerState.paused;
      notifyListeners();
      _audioService.pause();
    }
  }

  void resume() {
    if (_state == PlayerState.paused) {
      _state = PlayerState.playing;
      notifyListeners();
      _audioService.resume();
    }
  }

  void stop() {
    _state = PlayerState.stopped;
    _position = Duration.zero;
    notifyListeners();
    _audioService.stop();
  }

  void seek(Duration position) {
    _position = position;
    notifyListeners();
    _audioService.seek(position);
  }

  void next() {
    if (_queue.isEmpty) return;
    if (_repeatMode == RepeatMode.one) {
      if (_currentSong != null) {
        seek(Duration.zero);
        _playCurrentSong();
      }
      return;
    }

    int nextIndex = _currentIndex + 1;
    if (nextIndex >= _queue.length) {
      if (_repeatMode == RepeatMode.all) {
        nextIndex = 0;
      } else {
        stop();
        return;
      }
    }
    
    _currentIndex = nextIndex;
    _currentSong = _queue[_currentIndex];
    _duration = Duration(milliseconds: _currentSong!.duration);
    _position = Duration.zero;
    _state = PlayerState.playing;
    notifyListeners();
    
    _playCurrentSong();
  }

  void previous() {
    if (_queue.isEmpty) return;
    
    int prevIndex = _currentIndex - 1;
    if (prevIndex < 0) {
      if (_repeatMode == RepeatMode.all) {
        prevIndex = _queue.length - 1;
      } else {
        seek(Duration.zero);
        return;
      }
    }

    _currentIndex = prevIndex;
    _currentSong = _queue[_currentIndex];
    _duration = Duration(milliseconds: _currentSong!.duration);
    _position = Duration.zero;
    _state = PlayerState.playing;
    notifyListeners();
    
    _playCurrentSong();
  }

  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    notifyListeners();
  }

  void toggleRepeatMode() {
    switch (_repeatMode) {
      case RepeatMode.off:
        _repeatMode = RepeatMode.all;
        break;
      case RepeatMode.all:
        _repeatMode = RepeatMode.one;
        break;
      case RepeatMode.one:
        _repeatMode = RepeatMode.off;
        break;
    }
    notifyListeners();
  }

  void setRepeatMode(RepeatMode mode) {
    _repeatMode = mode;
    notifyListeners();
  }

  void updatePosition(Duration position) {
    _position = position;
    notifyListeners();
  }

  void _applySettings() {
    final settings = _settingsController;
    if (settings != null) {
      applyEqualizerPreset(
        settings.equalizerPreset,
        settings.useEqualizer,
      );

      if (_lastAudioQuality != settings.audioQuality) {
        final oldQuality = _lastAudioQuality;
        _lastAudioQuality = settings.audioQuality;
        if (oldQuality != null && _state == PlayerState.playing) {
          _simulateQualitySwitch();
        }
      }
    }
  }

  Future<void> _simulateQualitySwitch() async {
    _state = PlayerState.paused;
    notifyListeners();
    await _audioService.pause();
    
    // Simulate loading/buffering quality stream
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (_state == PlayerState.paused) {
      _state = PlayerState.playing;
      notifyListeners();
      await _audioService.resume();
    }
  }

  void applyEqualizerPreset(String preset, bool enabled) {
    if (!enabled) {
      _audioService.setPlaybackRate(1.0);
      _audioService.setBalance(0.0);
      return;
    }

    switch (preset) {
      case "Normal":
        _audioService.setPlaybackRate(1.0);
        _audioService.setBalance(0.0);
        break;
      case "Pop":
        _audioService.setPlaybackRate(1.02);
        _audioService.setBalance(0.0);
        break;
      case "Rock":
        _audioService.setPlaybackRate(1.03);
        _audioService.setBalance(0.15);
        break;
      case "Jazz":
        _audioService.setPlaybackRate(0.97);
        _audioService.setBalance(-0.1);
        break;
      case "Classical":
        _audioService.setPlaybackRate(0.98);
        _audioService.setBalance(-0.15);
        break;
      case "Hip Hop":
        _audioService.setPlaybackRate(1.05);
        _audioService.setBalance(0.1);
        break;
    }
  }

  @override
  void dispose() {
    _settingsController?.removeListener(_applySettings);
    _audioService.dispose();
    super.dispose();
  }
}
