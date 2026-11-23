import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexusstream/core/channel_metadata_helper.dart';
import 'package:nexusstream/services/m3u_parser.dart';
import 'package:nexusstream/services/m3u_service.dart';
import 'package:nexusstream/services/storage_service.dart';

void main() {
  test('Test fetchChannels', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();
    final m3uService = M3uService(storage);
    final channels = await m3uService.fetchChannels(forceRefresh: true);
    // ignore: avoid_print
    print('Fetched channels count: ${channels.length}');
    for (int i = 0; i < 15 && i < channels.length; i++) {
      final c = channels[i];
      // ignore: avoid_print
      print('Channel $i: ${c.name} | Logo: ${c.logo}');
    }
  });

  test('Test automatic official logo resolution for channels without tvg-logo', () {
    const rawM3u = '''#EXTM3U
#EXTINF:-1,CARACOL HD 2
http://stream.test/caracol2.m3u8
#EXTINF:-1,Cartoon Network HD
http://stream.test/cn.m3u8
#EXTINF:-1,ESPN 2 HD
http://stream.test/espn2.m3u8
#EXTINF:-1,Cinecanal HD
http://stream.test/cinecanal.m3u8
#EXTINF:-1,AMC HD
http://stream.test/amc.m3u8
#EXTINF:-1,AXN HD
http://stream.test/axn.m3u8
#EXTINF:-1,Win Sports
http://stream.test/winsports.m3u8
''';

    final channels = M3uParser.parse(rawM3u, source: 'custom_list');
    expect(channels.length, 7);

    // Caracol HD 2 must have its official logo
    expect(channels[0].logo, 'https://i.imgur.com/Fww94l9.png');

    // Cartoon Network must have its official logo
    expect(channels[1].logo, contains('Cartoon_Network'));

    // ESPN 2 must have its official logo
    expect(channels[2].logo, contains('ESPN'));

    // Cinecanal must have its official logo
    expect(channels[3].logo, contains('Cinecanal'));

    // AMC must have its official logo
    expect(channels[4].logo, contains('AMC'));

    // AXN must have its official logo
    expect(channels[5].logo, contains('AXN'));

    // Win Sports must have its official logo
    expect(channels[6].logo, 'https://i.imgur.com/DuSSrHV.png');
  });

  test('Direct ChannelMetadataHelper.resolveOfficialLogo checks', () {
    expect(ChannelMetadataHelper.resolveOfficialLogo('AE HD'), contains('A%26E'));
    expect(ChannelMetadataHelper.resolveOfficialLogo('Discovery Channel HD'), contains('Discovery'));
    expect(ChannelMetadataHelper.resolveOfficialLogo('Discovery Kids HD'), contains('Discovery_Kids'));
    expect(ChannelMetadataHelper.resolveOfficialLogo('America TV HD'), contains('Am%C3%A9rica_TV'));
    expect(ChannelMetadataHelper.resolveOfficialLogo('Canal RCN'), 'https://i.imgur.com/5PhTaHp.png');
  });
}
