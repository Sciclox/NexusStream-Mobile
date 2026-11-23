import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/network_defaults.dart';
import '../services/m3u_parser.dart';
import '../services/storage_service.dart';
import 'wiwy_portal.dart';

enum WiwyVodKind { movie, series }

class WiwyVodAsset {
  final String id;
  final String title;
  final String poster;
  final WiwyVodKind kind;
  final String category;
  final String? rating;
  final String? year;
  final String streamUrl;
  final String description;

  WiwyVodAsset({
    required this.id,
    required this.title,
    required this.poster,
    required this.kind,
    this.category = 'General',
    this.rating,
    this.year,
    required this.streamUrl,
    this.description = '',
  });

  factory WiwyVodAsset.fromJson(Map<String, dynamic> json) {
    return WiwyVodAsset(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? json['name']?.toString() ?? 'Sin título',
      poster: json['poster']?.toString() ?? json['image']?.toString() ?? '',
      kind: json['type'] == 'series' ? WiwyVodKind.series : WiwyVodKind.movie,
      category: json['category']?.toString() ?? json['genre']?.toString() ?? 'General',
      rating: json['rating']?.toString() ?? '8.5',
      year: json['year']?.toString() ?? '2024',
      streamUrl: json['streamUrl']?.toString() ?? json['play_url']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'poster': poster,
    'type': kind == WiwyVodKind.series ? 'series' : 'movie',
    'category': category,
    'rating': rating,
    'year': year,
    'streamUrl': streamUrl,
    'description': description,
  };
}

class WiwyVodService {
  final WiwyPortal _portal;
  final StorageService? _storage;
  final http.Client _client;

  static const String _defaultUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36 NexusStream/1.0';

  WiwyVodService(this._portal, [this._storage, http.Client? client])
      : _client = client ?? http.Client();

  /// Descarga y parsea un catálogo VOD M3U desde una URL provista
  Future<List<WiwyVodAsset>> fetchVodFromUrl(String url) async {
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
      String bodyText;
      try {
        bodyText = utf8.decode(response.bodyBytes, allowMalformed: true);
      } catch (_) {
        bodyText = response.body;
      }
      final parsed = M3uParser.parseVod(bodyText, source: 'custom_vod');
      if (parsed.isNotEmpty) {
        final storage = _storage;
        if (storage != null) {
          await storage.saveCachedVodAssets(parsed);
        }
        return parsed;
      } else {
        throw Exception('El archivo M3U no contiene películas o series válidas.');
      }
    } else {
      throw Exception('El servidor respondió con código HTTP ${response.statusCode}');
    }
  }

