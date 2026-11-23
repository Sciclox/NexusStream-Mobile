import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/network_defaults.dart';
import '../models/channel.dart';
import '../models/playlist.dart';
import '../wiwy/wiwy_vod.dart';

class StorageService {
  static const String _keyFavorites = 'favorites';
  static const String _keyWallpaper = 'wallpaper';
  static const String _keyAccent = 'accent';
  static const String _keyUseWiwy = 'use_wiwy';
  static const String _keyVpnAuto = 'vpn_auto';
  static const String _keyM3uCache = 'm3u_cached_channels';
  static const String _keyDevId = 'custom_dev_id';
  static const String _keyUserId = 'custom_user_id';
  static const String _keyCustomM3uUrl = 'custom_m3u_url';
  static const String _keyCustomVodUrl = 'custom_vod_url';
  static const String _keyVodCache = 'vod_cached_assets';
  static const String _keyPlaylists = 'saved_playlists';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // --- Identidad del Dispositivo (dev_id y user_id) ---
  String getDevId() => _prefs.getString(_keyDevId) ?? NetworkDefaults.hardcodedDeviceSeed;
  Future<bool> setDevId(String val) => _prefs.setString(_keyDevId, val.trim());

  String getUserId() => _prefs.getString(_keyUserId) ?? '978939558';
  Future<bool> setUserId(String val) => _prefs.setString(_keyUserId, val.trim());

  Future<void> resetIdentity() async {
    await _prefs.remove(_keyDevId);
    await _prefs.remove(_keyUserId);
  }

  // --- Favoritos ---
  Set<String> getFavoriteIds() {
    final list = _prefs.getStringList(_keyFavorites) ?? [];
    return list.toSet();
  }

  Future<bool> saveFavoriteIds(Set<String> ids) async {
    return await _prefs.setStringList(_keyFavorites, ids.toList());
  }

  Future<bool> toggleFavorite(String channelId) async {
    final current = getFavoriteIds();
    if (current.contains(channelId)) {
      current.remove(channelId);
    } else {
      current.add(channelId);
    }
    return await saveFavoriteIds(current);
  }

  Future<bool> clearFavorites() async {
    return await _prefs.remove(_keyFavorites);
  }

  // --- Temas & Wallpapers ---
  String? getWallpaperId() => _prefs.getString(_keyWallpaper);
  Future<bool> setWallpaperId(String id) => _prefs.setString(_keyWallpaper, id);

  String? getAccentName() => _prefs.getString(_keyAccent);
  Future<bool> setAccentName(String name) => _prefs.setString(_keyAccent, name);

  // --- Wiwy & VPN Toggles ---
  bool getUseWiwy() => _prefs.getBool(_keyUseWiwy) ?? false;
  Future<bool> setUseWiwy(bool val) => _prefs.setBool(_keyUseWiwy, val);

  bool getVpnAuto() => _prefs.getBool(_keyVpnAuto) ?? false;
  Future<bool> setVpnAuto(bool val) => _prefs.setBool(_keyVpnAuto, val);

