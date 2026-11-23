import 'package:flutter/foundation.dart';

class Channel {
  final String id;
  final String name;
  final String streamUrl;
  final String? logo;
  final String category;
  final String? group;
  final String? tvgId;
  final String source; // 'iptv_org', 'wiwy', 'custom'
  final bool isFavorite;
  final String country;
  final String countryCode;
  final String flag;
  final String language;

  const Channel({
    required this.id,
    required this.name,
    required this.streamUrl,
    this.logo,
    required this.category,
    this.group,
    this.tvgId,
    this.source = 'iptv_org',
    this.isFavorite = false,
    this.country = 'Latinoamérica',
    this.countryCode = 'LAT',
    this.flag = '🌎',
    this.language = 'Español',
  });

  Channel copyWith({
    String? id,
    String? name,
    String? streamUrl,
    String? logo,
    String? category,
    String? group,
    String? tvgId,
    String? source,
    bool? isFavorite,
    String? country,
    String? countryCode,
    String? flag,
    String? language,
  }) {
    return Channel(
      id: id ?? this.id,
      name: name ?? this.name,
      streamUrl: streamUrl ?? this.streamUrl,
      logo: logo ?? this.logo,
      category: category ?? this.category,
      group: group ?? this.group,
      tvgId: tvgId ?? this.tvgId,
      source: source ?? this.source,
      isFavorite: isFavorite ?? this.isFavorite,
      country: country ?? this.country,
      countryCode: countryCode ?? this.countryCode,
      flag: flag ?? this.flag,
      language: language ?? this.language,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'streamUrl': streamUrl,
      'logo': logo,
      'category': category,
      'group': group,
      'tvgId': tvgId,
      'source': source,
      'isFavorite': isFavorite,
      'country': country,
      'countryCode': countryCode,
      'flag': flag,
      'language': language,
    };
  }

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      id: json['id'] as String? ?? UniqueKey().toString(),
      name: json['name'] as String? ?? 'Canal desconocido',
      streamUrl: json['streamUrl'] as String? ?? '',
      logo: json['logo'] as String?,
      category: json['category'] as String? ?? 'Entretenimiento',
      group: json['group'] as String?,
      tvgId: json['tvgId'] as String?,
      source: json['source'] as String? ?? 'iptv_org',
      isFavorite: json['isFavorite'] as bool? ?? false,
      country: json['country'] as String? ?? 'Latinoamérica',
      countryCode: json['countryCode'] as String? ?? 'LAT',
      flag: json['flag'] as String? ?? '🌎',
      language: json['language'] as String? ?? 'Español',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Channel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