  /// Catálogo público ampliado de películas, series y documentales HD
  static final List<WiwyVodAsset> defaultCatalog = [
    WiwyVodAsset(
      id: 'vod_big_buck_bunny',
      title: 'Big Buck Bunny (4K Ultra HD)',
      poster: 'https://upload.wikimedia.org/wikipedia/commons/c/c5/Big_buck_bunny_poster_big.jpg',
      kind: WiwyVodKind.movie,
      category: 'Animación',
      rating: '8.8',
      year: '2024',
      streamUrl: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
      description: 'Cortometraje clásico de animación 3D producido por el Instituto Blender en alta resolución.',
    ),
    WiwyVodAsset(
      id: 'vod_tears_of_steel',
      title: 'Tears of Steel (Sci-Fi VFX)',
      poster: 'https://images.unsplash.com/photo-1508739773434-c26b3d09e071?w=400&auto=format&fit=crop&q=80',
      kind: WiwyVodKind.movie,
      category: 'Ciencia Ficción',
      rating: '8.6',
      year: '2023',
      streamUrl: 'https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8',
      description: 'Futuro distópico en Ámsterdam donde un grupo de científicos y guerreros intentan salvar el mundo de robots gigantes.',
    ),
    WiwyVodAsset(
      id: 'vod_pluto_accion',
      title: 'Pluto Cine Acción HD',
      poster: 'https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=400&auto=format&fit=crop&q=80',
      kind: WiwyVodKind.movie,
      category: 'Acción',
      rating: '8.9',
      year: '2025',
      streamUrl: 'https://service-stitcher.clusters.pluto.tv/stitch/hls/channel/5cae0d297ffb438db2e5c8e2/master.m3u8?advertisingId=&appName=web&appVersion=5.14.0&deviceDNT=0&deviceId=1&deviceMake=Chrome&deviceModel=web&deviceType=web&deviceVersion=1&sid=1',
      description: 'Canal cinematográfico continuo de acción, persecuciones explosivas y peleas cuerpo a cuerpo en español.',
    ),
    WiwyVodAsset(
      id: 'vod_pluto_estelar',
      title: 'Pluto Cine Estelar: Blockbusters',
      poster: 'https://images.unsplash.com/photo-1485846234645-a62644f84728?w=400&auto=format&fit=crop&q=80',
      kind: WiwyVodKind.movie,
      category: 'Drama & Clásicos',
      rating: '9.1',
      year: '2025',
      streamUrl: 'https://service-stitcher.clusters.pluto.tv/stitch/hls/channel/5d83c271500ee3deef9bf14a/master.m3u8?advertisingId=&appName=web&appVersion=5.14.0&deviceDNT=0&deviceId=1&deviceMake=Chrome&deviceModel=web&deviceType=web&deviceVersion=1&sid=1',
      description: 'Selección de películas taquilleras, estrellas de Hollywood y producciones cinematográficas galardonadas.',
    ),
    WiwyVodAsset(
      id: 'vod_sintel',
      title: 'Sintel: La Búsqueda del Dragón',
      poster: 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=400&auto=format&fit=crop&q=80',
      kind: WiwyVodKind.movie,
      category: 'Animación',
      rating: '8.7',
      year: '2023',
      streamUrl: 'https://media.w3.org/2010/05/sintel/trailer.mp4',
      description: 'Una solitaria guerrera recorre páramos helados y desiertos para encontrar a su amigo, un pequeño dragón llamado Scales.',
    ),
    WiwyVodAsset(
      id: 'vod_pluto_scifi',
      title: 'Pluto Sci-Fi Odyssey',
      poster: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=400&auto=format&fit=crop&q=80',
      kind: WiwyVodKind.movie,
      category: 'Ciencia Ficción',
      rating: '8.8',
      year: '2025',
      streamUrl: 'https://service-stitcher.clusters.pluto.tv/stitch/hls/channel/5cae0f224fa9cb8db22591b6/master.m3u8?advertisingId=&appName=web&appVersion=5.14.0&deviceDNT=0&deviceId=1&deviceMake=Chrome&deviceModel=web&deviceType=web&deviceVersion=1&sid=1',
      description: 'Viajes intergalácticos, inteligencia artificial rebelde y futuros alternativos las 24 horas.',
    ),
    WiwyVodAsset(
      id: 'vod_oceans',
      title: 'Oceans: Secretos del Abismo Marino',
      poster: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400&auto=format&fit=crop&q=80',
      kind: WiwyVodKind.movie,
      category: 'Documentales',
      rating: '9.3',
      year: '2024',
      streamUrl: 'https://vjs.zencdn.net/v/oceans.mp4',
      description: 'Exploración submarina de alta fidelidad que recorre los arrecifes y las fosas abisales del planeta.',
    ),
    WiwyVodAsset(
      id: 'vod_nasa_expedition',
      title: 'NASA: Misión Artemis & Espacio',
      poster: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=400&auto=format&fit=crop&q=80',
      kind: WiwyVodKind.series,
      category: 'Documentales',
      rating: '9.5',
      year: '2025',
      streamUrl: 'https://ntv1.akamaized.net/hls/live/2014075/NASA-NTV1-HLS/master.m3u8',
      description: 'Transmisiones oficiales de la NASA sobre el regreso a la Luna, misiones a Marte y el cosmos.',
    ),
    WiwyVodAsset(
      id: 'vod_pluto_terror',
      title: 'Pluto Cine Terror & Pesadillas',
      poster: 'https://images.unsplash.com/photo-1509248961158-e54f6934749c?w=400&auto=format&fit=crop&q=80',
      kind: WiwyVodKind.movie,
      category: 'Terror & Suspenso',
      rating: '8.3',
      year: '2025',
      streamUrl: 'https://service-stitcher.clusters.pluto.tv/stitch/hls/channel/5d83c36c7c64cfdfa069df1d/master.m3u8?advertisingId=&appName=web&appVersion=5.14.0&deviceDNT=0&deviceId=1&deviceMake=Chrome&deviceModel=web&deviceType=web&deviceVersion=1&sid=1',
      description: 'Cine de terror sobrenatural, slasher, monstruos y fenómenos inexplicables.',
    ),
    WiwyVodAsset(
      id: 'vod_pluto_suspenso',
      title: 'Pluto Suspenso & Thrillers',
      poster: 'https://images.unsplash.com/photo-1478760329108-5c3ed9d495a0?w=400&auto=format&fit=crop&q=80',
      kind: WiwyVodKind.movie,
      category: 'Terror & Suspenso',
      rating: '8.6',
      year: '2025',
      streamUrl: 'https://service-stitcher.clusters.pluto.tv/stitch/hls/channel/5d83c3ee49641edf9b47bba1/master.m3u8?advertisingId=&appName=web&appVersion=5.14.0&deviceDNT=0&deviceId=1&deviceMake=Chrome&deviceModel=web&deviceType=web&deviceVersion=1&sid=1',
      description: 'Intriga, giros inesperados y persecuciones mentales con detectives y misterios oscuros.',
    ),
    WiwyVodAsset(
      id: 'vod_red_bull_action',
      title: 'Red Bull Extrema: Sound of Speed',
      poster: 'https://images.unsplash.com/photo-1551698618-1dfe5d97d256?w=400&auto=format&fit=crop&q=80',
      kind: WiwyVodKind.series,
      category: 'Acción',
      rating: '9.2',
      year: '2024',
      streamUrl: 'https://rbmn-live.akamaized.net/hls/live/590964/BoRB-AT/master.m3u8',
      description: 'Hazañas atléticas extremas grabadas a 60 fps con adrenalina pura y sonido cinemático.',
    ),
    WiwyVodAsset(
      id: 'vod_dw_documental',
      title: 'DW Documentales en Español',
      poster: 'https://images.unsplash.com/photo-1526778548025-fa2f459cd5c1?w=400&auto=format&fit=crop&q=80',
      kind: WiwyVodKind.series,
      category: 'Documentales',
      rating: '9.0',
      year: '2025',
      streamUrl: 'https://dwamdstream104.akamaized.net/hls/live/2015530/dwstream104/index.m3u8',
      description: 'Investigaciones periodísticas internacionales sobre geopolítica, avances científicos y el planeta.',
    ),
    WiwyVodAsset(
      id: 'vod_pluto_anime',
      title: 'Pluto Anime & Manga Series',
      poster: 'https://images.unsplash.com/photo-1563089145-599997674d42?w=400&auto=format&fit=crop&q=80',
      kind: WiwyVodKind.series,
      category: 'Animación',
      rating: '8.9',
      year: '2025',
      streamUrl: 'https://service-stitcher.clusters.pluto.tv/stitch/hls/channel/5cae101b4fa9cb8db22591b8/master.m3u8?advertisingId=&appName=web&appVersion=5.14.0&deviceDNT=0&deviceId=1&deviceMake=Chrome&deviceModel=web&deviceType=web&deviceVersion=1&sid=1',
      description: 'Series de acción, mechas, fantasía épica y shonen dobladas al español.',
    ),
    WiwyVodAsset(
      id: 'vod_pluto_comedia',
      title: 'Pluto Cine Comedia & Risas',
      poster: 'https://images.unsplash.com/photo-1514306191717-452ec28c7814?w=400&auto=format&fit=crop&q=80',
      kind: WiwyVodKind.movie,
      category: 'Comedia & Drama',
      rating: '8.4',
      year: '2024',
      streamUrl: 'https://service-stitcher.clusters.pluto.tv/stitch/hls/channel/5d83c316279f0adf97782631/master.m3u8?advertisingId=&appName=web&appVersion=5.14.0&deviceDNT=0&deviceId=1&deviceMake=Chrome&deviceModel=web&deviceType=web&deviceVersion=1&sid=1',
      description: 'Comedias de enredos, parodias y humor irreverente para disfrutar en familia o amigos.',
    ),
    WiwyVodAsset(
      id: 'vod_pluto_drama',
      title: 'Pluto Cine Drama & Romance',
      poster: 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=400&auto=format&fit=crop&q=80',
      kind: WiwyVodKind.movie,
      category: 'Comedia & Drama',
      rating: '8.7',
      year: '2024',
      streamUrl: 'https://service-stitcher.clusters.pluto.tv/stitch/hls/channel/5d83c2c549641edf9b47bb9f/master.m3u8?advertisingId=&appName=web&appVersion=5.14.0&deviceDNT=0&deviceId=1&deviceMake=Chrome&deviceModel=web&deviceType=web&deviceVersion=1&sid=1',
      description: 'Historias emotivas, relaciones intensas y relatos cinematográficos profundos.',
    ),
    WiwyVodAsset(
      id: 'vod_pluto_naturaleza',
      title: 'Pluto Naturaleza Salvaje',
      poster: 'https://images.unsplash.com/photo-1534177616072-ef7dc120449d?w=400&auto=format&fit=crop&q=80',
      kind: WiwyVodKind.series,
      category: 'Documentales',
      rating: '9.2',
      year: '2025',
      streamUrl: 'https://service-stitcher.clusters.pluto.tv/stitch/hls/channel/5d83c3b77c64cfdfa069df1e/master.m3u8?advertisingId=&appName=web&appVersion=5.14.0&deviceDNT=0&deviceId=1&deviceMake=Chrome&deviceModel=web&deviceType=web&deviceVersion=1&sid=1',
      description: 'Grandes depredadores, selvas vírgenes y los hábitats más asombrosos del reino animal.',
    ),
    WiwyVodAsset(
      id: 'vod_pluto_paranormal',
      title: 'Pluto Misterio Paranormal',
      poster: 'https://images.unsplash.com/photo-1518709766631-a6a7f45921c3?w=400&auto=format&fit=crop&q=80',
      kind: WiwyVodKind.series,
      category: 'Terror & Suspenso',
      rating: '8.5',
      year: '2025',
      streamUrl: 'https://service-stitcher.clusters.pluto.tv/stitch/hls/channel/5d83c4a6500ee3deef9bf14c/master.m3u8?advertisingId=&appName=web&appVersion=5.14.0&deviceDNT=0&deviceId=1&deviceMake=Chrome&deviceModel=web&deviceType=web&deviceVersion=1&sid=1',
      description: 'Casos reales sin explicación, avistamientos OVNI e investigaciones de sucesos inexplicables.',
    ),
    WiwyVodAsset(
      id: 'vod_pluto_documundo',
      title: 'Pluto Documentales Mundo',
      poster: 'https://images.unsplash.com/photo-1461360370896-922624d12aa1?w=400&auto=format&fit=crop&q=80',
      kind: WiwyVodKind.series,
      category: 'Documentales',
      rating: '8.9',
      year: '2025',
      streamUrl: 'https://service-stitcher.clusters.pluto.tv/stitch/hls/channel/5d83c448279f0adf97782633/master.m3u8?advertisingId=&appName=web&appVersion=5.14.0&deviceDNT=0&deviceId=1&deviceMake=Chrome&deviceModel=web&deviceType=web&deviceVersion=1&sid=1',
      description: 'Relatos históricos, arqueología y los descubrimientos que transformaron la humanidad.',
    ),
    WiwyVodAsset(
      id: 'vod_pluto_retro',
      title: 'Pluto Retro: Cine Vintage',
      poster: 'https://images.unsplash.com/photo-1485095329183-d0797cdc5676?w=400&auto=format&fit=crop&q=80',
      kind: WiwyVodKind.series,
      category: 'Drama & Clásicos',
      rating: '8.8',
      year: '2024',
      streamUrl: 'https://service-stitcher.clusters.pluto.tv/stitch/hls/channel/5cae12547ffb438db2e5c8eb/master.m3u8?advertisingId=&appName=web&appVersion=5.14.0&deviceDNT=0&deviceId=1&deviceMake=Chrome&deviceModel=web&deviceType=web&deviceVersion=1&sid=1',
      description: 'Clásicos inolvidables de los 70s, 80s y 90s remasterizados para la era digital.',
    ),
    WiwyVodAsset(
      id: 'vod_pluto_crimen',
      title: 'Pluto Crímenes Verdaderos',
      poster: 'https://images.unsplash.com/photo-1557597774-9d273605dfa9?w=400&auto=format&fit=crop&q=80',
      kind: WiwyVodKind.series,
      category: 'Terror & Suspenso',
      rating: '8.9',
      year: '2025',
      streamUrl: 'https://service-stitcher.clusters.pluto.tv/stitch/hls/channel/5cae10a84fa9cb8db22591b9/master.m3u8?advertisingId=&appName=web&appVersion=5.14.0&deviceDNT=0&deviceId=1&deviceMake=Chrome&deviceModel=web&deviceType=web&deviceVersion=1&sid=1',
      description: 'Reconstrucciones forenses, testimonios policiales y los casos criminales más impactantes.',
    ),
    WiwyVodAsset(
      id: 'vod_apple_hdr',
      title: 'Apple Cinema Demo: Master HDR',
      poster: 'https://images.unsplash.com/photo-1478760329108-5c3ed9d495a0?w=400&auto=format&fit=crop&q=80',
      kind: WiwyVodKind.movie,
      category: 'Ciencia Ficción',
      rating: '9.0',
      year: '2024',
      streamUrl: 'https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8',
      description: 'Demostración de rango dinámico cinematográfico a alta tasa de bits y sonido envolvente.',
    ),
    WiwyVodAsset(
      id: 'vod_apple_soundstage',
      title: 'Apple Cinematic: Soundstage 16x9',
      poster: 'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=400&auto=format&fit=crop&q=80',
      kind: WiwyVodKind.movie,
      category: 'Ciencia Ficción',
      rating: '8.7',
      year: '2024',
      streamUrl: 'https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8',
      description: 'Transmisión de prueba de estándar HLS con sincronización de audio multicanal.',
    ),
    WiwyVodAsset(
      id: 'vod_bunny_short',
      title: 'Bunny & Friends: El Bosque Encantado',
      poster: 'https://images.unsplash.com/photo-1535268647677-300dbf3d78d1?w=400&auto=format&fit=crop&q=80',
      kind: WiwyVodKind.movie,
      category: 'Animación',
      rating: '8.6',
      year: '2023',
      streamUrl: 'https://media.w3.org/2010/05/bunny/movie.mp4',
      description: 'Aventura clásica de animación de código libre sobre la convivencia en el bosque salvaje.',
    ),
    WiwyVodAsset(
      id: 'vod_aljazeera_doc',
      title: 'Al Jazeera Global Investigations',
      poster: 'https://images.unsplash.com/photo-1585829365295-ab7cd400c167?w=400&auto=format&fit=crop&q=80',
      kind: WiwyVodKind.series,
      category: 'Documentales',
      rating: '9.1',
      year: '2025',
      streamUrl: 'https://live-hls-web-aja.getaj.net/AJA/01.m3u8',
      description: 'Periodismo de investigación galardonado, documentales y reportajes de actualidad mundial en vivo.',
    ),
    WiwyVodAsset(
      id: 'vod_pluto_series_latinas',
      title: 'Pluto Series Latinas de Culto',
      poster: 'https://images.unsplash.com/photo-1522869635100-9f4c5e86aa37?w=400&auto=format&fit=crop&q=80',
      kind: WiwyVodKind.series,
      category: 'Comedia & Drama',
      rating: '8.8',
      year: '2024',
      streamUrl: 'https://service-stitcher.clusters.pluto.tv/stitch/hls/channel/5d83c18b7c64cfdfa069df1a/master.m3u8?advertisingId=&appName=web&appVersion=5.14.0&deviceDNT=0&deviceId=1&deviceMake=Chrome&deviceModel=web&deviceType=web&deviceVersion=1&sid=1',
      description: 'Las mejores telenovelas y series dramáticas latinoamericanas que marcaron época.',
    ),
  ];

