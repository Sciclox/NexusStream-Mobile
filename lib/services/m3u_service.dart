import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/network_defaults.dart';
import '../models/channel.dart';
import 'm3u_parser.dart';
import 'storage_service.dart';

class M3uService {
  final StorageService _storage;
  final http.Client _client;

  static const String _defaultUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36 NexusStream/1.0';

  M3uService(this._storage, {http.Client? client})
      : _client = client ?? http.Client();

  /// Canales seleccionados de alta disponibilidad y abiertos
  static const List<Channel> defaultCuratedChannels = [
    Channel(
      id: 'curated_dw_espanol',
      name: 'DW Español (Alemania)',
      streamUrl: 'https://dwamdstream104.akamaized.net/hls/live/2015530/dwstream104/index.m3u8',
      logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/75/Deutsche_Welle_symbol_2012.svg/320px-Deutsche_Welle_symbol_2012.svg.png',
      category: 'Noticias',
      group: 'Noticias',
      source: 'curated',
    ),
    Channel(
      id: 'curated_nasa_tv',
      name: 'NASA TV HD (Oficial)',
      streamUrl: 'https://ntv1.akamaized.net/hls/live/2014075/NASA-NTV1-HLS/master.m3u8',
      logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e5/NASA_logo.svg/320px-NASA_logo.svg.png',
      category: 'Cultura',
      group: 'Ciencia & Espacio',
      source: 'curated',
    ),
    Channel(
      id: 'curated_redbull_tv',
      name: 'Red Bull TV Deportes',
      streamUrl: 'https://rbmn-live.akamaized.net/hls/live/590964/BoRB-AT/master.m3u8',
      logo: 'https://images.pluto.tv/channels/5cae0d297ffb438db2e5c8e2/colorLogoPNG.png',
      category: 'Deportes',
      group: 'Deportes',
      source: 'curated',
    ),
    Channel(
      id: 'curated_france24_es',
      name: 'France 24 Español',
      streamUrl: 'https://f24hls-i.akamaihd.net/hls/live/221195/F24_ES_LO_HLS/master_500.m3u8',
      logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/France_24_logo.svg/320px-France_24_logo.svg.png',
      category: 'Noticias',
      group: 'Noticias',
      source: 'curated',
    ),
    Channel(
      id: 'curated_telesur',
      name: 'TeleSUR Noticias',
      streamUrl: 'https://telesur.tlsur.net/live/telesur.m3u8',
      logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/ea/TeleSUR_logo.svg/320px-TeleSUR_logo.svg.png',
      category: 'Noticias',
      group: 'Latinoamérica',
      source: 'curated',
    ),
    Channel(
      id: 'curated_rtve_24h',
      name: 'RTVE 24h Noticias',
      streamUrl: 'https://rtvelivestream.akamaized.net/rtvesec/24h/24h_main.m3u8',
      logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/RTVE_24h_logo_2008.svg/320px-RTVE_24h_logo_2008.svg.png',
      category: 'Noticias',
      group: 'Noticias',
      source: 'curated',
    ),
    Channel(
      id: 'curated_big_buck_bunny',
      name: 'Cine Abierto: Big Buck Bunny (4K)',
      streamUrl: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
      logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Big_buck_bunny_poster_big.jpg/320px-Big_buck_bunny_poster_big.jpg',
      category: 'Cine',
      group: 'Cine',
      source: 'curated',
    ),
    Channel(
      id: 'curated_tears_of_steel',
      name: 'Cine Sci-Fi: Tears of Steel',
      streamUrl: 'https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8',
      logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/30/Tears_of_Steel_poster.jpg/320px-Tears_of_Steel_poster.jpg',
      category: 'Cine',
      group: 'Cine',
      source: 'curated',
    ),
  ];

  /// Decodifica de forma segura el cuerpo de la respuesta HTTP, evitando excepciones de formato
  /// cuando los servidores IPTV devuelven encabezados Content-Type malformados (ej: punto y coma sin signo igual).
  static String _safeDecodeResponse(http.Response response) {
    try {
      return utf8.decode(response.bodyBytes, allowMalformed: true);
    } catch (_) {
      try {
        return latin1.decode(response.bodyBytes);
      } catch (_) {
        return response.body;
      }
    }
  }

  /// Obtiene la lista de canales, asegurando que nunca esté vacía.
  /// Si el usuario configuró una lista M3U personalizada, se usa esa; de lo contrario, la lista por defecto.
  Future<List<Channel>> fetchChannels({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = _storage.getCachedChannels();
      if (cached.isNotEmpty) {
        return _applyFavorites(cached);
      }
    }

    final customUrl = _storage.getCustomM3uUrl();
    final hasCustom = customUrl.isNotEmpty;
    final targetUrl = hasCustom ? customUrl : NetworkDefaults.iptvOrgUrl;

    try {
      final response = await _client
          .get(
            Uri.parse(targetUrl),
            headers: const {
              'User-Agent': _defaultUserAgent,
              'Accept': '*/*',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final bodyText = _safeDecodeResponse(response);
        final parsed = M3uParser.parse(
          bodyText,
          source: hasCustom ? 'custom_iptv' : 'iptv_org',
        );
        if (parsed.isNotEmpty) {
          final combined = hasCustom ? parsed : [...defaultCuratedChannels, ...parsed];
          await _storage.saveCachedChannels(combined);
          return _applyFavorites(combined);
        }
      }
    } catch (_) {
      final cached = _storage.getCachedChannels();
      if (cached.isNotEmpty) {
        return _applyFavorites(cached);
      }
    }

    // Fallback garantizado si la red o el M3U tardan o fallan
    return _applyFavorites(defaultCuratedChannels);
  }

  /// Descarga y analiza directamente una lista M3U desde una URL provista
  Future<List<Channel>> fetchChannelsFromUrl(String url) async {
    final uri = Uri.parse(url.trim());
    final response = await _client
        .get(
          uri,
          headers: const {
            'User-Agent': _defaultUserAgent,
            'Accept': '*/*',
          },
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final bodyText = _safeDecodeResponse(response);
      final parsed = M3uParser.parse(bodyText, source: 'custom_iptv');
      if (parsed.isNotEmpty) {
        await _storage.saveCachedChannels(parsed);
        return _applyFavorites(parsed);
      } else {
        throw Exception('El archivo M3U no contiene canales válidos o no tiene formato compatible.');
      }
    } else {
      throw Exception('El servidor respondió con código HTTP ${response.statusCode}');
    }
  }

  List<Channel> _applyFavorites(List<Channel> channels) {
    final favIds = _storage.getFavoriteIds();
    return channels.map((c) {
      return c.copyWith(isFavorite: favIds.contains(c.id));
    }).toList();
  }
}
