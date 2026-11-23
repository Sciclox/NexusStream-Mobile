import 'package:flutter/material.dart';
import '../core/accent_theme.dart';
import '../core/channel_categories.dart';
import '../core/seasonal_theme.dart';
import '../models/channel.dart';
import '../models/playlist.dart';
import '../services/m3u_service.dart';
import '../services/storage_service.dart';
import '../services/vpn_service.dart';
import '../services/wallpaper_service.dart';
import '../wiwy/wiwy_portal.dart';
import '../wiwy/wiwy_source.dart';
import '../wiwy/wiwy_vod.dart';

enum ChannelFilterType {
  category, // Por Categoría (Deportes, Cine, Noticias, Infantil...)
  country,  // Por País (Colombia, México, Argentina, España...)
  language, // Por Idioma (Español, Inglés, Portugués...)
}

enum ChannelSortMode {
  original,
  nameAsc,
  nameDesc,
  country,
}

class AppState extends ChangeNotifier {
  final StorageService storage;
  final M3uService m3uService;
  final VpnService vpnService;
  final WallpaperService wallpaperService;
  final WiwyPortal wiwyPortal;
  final WiwySource wiwySource;

  int _currentTabIndex = 0;
  List<Channel> _channels = [];
  List<WiwyVodAsset> _vodAssets = [];
  List<Playlist> _savedPlaylists = [];
  bool _isLoadingVod = false;
  String _selectedCategory = ChannelCategories.all;
  ChannelFilterType _filterType = ChannelFilterType.category;
  String _selectedCountry = 'Todos';
  String _selectedLanguage = 'Todos';
  ChannelSortMode _sortMode = ChannelSortMode.original;
  String _searchQuery = '';
  Channel? _currentChannel;
  bool _isLoading = false;
  String? _errorMessage;
  late AccentOption _accent;
  bool _useWiwy = false;

  AppState({
    required this.storage,
    required this.m3uService,
    required this.vpnService,
    required this.wallpaperService,
    required this.wiwyPortal,
    required this.wiwySource,
  }) {
    // Cargar listas de reproducción guardadas
    _savedPlaylists = storage.getSavedPlaylists();

    // Inicializar de inmediato con canales curados para disponibilidad instantánea
    _channels = M3uService.defaultCuratedChannels;
    if (_channels.isNotEmpty) {
      _currentChannel = _channels.first;
    }

    // Inicializar catálogo VOD desde caché o catálogo por defecto
    final cachedVod = storage.getCachedVodAssets();
    _vodAssets = cachedVod.isNotEmpty ? cachedVod : WiwyVodService.defaultCatalog;
    loadVodCatalog();

    _accent = AccentTheme.fromName(storage.getAccentName());
    _useWiwy = storage.getUseWiwy();

    vpnService.onStatusChanged = (status) {
      notifyListeners();
    };
  }

  // --- Getters ---
  int get currentTabIndex => _currentTabIndex;
  List<Channel> get channels => _channels;
  List<WiwyVodAsset> get vodAssets => _vodAssets;
  List<Playlist> get savedPlaylists => _savedPlaylists;
  List<Playlist> get tvPlaylists => _savedPlaylists.where((p) => p.type == PlaylistType.tv).toList();
  List<Playlist> get vodPlaylists => _savedPlaylists.where((p) => p.type == PlaylistType.vod).toList();
  Playlist? get activeTvPlaylist {
    for (final p in _savedPlaylists) {
      if (p.type == PlaylistType.tv && p.isActive) return p;
    }
    return null;
  }
  Playlist? get activeVodPlaylist {
    for (final p in _savedPlaylists) {
      if (p.type == PlaylistType.vod && p.isActive) return p;
    }
    return null;
  }
  bool get isLoadingVod => _isLoadingVod;
  String get selectedCategory => _selectedCategory;
  ChannelFilterType get filterType => _filterType;
  String get selectedCountry => _selectedCountry;
  String get selectedLanguage => _selectedLanguage;
  ChannelSortMode get sortMode => _sortMode;
  String get searchQuery => _searchQuery;
  Channel? get currentChannel => _currentChannel;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AccentOption get accent => _accent;
  bool get useWiwy => _useWiwy;
  String get customM3uUrl => storage.getCustomM3uUrl();
  String get customVodUrl => storage.getCustomVodUrl();
  String get devId => storage.getDevId();
  String get userId => storage.getUserId();
  VpnStatus get vpnStatus => vpnService.status;
  SeasonalThemeItem get currentTheme => wallpaperService.currentTheme;

  List<String> get availableCountries {
    final Map<String, int> counts = {};
    for (final c in _channels) {
      counts[c.country] = (counts[c.country] ?? 0) + 1;
    }
    final sorted = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    return ['Todos', ...sorted];
  }