  /// Obtiene los elementos destacados o estantes VOD (/api/portalCore/v3/getShelveData)
  /// Si el usuario configuró una lista VOD personalizada, se prioriza esa lista.
  Future<List<WiwyVodAsset>> getFeaturedCatalog({bool forceRefresh = false}) async {
    final storage = _storage;
    if (storage != null) {
      final customUrl = storage.getCustomVodUrl();
      if (customUrl.isNotEmpty) {
        if (!forceRefresh) {
          final cached = storage.getCachedVodAssets();
          if (cached.isNotEmpty) return cached;
        }
        try {
          return await fetchVodFromUrl(customUrl);
        } catch (_) {
          final cached = storage.getCachedVodAssets();
          if (cached.isNotEmpty) return cached;
        }
      }
    }

    for (final host in NetworkDefaults.wiwyVodHosts) {
      try {
        final session = _portal.currentSession ?? await _portal.activate();
        final url = Uri.parse('$host/api/portalCore/v3/getShelveData');

        final response = await _client.post(
          url,
          headers: {
            'User-Agent': NetworkDefaults.rangerUserAgent,
            'App': NetworkDefaults.msAndroidApp,
            'App-Version': NetworkDefaults.msAndroidVersion,
            'Content-Type': 'application/json; charset=utf-8',
            'Content-Auth': session.authToken,
            'Content-License': session.license,
          },
          body: jsonEncode({
            'userId': session.userId,
            'dev_id': _portal.devId,
          }),
        ).timeout(NetworkDefaults.receiveTimeout);

        if (response.statusCode == 200) {
          final Map<String, dynamic> body = jsonDecode(response.body);
          final List list = body['data']?['items'] ?? [];
          if (list.isNotEmpty) {
            return list.map((item) => WiwyVodAsset.fromJson(item)).toList();
          }
        }
      } catch (_) {}
    }

    // Retorna el catálogo curado ampliado de películas si Wiwy no responde o está descontinuado
    return defaultCatalog;
  }

