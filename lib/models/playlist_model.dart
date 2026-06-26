class PlaylistModel {
  final String id;
  final String name;
  final String? description;
  final List<String> songIds;
  final String? artworkPath;
  final DateTime createdAt;

  PlaylistModel({
    required this.id,
    required this.name,
    this.description,
    required this.songIds,
    this.artworkPath,
    required this.createdAt,
  });

  factory PlaylistModel.fromJson(Map<String, dynamic> json) {
    return PlaylistModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      songIds: List<String>.from(json['songIds'] as List),
      artworkPath: json['artworkPath'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'songIds': songIds,
      'artworkPath': artworkPath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  PlaylistModel copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? songIds,
    String? artworkPath,
    DateTime? createdAt,
  }) {
    return PlaylistModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      songIds: songIds ?? this.songIds,
      artworkPath: artworkPath ?? this.artworkPath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
