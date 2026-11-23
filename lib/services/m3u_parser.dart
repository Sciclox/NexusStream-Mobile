import '../core/channel_categories.dart';
import '../core/channel_metadata_helper.dart';
import '../models/channel.dart';
import '../wiwy/wiwy_vod.dart';

class M3uParser {
  /// Parsea el contenido en texto plano de un archivo M3U / M3U8 de canales de TV
  static List<Channel> parse(String content, {String source = 'iptv_org'}) {
    final List<Channel> channels = [];
    final lines = content.split('\n');

    String? currentName;
    String? currentLogo;
    String? currentGroup;
    String? currentTvgId;
    String? currentTvgCountry;
    String? currentTvgLanguage;

    final regexTvgId = RegExp(r'''tvg-id\s*=\s*["']?([^"'\s,]+)["']?''', caseSensitive: false);
    final regexTvgName = RegExp(r'''tvg-name\s*=\s*["']?([^"'\n,]+)["']?''', caseSensitive: false);
    final regexTvgLogo = RegExp(r'''(?:tvg-logo|pltv-logo|logo)\s*=\s*["']?([^"'\s,]+)["']?''', caseSensitive: false);
    final regexGroupTitle = RegExp(r'''group-title\s*=\s*["']?([^"'\n,]+)["']?''', caseSensitive: false);
    final regexTvgCountry = RegExp(r'''tvg-country\s*=\s*["']?([^"'\s,]+)["']?''', caseSensitive: false);
    final regexTvgLanguage = RegExp(r'''tvg-language\s*=\s*["']?([^"'\s,]+)["']?''', caseSensitive: false);

    for (var rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      if (line.startsWith('#EXTINF:')) {
        // Extraer atributos
        final idMatch = regexTvgId.firstMatch(line);
        currentTvgId = idMatch?.group(1);

        final nameMatch = regexTvgName.firstMatch(line);
        final logoMatch = regexTvgLogo.firstMatch(line);
        currentLogo = logoMatch?.group(1);

        final groupMatch = regexGroupTitle.firstMatch(line);
        currentGroup = groupMatch?.group(1);

        final countryMatch = regexTvgCountry.firstMatch(line);
        currentTvgCountry = countryMatch?.group(1);

        final langMatch = regexTvgLanguage.firstMatch(line);
        currentTvgLanguage = langMatch?.group(1);

        // Extraer nombre del canal después de la última coma
        final commaIndex = line.lastIndexOf(',');
        if (commaIndex != -1 && commaIndex + 1 < line.length) {
          currentName = line.substring(commaIndex + 1).trim();
        } else {
          currentName = nameMatch?.group(1) ?? 'Canal sin nombre';
        }

        // Limpiar etiquetas de formato comunes como [COLOR yellow]...[/COLOR] o [B]...[/B]
        currentName = currentName
            .replaceAll(RegExp(r'\[/?COLOR.*?\]', caseSensitive: false), '')
            .replaceAll(RegExp(r'\[/?B\]', caseSensitive: false), '')
            .replaceAll(RegExp(r'\[/?I\]', caseSensitive: false), '')
            .trim();
      } else if (!line.startsWith('#')) {
        // Es la URL de streaming
        if (line.startsWith('http://') || line.startsWith('https://')) {
          final streamUrl = line;
          final name = currentName ?? 'Canal ${channels.length + 1}';
          final category = ChannelCategories.normalize(currentGroup);
          final id = currentTvgId != null && currentTvgId.isNotEmpty
              ? '${source}_$currentTvgId'
              : '${source}_${channels.length}_${name.hashCode}';

          final countryInfo = ChannelMetadataHelper.detectCountryAndLanguage(
            name: name,
            group: currentGroup,
            tvgCountry: currentTvgCountry,
            tvgLanguage: currentTvgLanguage,
          );

          // Si la lista M3U no trae tvg-logo (ej. listas privadas de TV cable), resolvemos el logo oficial de transmisión
          final effectiveLogo = (currentLogo != null && currentLogo.trim().isNotEmpty)
              ? currentLogo.trim()
              : ChannelMetadataHelper.resolveOfficialLogo(name);

          channels.add(
            Channel(
              id: id,
              name: name,
              streamUrl: streamUrl,
              logo: effectiveLogo,
              category: category,
              group: currentGroup,
              tvgId: currentTvgId,
              source: source,
              country: countryInfo.name,
              countryCode: countryInfo.code,
              flag: countryInfo.flag,
              language: countryInfo.language,
            ),
          );
        }

        // Reset temporal variables
        currentName = null;
        currentLogo = null;
        currentGroup = null;
        currentTvgId = null;
        currentTvgCountry = null;
        currentTvgLanguage = null;
      }
    }

    return channels;
  }