  /// Busca películas o series por nombre o categoría
  Future<List<WiwyVodAsset>> search(String query) async {
    if (query.isEmpty) return defaultCatalog;
    final lower = query.toLowerCase();
    final localMatches = defaultCatalog.where((item) =>
      item.title.toLowerCase().contains(lower) ||
      item.category.toLowerCase().contains(lower) ||
      item.description.toLowerCase().contains(lower)
    ).toList();

    for (final host in NetworkDefaults.wiwyVodHosts) {
      try {
        final session = _portal.currentSession ?? await _portal.activate();
        final url = Uri.parse('$host/api/portalCore/v3/searchByName');

        final response = await _client.post(
          url,
          headers: {
            'User-Agent': NetworkDefaults.rangerUserAgent,
            'App': NetworkDefaults.msAndroidApp,
            'App-Version': NetworkDefaults.msAndroidVersion,
            'Content-Type': 'application/json',
            'Content-Auth': session.authToken,
          },
          body: jsonEncode({
            'keyword': query,
            'userId': session.userId,
          }),
        ).timeout(NetworkDefaults.receiveTimeout);

        if (response.statusCode == 200) {
          final Map<String, dynamic> body = jsonDecode(response.body);
          final List list = body['data'] ?? [];
          if (list.isNotEmpty) {
            final remote = list.map((item) => WiwyVodAsset.fromJson(item)).toList();
            return [...localMatches, ...remote];
          }
        }
      } catch (_) {}
    }

    return localMatches;
  }
}
