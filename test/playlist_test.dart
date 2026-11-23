import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexusstream/core/network_defaults.dart';
import 'package:nexusstream/models/playlist.dart';
import 'package:nexusstream/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Playlist Model & Storage Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('NetworkDefaults curated presets contain TV and VOD lists', () {
      const presets = NetworkDefaults.curatedPresets;
      expect(presets, isNotEmpty);

      final vodPresets = presets.where((p) => p.isVod).toList();
      final tvPresets = presets.where((p) => !p.isVod).toList();

      expect(vodPresets, isNotEmpty);
      expect(tvPresets, isNotEmpty);

      // Verify user's shared links are present
      expect(vodPresets.any((p) => p.url == 'http://bit.ly/FilmesdeTerror1'), isTrue);
      expect(vodPresets.any((p) => p.url == 'http://bit.ly/CR-FILMES'), isTrue);
      expect(tvPresets.any((p) => p.url == 'http://bit.ly/2D8ZHyz'), isTrue);
    });

    test('Playlist JSON serialization and deserialization', () {
      final now = DateTime.now();
      final pl = Playlist(
        id: 'test_1',
        name: 'Terror Movies',
        url: 'http://bit.ly/FilmesdeTerror1',
        type: PlaylistType.vod,
        itemCount: 396,
        isActive: true,
        createdAt: now,
      );

      final json = pl.toJson();
      final decoded = Playlist.fromJson(json);

      expect(decoded.id, equals('test_1'));
      expect(decoded.name, equals('Terror Movies'));
      expect(decoded.url, equals('http://bit.ly/FilmesdeTerror1'));
      expect(decoded.type, equals(PlaylistType.vod));
      expect(decoded.itemCount, equals(396));
      expect(decoded.isActive, isTrue);
    });

    test('StorageService handles multiple playlists and active switching', () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = StorageService(prefs);

      expect(storage.getSavedPlaylists(), isEmpty);

      final pl1 = Playlist(
        id: 'tv_1',
        name: 'Live Canales 1',
        url: 'http://example.com/tv1.m3u',
        type: PlaylistType.tv,
        itemCount: 150,
        isActive: true,
        createdAt: DateTime.now(),
      );

      final pl2 = Playlist(
        id: 'tv_2',
        name: 'Live Canales 2',
        url: 'http://example.com/tv2.m3u',
        type: PlaylistType.tv,
        itemCount: 2000,
        isActive: false,
        createdAt: DateTime.now(),
      );

      final plVod = Playlist(
        id: 'vod_1',
        name: 'VOD Terror',
        url: 'http://bit.ly/FilmesdeTerror1',
        type: PlaylistType.vod,
        itemCount: 396,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await storage.addOrUpdatePlaylist(pl1);
      await storage.addOrUpdatePlaylist(pl2);
      await storage.addOrUpdatePlaylist(plVod);

      var playlists = storage.getSavedPlaylists();
      expect(playlists.length, equals(3));
      expect(storage.getCustomM3uUrl(), equals('http://example.com/tv1.m3u'));
      expect(storage.getCustomVodUrl(), equals('http://bit.ly/FilmesdeTerror1'));

      // Activar la segunda lista de TV
      await storage.setActivePlaylist('tv_2', PlaylistType.tv);

      playlists = storage.getSavedPlaylists();
      final activeTv = playlists.firstWhere((p) => p.type == PlaylistType.tv && p.isActive);
      expect(activeTv.id, equals('tv_2'));
      expect(storage.getCustomM3uUrl(), equals('http://example.com/tv2.m3u'));

      // pl1 debe estar ahora inactiva
      final oldTv = playlists.firstWhere((p) => p.id == 'tv_1');
      expect(oldTv.isActive, isFalse);

      // VOD debe seguir activa sin verse afectada
      final activeVod = playlists.firstWhere((p) => p.type == PlaylistType.vod && p.isActive);
      expect(activeVod.id, equals('vod_1'));

      // Eliminar lista
      await storage.removePlaylist('tv_1');
      playlists = storage.getSavedPlaylists();
      expect(playlists.length, equals(2));
      expect(playlists.any((p) => p.id == 'tv_1'), isFalse);
    });
  });
}
