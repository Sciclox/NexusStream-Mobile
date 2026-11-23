import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexusstream/services/storage_service.dart';
import 'package:nexusstream/services/m3u_parser.dart';

void main() {
  test('Test StorageService custom M3U URL persistence', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();

    expect(storage.getCustomM3uUrl(), '');

    await storage.setCustomM3uUrl('https://example.com/mi-lista.m3u');
    expect(storage.getCustomM3uUrl(), 'https://example.com/mi-lista.m3u');

    await storage.clearCustomM3uUrl();
    expect(storage.getCustomM3uUrl(), '');
  });

  test('Test M3uParser parses custom playlist lines correctly', () {
    const rawM3u = '''#EXTM3U
#EXTINF:-1 tvg-id="espn1" tvg-name="ESPN HD" tvg-logo="https://logo.com/espn.png" group-title="Deportes",ESPN Latino HD
http://stream.example.com/espn/live.m3u8
#EXTINF:-1 tvg-id="hbo" tvg-name="HBO Plus" tvg-logo="https://logo.com/hbo.png" group-title="Cine & Series",HBO Plus
http://stream.example.com/hbo/live.m3u8
''';

    final channels = M3uParser.parse(rawM3u, source: 'custom_m3u');
    expect(channels.length, 2);
    expect(channels[0].name, 'ESPN Latino HD');
    expect(channels[0].streamUrl, 'http://stream.example.com/espn/live.m3u8');
    expect(channels[0].category, 'Deportes');
    expect(channels[1].name, 'HBO Plus');
    expect(channels[1].category, 'Cine');
  });
}