  // --- Canales Cacheados ---
  List<Channel> getCachedChannels() {
    final raw = _prefs.getString(_keyM3uCache);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List decoded = jsonDecode(raw);
      return decoded.map((item) => Channel.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> saveCachedChannels(List<Channel> channels) async {
    try {
      final raw = jsonEncode(channels.map((c) => c.toJson()).toList());
      return await _prefs.setString(_keyM3uCache, raw);
    } catch (_) {
      return false;
    }
  }

  // --- Lista IPTV Personalizada (M3U / M3U8) ---
  String getCustomM3uUrl() => _prefs.getString(_keyCustomM3uUrl) ?? '';
  Future<bool> setCustomM3uUrl(String url) => _prefs.setString(_keyCustomM3uUrl, url.trim());
  Future<bool> clearCustomM3uUrl() => _prefs.remove(_keyCustomM3uUrl);

  // --- Lista VOD Personalizada (Películas y Series) ---
  String getCustomVodUrl() => _prefs.getString(_keyCustomVodUrl) ?? '';
  Future<bool> setCustomVodUrl(String url) => _prefs.setString(_keyCustomVodUrl, url.trim());
  Future<bool> clearCustomVodUrl() => _prefs.remove(_keyCustomVodUrl);

  List<WiwyVodAsset> getCachedVodAssets() {
    final raw = _prefs.getString(_keyVodCache);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List decoded = jsonDecode(raw);
      return decoded.map((item) => WiwyVodAsset.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> saveCachedVodAssets(List<WiwyVodAsset> assets) async {
    try {
      final raw = jsonEncode(assets.map((a) => a.toJson()).toList());
      return await _prefs.setString(_keyVodCache, raw);
    } catch (_) {
      return false;
    }
  }

  // --- Gestor de Múltiples Listas de Reproducción (IPTV y VOD) ---
  List<Playlist> getSavedPlaylists() {
    final raw = _prefs.getString(_keyPlaylists);
    if (raw == null || raw.isEmpty) {
      final list = <Playlist>[];
      final customM3u = getCustomM3uUrl();
      if (customM3u.isNotEmpty) {
        list.add(Playlist(
          id: 'migrated_tv',
          name: 'Mi Lista IPTV',
          url: customM3u,
          type: PlaylistType.tv,
          isActive: true,
          createdAt: DateTime.now(),
        ));
      }
      final customVod = getCustomVodUrl();
      if (customVod.isNotEmpty) {
        list.add(Playlist(
          id: 'migrated_vod',
          name: 'Mi Catálogo VOD',
          url: customVod,
          type: PlaylistType.vod,
          isActive: true,
          createdAt: DateTime.now(),
        ));
      }
      return list;
    }

    try {
      final List decoded = jsonDecode(raw);
      return decoded.map((item) => Playlist.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> savePlaylists(List<Playlist> playlists) async {
    try {
      final raw = jsonEncode(playlists.map((p) => p.toJson()).toList());
      return await _prefs.setString(_keyPlaylists, raw);
    } catch (_) {
      return false;
    }
  }

  Future<bool> addOrUpdatePlaylist(Playlist playlist) async {
    final current = getSavedPlaylists();
    final index = current.indexWhere((p) => p.id == playlist.id);

    List<Playlist> updated = [];
    for (final p in current) {
      if (p.id == playlist.id) {
        updated.add(playlist);
      } else if (playlist.isActive && p.type == playlist.type) {
        updated.add(p.copyWith(isActive: false));
      } else {
        updated.add(p);
      }
    }

    if (index == -1) {
      if (playlist.isActive) {
        updated = updated.map((p) => p.type == playlist.type ? p.copyWith(isActive: false) : p).toList();
      }
      updated.add(playlist);
    }

    if (playlist.isActive) {
      if (playlist.type == PlaylistType.tv) {
        await setCustomM3uUrl(playlist.url);
      } else {
        await setCustomVodUrl(playlist.url);
      }
    }

    return await savePlaylists(updated);
  }

  Future<bool> removePlaylist(String id) async {
    final current = getSavedPlaylists();
    final toRemove = current.where((p) => p.id == id).firstOrNull;
    final updated = current.where((p) => p.id != id).toList();

    if (toRemove != null && toRemove.isActive) {
      if (toRemove.type == PlaylistType.tv) {
        await clearCustomM3uUrl();
      } else {
        await clearCustomVodUrl();
      }
    }

    return await savePlaylists(updated);
  }

  Future<bool> setActivePlaylist(String id, PlaylistType type) async {
    final current = getSavedPlaylists();
    String? activeUrl;
    final updated = current.map((p) {
      if (p.type == type) {
        final makeActive = (p.id == id);
        if (makeActive) activeUrl = p.url;
        return p.copyWith(isActive: makeActive);
      }
      return p;
    }).toList();

    if (activeUrl != null) {
      if (type == PlaylistType.tv) {
        await setCustomM3uUrl(activeUrl!);
      } else {
        await setCustomVodUrl(activeUrl!);
      }
    } else {
      if (type == PlaylistType.tv) {
        await clearCustomM3uUrl();
      } else {
        await clearCustomVodUrl();
      }
    }

    return await savePlaylists(updated);
  }
}
