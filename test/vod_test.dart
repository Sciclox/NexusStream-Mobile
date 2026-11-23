import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexusstream/services/m3u_parser.dart';
import 'package:nexusstream/services/storage_service.dart';
import 'package:nexusstream/wiwy/wiwy_portal.dart';
import 'package:nexusstream/wiwy/wiwy_vod.dart';

void main() {
  test('Test StorageService VOD persistence', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();

    expect(storage.getCustomVodUrl(), '');

    await storage.setCustomVodUrl('http://bit.ly/FilmesdeTerror1');
    expect(storage.getCustomVodUrl(), 'http://bit.ly/FilmesdeTerror1');

    await storage.clearCustomVodUrl();
    expect(storage.getCustomVodUrl(), '');
  });

  test('Test M3uParser.parseVod parses movie & series entries correctly', () {
    const rawVod = '''#EXTM3U
#PLAYLISTV: pltv-logo="http://example.com/logo.png" group-title="FILMES DE TERROR" , FILMES DE TERROR
#EXTINF:-1 tvg-logo="https://img.com/candyman.jpg" , O MISTÉRIO DE CANDYMAN
http://cdn.example.com/movies/candyman.mp4
#EXTINF:-1 tvg-logo="https://img.com/serie.jpg" group-title="SERIES" , Stranger Things Temporada 1
http://cdn.example.com/series/st_s01e01.mp4
''';

    final assets = M3uParser.parseVod(rawVod);
    expect(assets.length, 2);

    expect(assets[0].title, 'O MISTÉRIO DE CANDYMAN');
    expect(assets[0].streamUrl, 'http://cdn.example.com/movies/candyman.mp4');
    expect(assets[0].poster, 'https://img.com/candyman.jpg');
    expect(assets[0].category, 'FILMES DE TERROR');
    expect(assets[0].kind, WiwyVodKind.movie);

    expect(assets[1].title, 'Stranger Things Temporada 1');
    expect(assets[1].category, 'SERIES');
    expect(assets[1].kind, WiwyVodKind.series);
  });

  test('Test fetching and parsing user bit.ly VOD link', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();
    final portal = WiwyPortal();
    final vodService = WiwyVodService(portal, storage);

    final results = await vodService.fetchVodFromUrl('http://bit.ly/FilmesdeTerror1');
    expect(results.isNotEmpty, isTrue);
    // ignore: avoid_print
    print('Total VOD titles parsed from bit.ly/FilmesdeTerror1: ${results.length}');
    // ignore: avoid_print
    print('First VOD title: ${results.first.title} -> ${results.first.streamUrl}');
  });
}
