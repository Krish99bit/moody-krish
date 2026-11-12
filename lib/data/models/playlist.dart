class Playlist {
  final int? id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final String? artworkPath;
  final int songCount;

  Playlist({
    this.id,
    required this.name,
    this.description,
    required this.createdAt,
    this.artworkPath,
    this.songCount = 0,
  });

  Playlist copyWith({
    int? id,
    String? name,
    String? description,
    DateTime? createdAt,
    String? artworkPath,
    int? songCount,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      artworkPath: artworkPath ?? this.artworkPath,
      songCount: songCount ?? this.songCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt.millisecondsSinceEpoch,
      'artwork_path': artworkPath,
    };
  }

  factory Playlist.fromMap(Map<String, dynamic> map, {int songCount = 0}) {
    return Playlist(
      id: map['id'] as int?,
      name: map['name'] as String? ?? 'Untitled Playlist',
      description: map['description'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int)
          : DateTime.now(),
      artworkPath: map['artwork_path'] as String?,
      songCount: songCount,
    );
  }
}