  List<String> get availableLanguages {
    final Map<String, int> counts = {};
    for (final c in _channels) {
      counts[c.language] = (counts[c.language] ?? 0) + 1;
    }
    final sorted = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    return ['Todos', ...sorted];
  }

  List<Channel> get filteredChannels {
    var result = _channels.where((c) {
      final matchesSearch = _searchQuery.isEmpty ||
          c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.country.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.category.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchesSearch) return false;

      switch (_filterType) {
        case ChannelFilterType.category:
          return _selectedCategory == ChannelCategories.all ||
              c.category.toLowerCase() == _selectedCategory.toLowerCase();
        case ChannelFilterType.country:
          return _selectedCountry == 'Todos' || c.country == _selectedCountry;
        case ChannelFilterType.language:
          return _selectedLanguage == 'Todos' || c.language == _selectedLanguage;
      }
    }).toList();

    switch (_sortMode) {
      case ChannelSortMode.nameAsc:
        result.sort((a, b) => a.name.compareTo(b.name));
        break;
      case ChannelSortMode.nameDesc:
        result.sort((a, b) => b.name.compareTo(a.name));
        break;
      case ChannelSortMode.country:
        result.sort((a, b) => a.country.compareTo(b.country));
        break;
      case ChannelSortMode.original:
        break;
    }

