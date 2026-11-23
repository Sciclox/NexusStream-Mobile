import 'package:flutter/material.dart';
import '../core/seasonal_theme.dart';
import 'storage_service.dart';

class WallpaperService {
  final StorageService _storage;
  SeasonalThemeItem _currentTheme = SeasonalTheme.none;

  WallpaperService(this._storage) {
    final savedId = _storage.getWallpaperId();
    _currentTheme = SeasonalTheme.fromId(savedId);
  }

  SeasonalThemeItem get currentTheme => _currentTheme;

  Future<void> setTheme(SeasonalThemeItem theme) async {
    _currentTheme = theme;
    await _storage.setWallpaperId(theme.id);
  }

  String? getAssetForOrientation(Orientation orientation) {
    if (_currentTheme.id == 'none') return null;
    if (orientation == Orientation.portrait) {
      return _currentTheme.portraitAsset ?? _currentTheme.landscapeAsset;
    }
    return _currentTheme.landscapeAsset;
  }
}
