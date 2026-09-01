import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/song_model.dart';
import '../models/album_model.dart';
import '../models/artist_model.dart';
import '../services/storage_service.dart';

class MusicController extends ChangeNotifier {
  final StorageService _storage = StorageService();
  bool _isStorageInitialized = false;
  List<String> _downloadedSongIds = [];

  List<SongModel> _songs = [];
  List<AlbumModel> _albums = [];
  List<ArtistModel> _artists = [];
  bool _isLoading = false;
  int? _activePort;
  String? _activeHost;

  List<SongModel> get songs => _songs;
  List<AlbumModel> get albums => _albums;
  List<ArtistModel> get artists => _artists;
  bool get isLoading => _isLoading;
  List<String> get downloadedSongIds => _downloadedSongIds;

  Future<void> _ensureStorage() async {
    if (!_isStorageInitialized) {
      await _storage.init();
      _isStorageInitialized = true;
    }
  }

  List<SongModel> get latestSongs {
    final list = List<SongModel>.from(_songs);
    list.sort((a, b) {
      final idA = int.tryParse(a.id) ?? 0;
      final idB = int.tryParse(b.id) ?? 0;
      return idB.compareTo(idA);
    });
    return list;
  }

  List<SongModel> get popularSongs {
    final list = List<SongModel>.from(_songs);
    list.sort((a, b) {
      final scoreA = a.streamCount + a.downloadCount;
      final scoreB = b.streamCount + b.downloadCount;
      return scoreB.compareTo(scoreA);
    });
    return list;
  }

  Future<void> logPlay(String songId) async {
    try {
      final Uri uri;
      if (ApiConstants.useLiveBackend) {
        uri = Uri.parse('${ApiConstants.baseUrl}/songs/$songId/play/');
      } else {
        final port = _activePort ?? await _findActivePort();
        if (port == null) return;
        final host = _activeHost ?? (Platform.isAndroid ? '10.0.2.2' : '127.0.0.1');
        uri = Uri.parse('http://$host:$port/api/songs/$songId/play/');
      }
      
      final response = await http.post(uri);
      if (kDebugMode) {
        print('Logged play for song $songId: status ${response.statusCode}');
      }
      
      final index = _songs.indexWhere((s) => s.id == songId);
      if (index != -1) {
        _songs[index] = _songs[index].copyWith(
          streamCount: _songs[index].streamCount + 1,
        );
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error logging play to backend: $e');
      }
    }
  }

  Future<void> logDownload(String songId) async {
    try {
      final Uri uri;
      if (ApiConstants.useLiveBackend) {
        uri = Uri.parse('${ApiConstants.baseUrl}/songs/$songId/download/');
      } else {
        final port = _activePort ?? await _findActivePort();
        if (port == null) return;
        final host = _activeHost ?? (Platform.isAndroid ? '10.0.2.2' : '127.0.0.1');
        uri = Uri.parse('http://$host:$port/api/songs/$songId/download/');
      }
      
      final response = await http.post(uri);
      if (kDebugMode) {
        print('Logged download for song $songId: status ${response.statusCode}');
      }
      
      final index = _songs.indexWhere((s) => s.id == songId);
      if (index != -1) {
        _songs[index] = _songs[index].copyWith(
          downloadCount: _songs[index].downloadCount + 1,
        );
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error logging download to backend: $e');
      }
    }
  }

  String _normalizeUrl(String? url, String host, int port) {
    if (url == null || url.isEmpty) return '';
    if (ApiConstants.useLiveBackend) {
      if (url.startsWith('/')) {
        return 'https://nupe-songs-backend1.onrender.com$url';
      }
      final regExp = RegExp(r'https?://(localhost|127\.0\.0\.1|10\.0\.2\.2)(:\d+)?');
      return url.replaceAllMapped(regExp, (match) => 'https://nupe-songs-backend1.onrender.com');
    } else {
      if (url.startsWith('/')) {
        return 'http://$host:$port$url';
      }
      final regExp = RegExp(r'https?://(localhost|127\.0\.0\.1|10\.0\.2\.2)(:\d+)?');
      return url.replaceAllMapped(regExp, (match) => 'http://$host:$port');
    }
  }