    return result;
  }

  List<Channel> get favoriteChannels {
    final favIds = storage.getFavoriteIds();
    return _channels.where((c) => favIds.contains(c.id)).toList();
  }

  // --- Acciones de Estado ---
  void setTabIndex(int index) {
    if (_currentTabIndex != index) {
      _currentTabIndex = index;
      notifyListeners();
    }
  }

  void setFilterType(ChannelFilterType type) {
    _filterType = type;
    notifyListeners();
  }

  void selectCountry(String country) {
    _selectedCountry = country;
    notifyListeners();
  }

  void selectLanguage(String language) {
    _selectedLanguage = language;
    notifyListeners();
  }

  void setSortMode(ChannelSortMode mode) {
    _sortMode = mode;
    notifyListeners();
  }

  void selectCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCurrentChannel(Channel? channel) {
    _currentChannel = channel;
    notifyListeners();
  }

  Future<void> toggleFavorite(Channel channel) async {
    await storage.toggleFavorite(channel.id);
    // Actualizar estado local
    final favIds = storage.getFavoriteIds();
    _channels = _channels.map((c) {
      if (c.id == channel.id) {
        return c.copyWith(isFavorite: favIds.contains(c.id));
      }
      return c;
    }).toList();
    notifyListeners();
  }

  Future<void> clearAllFavorites() async {
    await storage.clearFavorites();
    _channels = _channels.map((c) => c.copyWith(isFavorite: false)).toList();
    notifyListeners();
  }

  Future<void> setWallpaper(SeasonalThemeItem theme) async {
    await wallpaperService.setTheme(theme);
    notifyListeners();
  }

  Future<void> setAccent(AccentOption opt) async {
    _accent = opt;
    await storage.setAccentName(opt.name);
    notifyListeners();
  }

  Future<void> setUseWiwy(bool value) async {
    _useWiwy = value;
    await storage.setUseWiwy(value);
    await loadChannels(forceRefresh: true);
  }

  /// Configura una lista de reproducción IPTV M3U/M3U8 personalizada
  Future<int> setCustomM3uPlaylist(String url, {String? playlistName}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final trimmed = url.trim();
      if (trimmed.isEmpty) {
        await storage.clearCustomM3uUrl();
        await storage.setActivePlaylist('', PlaylistType.tv);
        _savedPlaylists = storage.getSavedPlaylists();
        await loadChannels(forceRefresh: true);
        return _channels.length;
      }

      final channels = await m3uService.fetchChannelsFromUrl(trimmed);
      await storage.setCustomM3uUrl(trimmed);

      // Sincronizar con gestor de listas guardadas
      final existingIndex = _savedPlaylists.indexWhere((p) => p.type == PlaylistType.tv && p.url == trimmed);
      if (existingIndex != -1) {
        final currentPl = _savedPlaylists[existingIndex];
        await storage.addOrUpdatePlaylist(currentPl.copyWith(isActive: true, itemCount: channels.length));
      } else {
        final newPl = Playlist(
          id: 'pl_${DateTime.now().millisecondsSinceEpoch}',
          name: playlistName ?? 'Lista IPTV Personalizada',
          url: trimmed,
          type: PlaylistType.tv,
          itemCount: channels.length,
          isActive: true,
          createdAt: DateTime.now(),
        );
        await storage.addOrUpdatePlaylist(newPl);
      }
      _savedPlaylists = storage.getSavedPlaylists();

      _channels = channels;
      _currentChannel = _channels.isNotEmpty ? _channels.first : null;
      _selectedCategory = ChannelCategories.all;
      return _channels.length;
    } catch (e) {
      _errorMessage = 'Error al cargar lista IPTV: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Restablece la lista IPTV a la predeterminada (IPTV-Org)
  Future<void> resetCustomM3uPlaylist() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await storage.clearCustomM3uUrl();
      await storage.setActivePlaylist('', PlaylistType.tv);
      _savedPlaylists = storage.getSavedPlaylists();
      await loadChannels(forceRefresh: true);
    } catch (e) {
      _errorMessage = 'Error al restablecer la lista: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carga el catálogo VOD (películas y series)
  Future<void> loadVodCatalog({bool forceRefresh = false}) async {
    _isLoadingVod = true;
    notifyListeners();
    try {
      final vodService = WiwyVodService(wiwyPortal, storage);
      final list = await vodService.getFeaturedCatalog(forceRefresh: forceRefresh);
      if (list.isNotEmpty) {
        _vodAssets = list;
      }
    } catch (_) {
      if (_vodAssets.isEmpty) {
        _vodAssets = WiwyVodService.defaultCatalog;
      }
    } finally {
      _isLoadingVod = false;
      notifyListeners();
    }
  }

  /// Configura una lista VOD (Películas y Series) personalizada
  Future<int> setCustomVodPlaylist(String url, {String? playlistName}) async {
    _isLoadingVod = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final trimmed = url.trim();
      if (trimmed.isEmpty) {
        await storage.clearCustomVodUrl();
        await storage.setActivePlaylist('', PlaylistType.vod);
        _savedPlaylists = storage.getSavedPlaylists();
        await loadVodCatalog(forceRefresh: true);
        return _vodAssets.length;
      }

      final vodService = WiwyVodService(wiwyPortal, storage);
      final results = await vodService.fetchVodFromUrl(trimmed);
      await storage.setCustomVodUrl(trimmed);

      // Sincronizar con gestor de listas guardadas
      final existingIndex = _savedPlaylists.indexWhere((p) => p.type == PlaylistType.vod && p.url == trimmed);
      if (existingIndex != -1) {
        final currentPl = _savedPlaylists[existingIndex];
        await storage.addOrUpdatePlaylist(currentPl.copyWith(isActive: true, itemCount: results.length));
      } else {
        final newPl = Playlist(
          id: 'pl_${DateTime.now().millisecondsSinceEpoch}',
          name: playlistName ?? 'Catálogo VOD Personalizado',
          url: trimmed,
          type: PlaylistType.vod,
          itemCount: results.length,
          isActive: true,
          createdAt: DateTime.now(),
        );
        await storage.addOrUpdatePlaylist(newPl);
      }
      _savedPlaylists = storage.getSavedPlaylists();

      _vodAssets = results;
      return results.length;
    } catch (e) {
      _errorMessage = 'Error al cargar lista VOD: $e';
      rethrow;
    } finally {
      _isLoadingVod = false;
      notifyListeners();
    }
  }

  /// Restablece el catálogo VOD al catálogo predeterminado
  Future<void> resetCustomVodPlaylist() async {
    _isLoadingVod = true;
    notifyListeners();
    try {
      await storage.clearCustomVodUrl();
      await storage.setActivePlaylist('', PlaylistType.vod);
      _savedPlaylists = storage.getSavedPlaylists();
      await loadVodCatalog(forceRefresh: true);
    } finally {
      _isLoadingVod = false;
      notifyListeners();
    }
  }

  // --- Operaciones del Gestor de Múltiples Listas ---

  /// Añade una nueva lista guardada y la valida
  Future<int> addPlaylist({
    required String name,
    required String url,
    required PlaylistType type,
    bool activate = true,
  }) async {
    final trimmed = url.trim();
    if (type == PlaylistType.tv) {
      if (activate) {
        return await setCustomM3uPlaylist(trimmed, playlistName: name);
      } else {
        final channels = await m3uService.fetchChannelsFromUrl(trimmed);
        final newPl = Playlist(
          id: 'pl_${DateTime.now().millisecondsSinceEpoch}',
          name: name.trim().isEmpty ? 'Lista IPTV' : name.trim(),
          url: trimmed,
          type: PlaylistType.tv,
          itemCount: channels.length,
          isActive: false,
          createdAt: DateTime.now(),
        );
        await storage.addOrUpdatePlaylist(newPl);
        _savedPlaylists = storage.getSavedPlaylists();
        notifyListeners();
        return channels.length;
      }
    } else {
      if (activate) {
        return await setCustomVodPlaylist(trimmed, playlistName: name);
      } else {
        final vodService = WiwyVodService(wiwyPortal, storage);
        final results = await vodService.fetchVodFromUrl(trimmed);
        final newPl = Playlist(
          id: 'pl_${DateTime.now().millisecondsSinceEpoch}',
          name: name.trim().isEmpty ? 'Catálogo VOD' : name.trim(),
          url: trimmed,
          type: PlaylistType.vod,
          itemCount: results.length,
          isActive: false,
          createdAt: DateTime.now(),
        );
        await storage.addOrUpdatePlaylist(newPl);
        _savedPlaylists = storage.getSavedPlaylists();
        notifyListeners();
        return results.length;
      }
    }
  }

  /// Activa una lista existente
  Future<void> activatePlaylist(String id) async {
    final pl = _savedPlaylists.where((p) => p.id == id).firstOrNull;
    if (pl == null) return;

    if (pl.type == PlaylistType.tv) {
      await setCustomM3uPlaylist(pl.url, playlistName: pl.name);
    } else {
      await setCustomVodPlaylist(pl.url, playlistName: pl.name);
    }
  }

  /// Elimina una lista guardada
  Future<void> deletePlaylist(String id) async {
    final pl = _savedPlaylists.where((p) => p.id == id).firstOrNull;
    if (pl == null) return;

    final wasActive = pl.isActive;
    final type = pl.type;

    await storage.removePlaylist(id);
    _savedPlaylists = storage.getSavedPlaylists();

    if (wasActive) {
      final remaining = _savedPlaylists.where((p) => p.type == type).toList();
      if (remaining.isNotEmpty) {
        await activatePlaylist(remaining.first.id);
      } else {
        if (type == PlaylistType.tv) {
          await resetCustomM3uPlaylist();
        } else {
          await resetCustomVodPlaylist();
        }
      }
    } else {
      notifyListeners();
    }
  }

  /// Actualiza y refresca el contenido de una lista
  Future<int> refreshPlaylist(String id) async {
    final pl = _savedPlaylists.where((p) => p.id == id).firstOrNull;
    if (pl == null) return 0;

    int newCount = 0;
    if (pl.type == PlaylistType.tv) {
      if (pl.isActive) {
        newCount = await setCustomM3uPlaylist(pl.url, playlistName: pl.name);
      } else {
        final channels = await m3uService.fetchChannelsFromUrl(pl.url);
        newCount = channels.length;
        await storage.addOrUpdatePlaylist(pl.copyWith(itemCount: newCount));
        _savedPlaylists = storage.getSavedPlaylists();
        notifyListeners();
      }
    } else {
      if (pl.isActive) {
        newCount = await setCustomVodPlaylist(pl.url, playlistName: pl.name);
      } else {
        final vodService = WiwyVodService(wiwyPortal, storage);
        final results = await vodService.fetchVodFromUrl(pl.url);
        newCount = results.length;
        await storage.addOrUpdatePlaylist(pl.copyWith(itemCount: newCount));
        _savedPlaylists = storage.getSavedPlaylists();
        notifyListeners();
      }
    }
    return newCount;
  }

  Future<void> updateDeviceIdentity({required String devId, required String userId}) async {
    await storage.setDevId(devId);
    await storage.setUserId(userId);
    wiwyPortal.resetSession();
    notifyListeners();
  }

  Future<void> resetDeviceIdentity() async {
    await storage.resetIdentity();
    wiwyPortal.resetSession();
    notifyListeners();
  }

  Future<Map<String, dynamic>> testHandshake({String? devId, String? userId, String? host}) async {
    return await wiwyPortal.testHandshake(customDevId: devId, customUserId: userId, host: host);
  }

  Future<Map<String, Map<String, dynamic>>> testClusterHandshake({String? devId, String? userId}) async {
    return await wiwyPortal.testClusterHandshake(customDevId: devId, customUserId: userId);
  }

  Future<void> toggleVpn({VpnProfile? profile}) async {
    if (vpnService.isConnected) {
      await vpnService.disconnect();
    } else {
      await vpnService.connect(profile: profile);
    }
  }

  void setVpnProfile(VpnProfile profile) {
    vpnService.setSelectedProfile(profile);
    notifyListeners();
  }

  Future<void> loadChannels({bool forceRefresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_useWiwy) {
        final wiwyChannels = await wiwySource.getChannels();
        if (wiwyChannels.isNotEmpty) {
          _channels = wiwyChannels;
        } else {
          // Fallback a IPTV-Org si Wiwy está bloqueado o caído
          _channels = await m3uService.fetchChannels(forceRefresh: forceRefresh);
        }
      } else {
        _channels = await m3uService.fetchChannels(forceRefresh: forceRefresh);
      }

      // Si no hay canal activo, asignar el primero
      if (_channels.isNotEmpty && _currentChannel == null) {
        _currentChannel = _channels.first;
      }
    } catch (e) {
      _errorMessage = 'No se pudieron cargar los canales: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
