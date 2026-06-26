class ArtistModel {
  final String id;
  final String name;
  final String? imagePath;
  final String? bio;
  final List<String> songIds;
  final List<String> albumIds;

  ArtistModel({
    required this.id,
    required this.name,
    String? imagePath,
    this.bio,
    required this.songIds,
    required this.albumIds,
  }) : imagePath = (imagePath == null || imagePath.isEmpty)
            ? 'assets/images/app_logo.jpeg'
            : imagePath;

  factory ArtistModel.fromJson(Map<String, dynamic> json) {
    return ArtistModel(
      id: json['id'] as String,
      name: json['name'] as String,
      imagePath: json['imagePath'] as String?,
      bio: json['bio'] as String?,
      songIds: List<String>.from(json['songIds'] as List),
      albumIds: List<String>.from(json['albumIds'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imagePath': imagePath,
      'bio': bio,
      'songIds': songIds,
      'albumIds': albumIds,
    };
  }

  ArtistModel copyWith({
    String? id,
    String? name,
    String? imagePath,
    String? bio,
    List<String>? songIds,
    List<String>? albumIds,
  }) {
    return ArtistModel(
      id: id ?? this.id,
      name: name ?? this.name,
      imagePath: imagePath ?? this.imagePath,
      bio: bio ?? this.bio,
      songIds: songIds ?? this.songIds,
      albumIds: albumIds ?? this.albumIds,
    );
  }
}