  String _normalizeAudioUrl(String? url, String host, int port) {
    String normalized = _normalizeUrl(url, host, port);
    if (normalized.contains('res.cloudinary.com') && normalized.contains('/image/upload/')) {
      normalized = normalized.replaceAll('/image/upload/', '/video/upload/');
    }
    return normalized;
  }

  Future<int?> _findActivePort() async {
    final host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
    final ports = [8000];
    for (final port in ports) {
      try {
        if (kDebugMode) {
          print('Probing port $port via socket connection...');
        }
        final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 2));
        socket.destroy();
        if (kDebugMode) {
          print('Socket connection succeeded on port $port! Server is listening.');
        }
        return port;
      } catch (e) {
        if (kDebugMode) {
          print('Socket probe failed for port $port: $e');
        }
      }
    }
    return null;
  }

  Future<void> loadMusic() async {
    _isLoading = true;
    notifyListeners();

    await _ensureStorage();
    final isFirstLaunch = _storage.getBool('music_is_first_launch', defaultValue: true);
    if (isFirstLaunch) {
      _downloadedSongIds = ['1', '2', '3', '4', '5'];
      await _storage.setString('music_downloaded_ids', jsonEncode(_downloadedSongIds));
      await _storage.setBool('music_is_first_launch', false);
    } else {
      final cachedIds = _storage.getString('music_downloaded_ids');
      if (cachedIds != null) {
        _downloadedSongIds = List<String>.from(jsonDecode(cachedIds));
      } else {
        _downloadedSongIds = [];
      }
    }

    try {
      if (ApiConstants.useLiveBackend) {
        final songsUri = Uri.parse('${ApiConstants.baseUrl}/songs');
        final albumsUri = Uri.parse('${ApiConstants.baseUrl}/albums');
        final artistsUri = Uri.parse('${ApiConstants.baseUrl}/artists');

        if (kDebugMode) {
          print('Fetching music from live backend: ${ApiConstants.baseUrl}');
        }

        final responses = await Future.wait([
          http.get(songsUri),
          http.get(albumsUri),
          http.get(artistsUri),
        ]).timeout(const Duration(seconds: 30));

        if (responses[0].statusCode == 200 &&
            responses[1].statusCode == 200 &&
            responses[2].statusCode == 200) {
          final List<dynamic> songsJson = jsonDecode(responses[0].body);
          final List<dynamic> albumsJson = jsonDecode(responses[1].body);
          final List<dynamic> artistsJson = jsonDecode(responses[2].body);

          final String host = '';
          final int port = 0;

          // Parse Artists
          final List<ArtistModel> backendArtists = [];
          for (final art in artistsJson) {
            backendArtists.add(ArtistModel(
              id: art['id'].toString(),
              name: art['name'] as String,
              imagePath: _normalizeUrl(art['image'] as String?, host, port),
              songIds: [],
              albumIds: [],
            ));
          }

          // Parse Albums
          final List<AlbumModel> backendAlbums = [];
          for (final alb in albumsJson) {
            final artistObj = alb['artist'];
            final artistName = artistObj != null ? artistObj['name'] as String : 'Unknown Artist';
            final List<String> songIds = [];
            if (alb['songs'] != null) {
              for (final s in alb['songs']) {
                songIds.add(s['id'].toString());
              }
            }
            backendAlbums.add(AlbumModel(
              id: alb['id'].toString(),
              name: alb['name'] as String,
              artist: artistName,
              artworkPath: _normalizeUrl(alb['artwork'] as String?, host, port),
              releaseYear: alb['release_year'] as int?,
              songIds: songIds,
            ));
          }

          // Parse Songs
          final List<SongModel> backendSongs = [];
          for (final s in songsJson) {
            final artistObj = s['artist'];
            final artistName = artistObj != null ? artistObj['name'] as String : 'Unknown Artist';
            final albumObj = s['album'];
            final albumName = albumObj != null ? albumObj['name'] as String : 'Single';
            final path = _normalizeAudioUrl(s['stream_url'] as String? ?? s['audio_file'] as String? ?? '', host, port);
            final duration = s['duration_ms'] as int? ?? 180000;
            backendSongs.add(SongModel(
              id: s['id'].toString(),
              title: s['title'] as String,
              artist: artistName,
              album: albumName,
              path: path,
              duration: duration,
              artworkPath: _normalizeUrl(s['artwork_url'] as String?, host, port),
              isFavorite: s['is_favorited'] as bool? ?? false,
              lyrics: s['lyrics'] as String?,
            ));
          }

          _songs = backendSongs;
          _albums = backendAlbums.map((album) {
            final songsOfAlbum = _songs.where((s) => s.album.toLowerCase() == album.name.toLowerCase()).map((s) => s.id).toList();
            return album.copyWith(songIds: songsOfAlbum);
          }).toList();
          _artists = backendArtists.map((artist) {
            final songsOfArtist = _songs.where((s) => s.artist.toLowerCase() == artist.name.toLowerCase()).map((s) => s.id).toList();
            final albumsOfArtist = _albums.where((a) => a.artist.toLowerCase() == artist.name.toLowerCase()).map((a) => a.id).toList();
            return artist.copyWith(
              songIds: songsOfArtist,
              albumIds: albumsOfArtist,
            );
          }).toList();

          if (kDebugMode) {
            print('Successfully loaded music data from live backend: ${_songs.length} songs, ${_albums.length} albums, ${_artists.length} artists.');
          }

          _isLoading = false;
          notifyListeners();
          return;
        }
      } else {
        final port = await _findActivePort();
        _activePort = port;
        if (port != null) {
          final host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
          _activeHost = host;
          if (kDebugMode) {
            print('Found active backend port: $port. Fetching content using host: $host');
          }
          final songsUri = Uri.parse('http://$host:$port/api/songs');
          final albumsUri = Uri.parse('http://$host:$port/api/albums');
          final artistsUri = Uri.parse('http://$host:$port/api/artists');

          final responses = await Future.wait([
            http.get(songsUri),
            http.get(albumsUri),
            http.get(artistsUri),
          ]).timeout(const Duration(seconds: 15));

          if (responses[0].statusCode == 200 &&
              responses[1].statusCode == 200 &&
              responses[2].statusCode == 200) {
            final List<dynamic> songsJson = jsonDecode(responses[0].body);
            final List<dynamic> albumsJson = jsonDecode(responses[1].body);
            final List<dynamic> artistsJson = jsonDecode(responses[2].body);

            // Parse Artists
            final List<ArtistModel> backendArtists = [];
            for (final art in artistsJson) {
              backendArtists.add(ArtistModel(
                id: art['id'].toString(),
                name: art['name'] as String,
                imagePath: _normalizeUrl(art['image'] as String?, host, port),
                songIds: [],
                albumIds: [],
              ));
            }

            // Parse Albums
            final List<AlbumModel> backendAlbums = [];
            for (final alb in albumsJson) {
              final artistObj = alb['artist'];
              final artistName = artistObj != null ? artistObj['name'] as String : 'Unknown Artist';
              final List<String> songIds = [];
              if (alb['songs'] != null) {
                for (final s in alb['songs']) {
                  songIds.add(s['id'].toString());
                }
              }
              backendAlbums.add(AlbumModel(
                id: alb['id'].toString(),
                name: alb['name'] as String,
                artist: artistName,
                artworkPath: _normalizeUrl(alb['artwork'] as String?, host, port),
                releaseYear: alb['release_year'] as int?,
                songIds: songIds,
              ));
            }

            // Parse Songs
            final List<SongModel> backendSongs = [];
            for (final s in songsJson) {
              final artistObj = s['artist'];
              final artistName = artistObj != null ? artistObj['name'] as String : 'Unknown Artist';
              final albumObj = s['album'];
              final albumName = albumObj != null ? albumObj['name'] as String : 'Single';
              final path = _normalizeAudioUrl(s['stream_url'] as String? ?? s['audio_file'] as String? ?? '', host, port);
              final duration = s['duration_ms'] as int? ?? 180000;
              backendSongs.add(SongModel(
                id: s['id'].toString(),
                title: s['title'] as String,
                artist: artistName,
                album: albumName,
                path: path,
                duration: duration,
                artworkPath: _normalizeUrl(s['artwork_url'] as String?, host, port),
                isFavorite: s['is_favorited'] as bool? ?? false,
                lyrics: s['lyrics'] as String?,
              ));
            }

            _songs = backendSongs;
            _albums = backendAlbums.map((album) {
              final songsOfAlbum = _songs.where((s) => s.album.toLowerCase() == album.name.toLowerCase()).map((s) => s.id).toList();
              return album.copyWith(songIds: songsOfAlbum);
            }).toList();
            _artists = backendArtists.map((artist) {
              final songsOfArtist = _songs.where((s) => s.artist.toLowerCase() == artist.name.toLowerCase()).map((s) => s.id).toList();
              final albumsOfArtist = _albums.where((a) => a.artist.toLowerCase() == artist.name.toLowerCase()).map((a) => a.id).toList();
              return artist.copyWith(
                songIds: songsOfArtist,
                albumIds: albumsOfArtist,
              );
            }).toList();

            if (kDebugMode) {
              print('Successfully loaded music data from backend: ${_songs.length} songs, ${_albums.length} albums, ${_artists.length} artists.');
            }

            _isLoading = false;
            notifyListeners();
            return;
          }
        } else {
          if (kDebugMode) {
            print('No active backend port found. Using local fallback.');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching music from backend: $e. Using local fallback.');
      }
    }

    // --- LOCAL FALLBACK DATA ---
    try {
      // Load real Nupe songs from assets with LRC-timestamped lyrics
      await Future.delayed(const Duration(milliseconds: 500));
      
      _songs = [
        SongModel(
          id: '1',
          title: 'Dabe Dabe',
          artist: 'Nupe Heritage',
          album: 'Nupe Classics',
          path: 'songs/Dabe_Dabe.mp3',
          duration: 156000,
          artworkPath: 'assets/images/chill_vibes.png',
          lyrics: '''[00:00.00] (Intro Music)
[00:04.00] Dabe Dabe, egi Nupe
[00:08.00] Gbakako wo, ezhi be kpokpo
[00:12.00] Dabe Dabe, egi Nupe
[00:16.00] Wo yi nupe, de wun na a
[00:20.00] (Melodious Instrumental)
[00:24.00] Gently, gently, child of Nupe
[00:28.00] Walk with pride, the land is bright
[00:32.00] Gently, gently, child of Nupe
[00:36.00] You are Nupe, never forget your roots
[00:40.00] (Instrumental Bridge)
[00:44.00] Ezhingi gwa, de emi gwa
[00:48.00] Soko be kpe, na wo ba lo
[00:52.00] Ka ji awo, Ka ji awo
[00:56.00] Nupe ye bo, yi de laka
[01:00.00] (English Translation)
[01:04.00] Hold my hand, hold my home
[01:08.00] Only God knows where you will go
[01:12.00] Do your best, do your best
[01:16.00] Nupe is loved, we have pride
[01:20.00] (Melodious Instrumental Solo)
[01:30.00] Dabe Dabe, egi Nupe
[01:34.00] Gbakako wo, ezhi be kpokpo
[01:38.00] Dabe Dabe, egi Nupe
[01:42.00] Wo yi nupe, de wun na a
[01:46.00] (English Chorus Repeat)
[01:50.00] Gently, gently, child of Nupe
[01:54.00] Walk with pride, the land is bright
[01:58.00] Gently, gently, child of Nupe
[02:02.00] You are Nupe, never forget your roots
[02:06.00] (Bridge Repeat)
[02:10.00] Ezhingi gwa, de emi gwa
[02:14.00] Soko be kpe, na wo ba lo
[02:18.00] Ka ji awo, Ka ji awo
[02:22.00] Nupe ye bo, yi de laka
[02:26.00] (Outro Music to end)
[02:35.00] (Song completed)''',
        ),
        SongModel(
          id: '2',
          title: 'Eganzuma',
          artist: 'Nupe Traditional',
          album: 'Nupe Classics',
          path: 'songs/Eganzuma.mp3',
          duration: 406000,
          artworkPath: 'assets/images/road_trip.png',
          lyrics: '''[00:00.00] (Intro Beat)
[00:08.00] Eganzuma, eganzuma
[00:13.00] Egan na wo ba na, de gbari a
[00:18.00] Eganzuma, eganzuma
[00:23.00] Wo da a kpa, egan nda ye
[00:28.00] (Drum Roll Instrumental)
[00:33.00] Words of wisdom, words of wisdom
[00:38.00] The words you speak have weight
[00:43.00] Words of wisdom, words of wisdom
[00:48.00] Remember the sayings of the elders
[00:53.00] (Instrumental Interlude)
[00:58.00] Soko da, wun yi gaba
[01:03.00] Enchi le yi, wun la wo gwa
[01:08.00] Gbako na wo ji, wun ge be
[01:13.00] Nupe ye bo, ezhi ge!
[01:18.00] (Traditional Flutes Solo)
[01:30.00] Walk high, speak true, child of Nupe
[01:35.00] For the ancestors stand with you
[01:40.00] Soko be ya wo, de nna ya
[01:45.00] Eganzuma, Nupe heritage!
[01:50.00] (Extended Rhythm Interlude)
[02:10.00] Eganzuma, eganzuma
[02:15.00] Egan na wo ba na, de gbari a
[02:20.00] Eganzuma, eganzuma
[02:25.00] Wo da a kpa, egan nda ye
[02:30.00] (Drum and Flutes Chorus)
[02:40.00] Words of wisdom, words of wisdom
[02:45.00] The words you speak have weight
[02:50.00] Words of wisdom, words of wisdom
[02:55.00] Remember the sayings of the elders
[03:00.00] (Acoustic Guitar Bridge)
[03:20.00] Soko da, wun yi gaba
[03:25.00] Enchi le yi, wun la wo gwa
[03:30.00] Gbako na wo ji, wun ge be
[03:35.00] Nupe ye bo, ezhi ge!
[03:40.00] (Melodic Flutes Solo)
[04:00.00] Walk high, speak true, child of Nupe
[04:05.00] For the ancestors stand with you
[04:10.00] Soko be ya wo, de nna ya
[04:15.00] Eganzuma, Nupe heritage!
[04:20.00] (Traditional Beat & Chants)
[04:40.00] Eganzuma, eganzuma
[04:45.00] Egan na wo ba na, de gbari a
[04:50.00] Eganzuma, eganzuma
[04:55.00] Wo da a kpa, egan nda ye
[05:00.00] (English Verse Repeat)
[05:05.00] Words of wisdom, words of wisdom
[05:10.00] The words you speak have weight
[05:15.00] Words of wisdom, words of wisdom
[05:20.00] Remember the sayings of the elders
[05:25.00] (Percussion and Flutes Solo)
[05:45.00] Soko da, wun yi gaba
[05:50.00] Enchi le yi, wun la wo gwa
[05:55.00] Gbako na wo ji, wun ge be
[06:00.00] Nupe ye bo, ezhi ge!
[06:05.00] (Traditional Flutes Outro)
[06:20.00] Eganzuma, Nupe heritage!
[06:30.00] (Outro Drums Fade)
[06:40.00] (Song completed)''',
        ),
        SongModel(
          id: '3',
          title: 'Haliya liya',
          artist: 'Nupe Melodies',
          album: 'Nupe Classics',
          path: 'songs/Haliya_liya.mp3',
          duration: 240000,
          artworkPath: 'assets/images/sunset_vibes.png',
          lyrics: '''[00:00.00] (Melody Intro)
[00:06.00] Haliya liya, haliya liya
[00:11.00] Hali gege yi wun nda be
[00:16.00] Haliya liya, haliya liya
[00:21.00] Soko ya wo, enchi gubakpa
[00:26.00] (Guitar Interlude)
[00:31.00] Melodies, melodies
[00:36.00] Good character is what shines
[00:41.00] Melodies, melodies
[00:46.00] May God grant you double blessings
[00:51.00] (Chorus Instrumental)
[00:56.00] Lilo ye bo, lilo ye bo
[01:01.00] Zhi na wo zhi, wo kpe nda ye
[01:06.00] Soko be ya wo, de nna ya
[01:11.00] Haliya ge, Nupe songs!
[01:16.00] (Guitar Solo Bridge)
[01:30.00] Haliya liya, haliya liya
[01:35.00] Hali gege yi wun nda be
[01:40.00] Haliya liya, haliya liya
[01:45.00] Soko ya wo, enchi gubakpa
[01:50.00] (Chorus Translation Repeat)
[01:55.00] Melodies, melodies
[02:00.00] Good character is what shines
[02:05.00] Melodies, melodies
[02:10.00] May God grant you double blessings
[02:15.00] (Synthesizer Interlude)
[02:30.00] Lilo ye bo, lilo ye bo
[02:35.00] Zhi na wo zhi, wo kpe nda ye
[02:40.00] Soko be ya wo, de nna ya
[02:45.00] Haliya ge, Nupe songs!
[02:50.00] (Bass and Guitar Bridge)
[03:05.00] Haliya liya, haliya liya
[03:10.00] Hali gege yi wun nda be
[03:15.00] Lilo ye bo, lilo ye bo
[03:20.00] Zhi na wo zhi, wo kpe nda ye
[03:25.00] (Outro Melody starts)
[03:40.00] Haliya ge, Nupe songs!
[03:45.00] (Outro Music to end)
[03:59.00] (Song completed)''',
        ),
        SongModel(
          id: '4',
          title: 'Mokwa',
          artist: 'Nupe Beats',
          album: 'Mokwa Riddims',
          path: 'songs/Mokwa.mp3',
          duration: 180000,
          artworkPath: 'assets/images/day_one.png',
          lyrics: '''[00:00.00] (Highlife Beat Intro)
[00:05.00] Mokwa, ezhi gege
[00:10.00] Mokwa, ezhi nupe
[00:15.00] Mokwa, na yi da na
[00:20.00] Ezhi ge, na wo kpa na
[00:25.00] (Brass Solo)
[00:30.00] Mokwa, the beautiful town
[00:35.00] Mokwa, the Nupe town
[00:40.00] Mokwa, where we belong
[00:45.00] A town of great history
[00:50.00] (Guitar Solo Bridge)
[00:55.00] Gbako be kpe, na yi lo na
[01:00.00] Emizhi Mokwa, de efa bo
[01:05.00] Soko be de, ezhi na yi
[01:10.00] Nupe songs, Mokwa riddims!
[01:15.00] (Highlife Beat Bridge)
[01:25.00] Mokwa, ezhi gege
[01:30.00] Mokwa, ezhi nupe
[01:35.00] Mokwa, na yi da na
[01:40.00] Ezhi ge, na wo kpa na
[01:45.00] (Brass and Guitar Interlude)
[01:55.00] Mokwa, the beautiful town
[02:00.00] Mokwa, the Nupe town
[02:05.00] Mokwa, where we belong
[02:10.00] A town of great history
[02:15.00] (Melodic Trumpets Bridge)
[02:25.00] Gbako be kpe, na yi lo na
[02:30.00] Emizhi Mokwa, de efa bo
[02:35.00] Soko be de, ezhi na yi
[02:40.00] Mokwa, ezhi gege!
[02:45.00] (Outro Horns to end)
[02:59.00] (Song completed)''',
        ),
        SongModel(
          id: '5',
          title: 'Nupe Class',
          artist: 'Nupe Academy',
          album: 'Nupe Classics',
          path: 'songs/Nupe_Class.mp3',
          duration: 204000,
          artworkPath: 'assets/images/study_focus.png',
          lyrics: '''[00:00.00] (Upbeat Intro)
[00:04.00] Nupe Class, yi ye nupe
[00:08.00] Gba gba gba, yi kpin nupe
[00:12.00] Nupe Class, yi ye nupe
[00:16.00] Ezhi gege, na wo kpe na
[00:20.00] (Synthesizer Bridge)
[00:24.00] Nupe Class, we speak Nupe
[00:28.00] Read, read, read, and learn Nupe
[00:32.00] Nupe Class, we speak Nupe
[00:36.00] The beautiful land we know
[00:40.00] (Classroom Chatter Beat)
[00:44.00] Egan Nupe, egan zhi ge
[00:48.00] Yi gba gba, yi kpin be
[00:52.00] Nnda, nnya, eginkpa ye
[00:56.00] Nupe class, learning culture!
[01:00.00] (Upbeat Synth Bridge)
[01:15.00] Nupe Class, yi ye nupe
[01:19.00] Gba gba gba, yi kpin nupe
[01:23.00] Nupe Class, yi ye nupe
[01:27.00] Ezhi gege, na wo kpe na
[01:31.00] (Synthesizer Solo)
[01:45.00] Nupe Class, we speak Nupe
[01:49.00] Read, read, read, and learn Nupe
[01:53.00] Nupe Class, we speak Nupe
[01:57.00] The beautiful land we know
[02:01.00] (Classroom Chatter Beat)
[02:15.00] Egan Nupe, egan zhi ge
[02:19.00] Yi gba gba, yi kpin be
[02:23.00] Nnda, nnya, eginkpa ye
[02:27.00] Nupe class, learning culture!
[02:32.00] (Classroom Chatter Bridge)
[02:45.00] Nupe Class, yi ye nupe
[02:49.00] Gba gba gba, yi kpin nupe
[02:53.00] Nupe Class, yi ye nupe
[02:57.00] Ezhi gege, na wo kpe na
[03:02.00] (Outro Synth Solo)
[03:15.00] Nupe class, learning culture!
[03:20.00] (Song ending)
[03:23.00] (Silence)''',
        ),
      ];

      _albums = [
        AlbumModel(
          id: 'a1',
          name: 'Nupe Classics',
          artist: 'Various Artists',
          artworkPath: 'assets/images/chill_vibes.png',
          songIds: ['1', '2', '3', '5'],
        ),
        AlbumModel(
          id: 'a2',
          name: 'Mokwa Riddims',
          artist: 'Nupe Beats',
          artworkPath: 'assets/images/day_one.png',
          songIds: ['4'],
        ),
      ];

      _artists = [
        ArtistModel(
          id: 'art1',
          name: 'Nupe Heritage',
          songIds: ['1'],
          albumIds: ['a1'],
        ),
        ArtistModel(
          id: 'art2',
          name: 'Nupe Traditional',
          songIds: ['2'],
          albumIds: ['a1'],
        ),
        ArtistModel(
          id: 'art3',
          name: 'Nupe Melodies',
          songIds: ['3'],
          albumIds: ['a1'],
        ),
        ArtistModel(
          id: 'art4',
          name: 'Nupe Beats',
          songIds: ['4'],
          albumIds: ['a2'],
        ),
        ArtistModel(
          id: 'art5',
          name: 'Nupe Academy',
          songIds: ['5'],
          albumIds: ['a1'],
        ),
      ];
    } catch (e) {
      if (kDebugMode) {
        print('Error loading music: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleFavorite(String songId) {
    final index = _songs.indexWhere((song) => song.id == songId);
    if (index != -1) {
      _songs[index] = _songs[index].copyWith(isFavorite: !_songs[index].isFavorite);
      notifyListeners();
    }
  }

  Future<void> downloadSong(String songId) async {
    await _ensureStorage();
    if (!_downloadedSongIds.contains(songId)) {
      _downloadedSongIds.add(songId);
      await _storage.setString('music_downloaded_ids', jsonEncode(_downloadedSongIds));
      notifyListeners();
    }
  }

  Future<void> deleteDownloadedSong(String songId) async {
    await _ensureStorage();
    if (_downloadedSongIds.contains(songId)) {
      _downloadedSongIds.remove(songId);
      await _storage.setString('music_downloaded_ids', jsonEncode(_downloadedSongIds));
      notifyListeners();
    }
  }

  Future<void> clearDownloadedSongIds() async {
    await _ensureStorage();
    _downloadedSongIds.clear();
    await _storage.setString('music_downloaded_ids', jsonEncode(_downloadedSongIds));
    notifyListeners();
  }
}
