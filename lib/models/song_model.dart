class LyricLine {
  final Duration time;
  final String text;

  LyricLine({required this.time, required this.text});
}

class SongModel {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String path;
  final int duration; // in milliseconds
  final String? artworkPath;
  final bool isFavorite;
  final String? lyrics;
  final int streamCount;
  final int downloadCount;
  final String? genre;

  SongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.path,
    required this.duration,
    String? artworkPath,
    this.isFavorite = false,
    this.lyrics,
    this.streamCount = 0,
    this.downloadCount = 0,
    this.genre,
  }) : artworkPath = (artworkPath == null || artworkPath.isEmpty)
            ? 'assets/images/app_logo.jpeg'
            : artworkPath;

  // Parse LRC formatted string [mm:ss.SS] text into structured LyricLines
  List<LyricLine> get parsedLyrics {
    if (lyrics == null || lyrics!.isEmpty) return [];
    final lines = lyrics!.split('\n');
    final List<LyricLine> list = [];
    final regex = RegExp(r'^\[(\d+):(\d+)\.(\d+)\](.*)$');
    for (final line in lines) {
      final match = regex.firstMatch(line.trim());
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final centiseconds = int.parse(match.group(3)!);
        final text = match.group(4)!.trim();
        final time = Duration(
          minutes: minutes,
          seconds: seconds,
          milliseconds: centiseconds * 10,
        );
        list.add(LyricLine(time: time, text: text));
      } else {
        if (line.trim().isNotEmpty) {
          list.add(LyricLine(time: Duration.zero, text: line.trim()));
        }
      }
    }
    return list;
  }

  factory SongModel.fromJson(Map<String, dynamic> json) {
    String? genreName;
    if (json['genre'] != null) {
      if (json['genre'] is Map) {
        genreName = json['genre']['name'] as String?;
      } else if (json['genre'] is String) {
        genreName = json['genre'] as String;
      }
    }
    return SongModel(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      album: json['album'] as String,
      path: json['path'] as String,
      duration: json['duration'] as int,
      artworkPath: json['artworkPath'] as String?,
      isFavorite: json['isFavorite'] as bool? ?? false,
      lyrics: json['lyrics'] as String?,
      streamCount: json['streamCount'] as int? ?? json['stream_count'] as int? ?? 0,
      downloadCount: json['downloadCount'] as int? ?? json['download_count'] as int? ?? 0,
      genre: genreName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'path': path,
      'duration': duration,
      'artworkPath': artworkPath,
      'isFavorite': isFavorite,
      'lyrics': lyrics,
      'streamCount': streamCount,
      'downloadCount': downloadCount,
      'genre': genre,
    };
  }

  SongModel copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? path,
    int? duration,
    String? artworkPath,
    bool? isFavorite,
    String? lyrics,
    int? streamCount,
    int? downloadCount,
    String? genre,
  }) {
    return SongModel(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      path: path ?? this.path,
      duration: duration ?? this.duration,
      artworkPath: artworkPath ?? this.artworkPath,
      isFavorite: isFavorite ?? this.isFavorite,
      lyrics: lyrics ?? this.lyrics,
      streamCount: streamCount ?? this.streamCount,
      downloadCount: downloadCount ?? this.downloadCount,
      genre: genre ?? this.genre,
    );
  }
}
