import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart' as auds;
import 'package:audioplayers/audioplayers.dart';

class MyAudioHandler extends auds.BaseAudioHandler with auds.QueueHandler {
  final AudioPlayer _player = AudioPlayer();
  VoidCallback? onSkipToNext;
  VoidCallback? onSkipToPrevious;

  MyAudioHandler() {
    _initStreams();
    playbackState.add(auds.PlaybackState(
      controls: [
        auds.MediaControl.skipToPrevious,
        auds.MediaControl.play,
        auds.MediaControl.stop,
        auds.MediaControl.skipToNext,
      ],
      systemActions: const {
        auds.MediaAction.seek,
        auds.MediaAction.seekForward,
        auds.MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      playing: false,
      processingState: auds.AudioProcessingState.idle,
    ));
  }

  AudioPlayer get player => _player;

  void _initStreams() {
    // Listen to player state changes to update the notification play/pause state
    _player.onPlayerStateChanged.listen((state) {
      _updatePlaybackState(state);
    });

    // Listen to position changes to update seekbar in notification
    _player.onPositionChanged.listen((pos) {
      playbackState.add(playbackState.value.copyWith(
        updatePosition: pos,
      ));
    });
  }

  void _updatePlaybackState(PlayerState state) {
    final playing = state == PlayerState.playing;
    playbackState.add(playbackState.value.copyWith(
      controls: [
        auds.MediaControl.skipToPrevious,
        if (playing) auds.MediaControl.pause else auds.MediaControl.play,
        auds.MediaControl.stop,
        auds.MediaControl.skipToNext,
      ],
      systemActions: const {
        auds.MediaAction.seek,
        auds.MediaAction.seekForward,
        auds.MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      playing: playing,
      processingState: const {
        PlayerState.playing: auds.AudioProcessingState.ready,
        PlayerState.paused: auds.AudioProcessingState.ready,
        PlayerState.stopped: auds.AudioProcessingState.idle,
        PlayerState.completed: auds.AudioProcessingState.completed,
      }[state] ?? auds.AudioProcessingState.idle,
    ));
  }

  Future<void> playPath(String path) async {
    String finalPath = path.trim();
    if (finalPath.contains('res.cloudinary.com') && finalPath.contains('/image/upload/')) {
      finalPath = finalPath.replaceAll('/image/upload/', '/video/upload/');
    }
    if (finalPath.startsWith('http://') || finalPath.startsWith('https://')) {
      await _player.play(UrlSource(finalPath));
    } else {
      await _player.play(AssetSource(finalPath));
    }
  }

  void updateMetadata({
    required String id,
    required String title,
    required String artist,
    required String album,
    required int durationMs,
    String? artworkPath,
  }) {
    Uri? validArtUri;
    if (artworkPath != null && artworkPath.isNotEmpty) {
      if (artworkPath.startsWith('http://') || artworkPath.startsWith('https://') || artworkPath.startsWith('file://')) {
        validArtUri = Uri.tryParse(artworkPath);
      }
    }

    mediaItem.add(auds.MediaItem(
      id: id,
      album: album,
      title: title,
      artist: artist,
      duration: Duration(milliseconds: durationMs),
      artUri: validArtUri,
    ));
  }

  @override
  Future<void> play() async {
    await _player.resume();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    if (onSkipToNext != null) {
      onSkipToNext!();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (onSkipToPrevious != null) {
      onSkipToPrevious!();
    }
  }
}

class AudioService {
  static late MyAudioHandler handler;

  // Stream getters for position, duration, and completion events
  Stream<Duration> get onPositionChanged => handler.player.onPositionChanged;
  Stream<Duration> get onDurationChanged => handler.player.onDurationChanged;
  Stream<void> get onPlayerComplete => handler.player.onPlayerComplete;

  double get volume => handler.player.volume;
  bool get isPlaying => handler.player.state == PlayerState.playing;

  Future<void> init({VoidCallback? onSkipToNext, VoidCallback? onSkipToPrevious}) async {
    handler.onSkipToNext = onSkipToNext;
    handler.onSkipToPrevious = onSkipToPrevious;
    if (kDebugMode) {
      print('AudioService initialized with callbacks');
    }
  }

  Future<void> play(String path) async {
    if (kDebugMode) {
      print('Playing audio: $path');
    }
    await handler.playPath(path);
  }

  Future<void> pause() async {
    if (kDebugMode) {
      print('Audio playback paused');
    }
    await handler.pause();
  }

  Future<void> resume() async {
    if (kDebugMode) {
      print('Audio playback resumed');
    }
    await handler.play();
  }

  Future<void> stop() async {
    if (kDebugMode) {
      print('Audio playback stopped');
    }
    await handler.stop();
  }

  Future<void> seek(Duration position) async {
    if (kDebugMode) {
      print('Seeking to: $position');
    }
    await handler.seek(position);
  }

  Future<void> setVolume(double volume) async {
    if (kDebugMode) {
      print('Volume set to: $volume');
    }
    await handler.player.setVolume(volume.clamp(0.0, 1.0));
  }

  Future<void> setPlaybackRate(double rate) async {
    await handler.player.setPlaybackRate(rate);
  }

  Future<void> setBalance(double balance) async {
    await handler.player.setBalance(balance);
  }

  void updateMetadata({
    required String id,
    required String title,
    required String artist,
    required String album,
    required int durationMs,
    String? artworkPath,
  }) {
    handler.updateMetadata(
      id: id,
      title: title,
      artist: artist,
      album: album,
      durationMs: durationMs,
      artworkPath: artworkPath,
    );
  }

  Future<void> dispose() async {
    // We don't dispose the global handler here as it lives with the application lifecycle
  }
}
