import 'package:flutter/foundation.dart';
import '../core/channel_categories.dart';
import '../models/channel.dart';
import 'wiwy_portal.dart';

class WiwySource {
  final WiwyPortal _portal;

  WiwySource(this._portal);

  Future<List<Channel>> getChannels() async {
    try {
      final rawList = await _portal.getLiveData();
      final List<Channel> result = [];

      for (var item in rawList) {
        final id = item['id']?.toString() ?? UniqueKey().toString();
        final name = item['title']?.toString() ?? item['name']?.toString() ?? 'Canal Wiwy';
        final streamUrl = item['play_url']?.toString() ?? item['url']?.toString() ?? '';
        final logo = item['icon']?.toString() ?? item['logo']?.toString();
        final rawCat = item['category']?.toString() ?? item['group']?.toString();
        final category = ChannelCategories.normalize(rawCat);

        if (streamUrl.isNotEmpty) {
          result.add(
            Channel(
              id: 'wiwy_$id',
              name: name,
              streamUrl: streamUrl,
              logo: logo,
              category: category,
              group: rawCat,
              tvgId: id,
              source: 'wiwy',
            ),
          );
        }
      }

      return result;
    } catch (e) {
      return [];
    }
  }
}
