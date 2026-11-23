enum PlaylistType {
  tv,
  vod,
}

class Playlist {
  final String id;
  final String name;
  final String url;
  final PlaylistType type;
  final int itemCount;
  final bool isActive;
  final DateTime createdAt;

  const Playlist({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
    this.itemCount = 0,
    this.isActive = false,
    required this.createdAt,
  });

  Playlist copyWith({
    String? id,
    String? name,
    String? url,
    PlaylistType? type,
    int? itemCount,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      type: type ?? this.type,
      itemCount: itemCount ?? this.itemCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'type': type.name,
      'itemCount': itemCount,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Sin nombre',
      url: json['url'] as String? ?? '',
      type: (json['type'] as String?) == 'vod' ? PlaylistType.vod : PlaylistType.tv,
      itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Playlist &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          url == other.url &&
          type == other.type &&
          isActive == other.isActive;

  @override
  int get hashCode => id.hashCode ^ url.hashCode ^ type.hashCode ^ isActive.hashCode;
}