  /// Parsea una lista M3U de contenido VOD (Películas y Series)
  static List<WiwyVodAsset> parseVod(String content, {String source = 'custom_vod'}) {
    final List<WiwyVodAsset> assets = [];
    final lines = content.split('\n');

    String? currentTitle;
    String? currentLogo;
    String? currentGroup;
    String activeGroup = 'Películas';

    final regexTvgName = RegExp(r'tvg-name\s*=\s*"([^"]*)"', caseSensitive: false);
    final regexTvgLogo = RegExp(r'(?:tvg-logo|pltv-logo)\s*=\s*"([^"]*)"', caseSensitive: false);
    final regexGroupTitle = RegExp(r'group-title\s*=\s*"([^"]*)"', caseSensitive: false);

    for (var rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      if (line.startsWith('#EXTINF:') || line.startsWith('#PLAYLISTV:')) {
        final logoMatch = regexTvgLogo.firstMatch(line);
        if (logoMatch != null && logoMatch.group(1)!.trim().isNotEmpty) {
          currentLogo = logoMatch.group(1)!.trim();
        }

        final groupMatch = regexGroupTitle.firstMatch(line);
        if (groupMatch != null && groupMatch.group(1)!.trim().isNotEmpty) {
          final g = groupMatch.group(1)!.trim();
          if (g != '-') {
            currentGroup = g;
            activeGroup = g;
          }
        }

        final nameMatch = regexTvgName.firstMatch(line);
        final commaIndex = line.lastIndexOf(',');
        if (commaIndex != -1 && commaIndex + 1 < line.length) {
          final candidate = line.substring(commaIndex + 1).trim();
          if (candidate.isNotEmpty) {
            currentTitle = candidate;
          }
        } else if (nameMatch != null) {
          currentTitle = nameMatch.group(1)?.trim();
        }

        if (currentTitle != null) {
          currentTitle = currentTitle
              .replaceAll(RegExp(r'\[/?COLOR.*?\]', caseSensitive: false), '')
              .replaceAll(RegExp(r'\[/?B\]', caseSensitive: false), '')
              .replaceAll(RegExp(r'\[/?I\]', caseSensitive: false), '')
              .trim();
        }
      } else if (!line.startsWith('#')) {
        if (line.startsWith('http://') || line.startsWith('https://')) {
          final streamUrl = line;
          final title = currentTitle ?? 'Título ${assets.length + 1}';
          final group = currentGroup ?? activeGroup;

          final lower = '$title $group'.toLowerCase();
          final isSeries = lower.contains('serie') ||
              lower.contains('temporada') ||
              lower.contains('season') ||
              lower.contains('episodio') ||
              lower.contains('ep.') ||
              RegExp(r's\d+e\d+', caseSensitive: false).hasMatch(lower);

          assets.add(
            WiwyVodAsset(
              id: '${source}_${assets.length}_${title.hashCode}',
              title: title,
              poster: currentLogo ?? '',
              kind: isSeries ? WiwyVodKind.series : WiwyVodKind.movie,
              category: group,
              streamUrl: streamUrl,
              rating: '8.5',
              year: '2024',
              description: 'VOD: $title',
            ),
          );

          currentTitle = null;
          currentLogo = null;
          currentGroup = null;
        }
      }
    }

    return assets;
  }
}
