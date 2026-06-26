class AlbumModel {
  final String id;
  final String name;
  final String artist;
  final String? artworkPath;
  final int? releaseYear;
  final List<String> songIds;

  AlbumModel({
    required this.id,
    required this.name,
    required this.artist,
    String? artworkPath,
    this.releaseYear,
    required this.songIds,
  }) : artworkPath = (artworkPath == null || artworkPath.isEmpty)
            ? 'assets/images/app_logo.jpeg'
            : artworkPath;

  factory AlbumModel.fromJson(Map<String, dynamic> json) {
    return AlbumModel(
      id: json['id'] as String,
      name: json['name'] as String,
      artist: json['artist'] as String,
      artworkPath: json['artworkPath'] as String?,
      releaseYear: json['releaseYear'] as int?,
      songIds: List<String>.from(json['songIds'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'artist': artist,
      'artworkPath': artworkPath,
      'releaseYear': releaseYear,
      'songIds': songIds,
    };
  }

  AlbumModel copyWith({
    String? id,
    String? name,
    String? artist,
    String? artworkPath,
    int? releaseYear,
    List<String>? songIds,
  }) {
    return AlbumModel(
      id: id ?? this.id,
      name: name ?? this.name,
      artist: artist ?? this.artist,
      artworkPath: artworkPath ?? this.artworkPath,
      releaseYear: releaseYear ?? this.releaseYear,
      songIds: songIds ?? this.songIds,
    );
  }
}
