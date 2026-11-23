class PlaylistPreset {
  final String name;
  final String url;
  final bool isVod;
  final String description;
  final bool isVerified;

  const PlaylistPreset({
    required this.name,
    required this.url,
    required this.isVod,
    required this.description,
    this.isVerified = true,
  });
}

class NetworkDefaults {
  static const String iptvOrgUrl = 'https://iptv-org.github.io/iptv/index.m3u';
  
  // Endpoints revelados en la ingeniería inversa (Cluster de Servidores Wiwy / Tele Latino)
  static const String wiwyPortalHost = 'https://eslitx.7jpeq68c.com';
  static const String wiwyVodHost = 'https://brkhzs.udigkkrc.com';

  // Cluster completo de nodos de alta disponibilidad para failover
  static const List<String> wiwyClusterHosts = [
    'https://eslitx.7jpeq68c.com', // Nodo principal de activación y canales
    'https://c2tgd.izvhrdcjb.com', // Nodo espejo 1
    'https://eaeylu.bvsvfb8c.com', // Nodo espejo 2
    'https://brkhzs.udigkkrc.com', // Nodo VOD y catálogo
  ];

  static const List<String> wiwyVodHosts = [
    'https://brkhzs.udigkkrc.com',
    'https://eaeylu.bvsvfb8c.com',
    'https://c2tgd.izvhrdcjb.com',
    'https://eslitx.7jpeq68c.com',
  ];

  // Listas de reproducción verificadas y sugeridas para TV y VOD
  static const List<PlaylistPreset> curatedPresets = [
    PlaylistPreset(
      name: 'Películas de Terror',
      url: 'http://bit.ly/FilmesdeTerror1',
      isVod: true,
      description: 'Colección de más de 390 películas de terror y suspenso en HD',
      isVerified: true,
    ),
    PlaylistPreset(
      name: 'Cristiano Filmes VOD',
      url: 'http://bit.ly/CR-FILMES',
      isVod: true,
      description: 'Catálogo de cine variado en M3U8 de alta definición',
      isVerified: true,
    ),
    PlaylistPreset(
      name: 'TV Global (2,020 Canales)',
      url: 'http://bit.ly/2D8ZHyz',
      isVod: false,
      description: 'Más de 2,000 canales de televisión mundial en vivo',
      isVerified: true,
    ),
    PlaylistPreset(
      name: 'Catálogo Global Completo (11,500+ Canales)',
      url: 'https://iptv-org.github.io/iptv/index.m3u',
      isVod: false,
      description: 'Catálogo global completo con más de 11,500 canales y logos oficiales (IPTV-Org)',
      isVerified: true,
    ),
    PlaylistPreset(
      name: 'TecnoTV Películas VOD',
      url: 'http://tecnotv.xyz/peliculas.m3u',
      isVod: true,
      description: 'Catálogo de películas y estrenos TecnoTV',
      isVerified: false,
    ),
    PlaylistPreset(
      name: 'TecnoTV Canales',
      url: 'http://tecnotv.xyz/lista.m3u',
      isVod: false,
      description: 'Canales latinos y de entretenimiento en vivo',
      isVerified: false,
    ),
    PlaylistPreset(
      name: 'Series del Japón',
      url: 'http://bit.ly/SeriesJapao',
      isVod: true,
      description: 'Series de anime y producciones japonesas',
      isVerified: false,
    ),
    PlaylistPreset(
      name: 'Apex IPTV Filmes',
      url: 'http://bit.ly/apexiptvfilmes',
      isVod: true,
      description: 'Películas en línea y cine internacional',
      isVerified: false,
    ),
  ];

  // Perfiles OpenVPN detectados
  static const String vpnServerPrimary = 'public-vpn-194.opengw.net:443';
  static const String vpnServerBackup = 'public-vpn-206.opengw.net:443';
  static const String vpnAssetDefault = 'assets/default.ovpn';
  static const String vpnAssetConfig = 'assets/vpn/config.ovpn';
  static const String vpnAssetVpnok = 'assets/vpn/vpnok.ovpn';
  
  // Headers emulados del cliente msandroid (Magis TV / Tele Latino)
  static const String rangerUserAgent = 'Ranger/4.9.4-17294ac0';
  static const String msAndroidApp = 'com.android.msandroid';
  static const String msAndroidVersion = '49902';
  
  // Seed hardcodeado identificado en libapp.so (offset 249290)
  static const String hardcodedDeviceSeed = '1798e621bbde68b9cf944375d862af41';

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
