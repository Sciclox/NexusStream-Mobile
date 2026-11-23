import 'package:flutter/material.dart';

class ChannelCountryInfo {
  final String name;
  final String code;
  final String flag;
  final String language;

  const ChannelCountryInfo({
    required this.name,
    required this.code,
    required this.flag,
    required this.language,
  });
}

class ChannelBrandBadge {
  final String label;
  final String? shortLabel;
  final Color primaryColor;
  final Color secondaryColor;
  final IconData icon;
  final String? directLogoUrl;

  const ChannelBrandBadge({
    required this.label,
    this.shortLabel,
    required this.primaryColor,
    required this.secondaryColor,
    required this.icon,
    this.directLogoUrl,
  });

  String get effectiveShortLabel => shortLabel ?? (label.length <= 4 ? label : label.substring(0, 3));
}

class ChannelMetadataHelper {
  /// Detecta automáticamente el país, código ISO, bandera e idioma
  static ChannelCountryInfo detectCountryAndLanguage({
    required String name,
    String? group,
    String? tvgCountry,
    String? tvgLanguage,
  }) {
    final lowerName = name.toLowerCase();
    final lowerGroup = (group ?? '').toLowerCase();
    final lowerCountryAttr = (tvgCountry ?? '').toLowerCase();

    // 1. Detección por atributo directo tvg-country
    if (lowerCountryAttr.isNotEmpty) {
      if (lowerCountryAttr == 'co' || lowerCountryAttr.contains('colomb')) {
        return const ChannelCountryInfo(name: 'Colombia', code: 'CO', flag: '🇨🇴', language: 'Español');
      }
      if (lowerCountryAttr == 'mx' || lowerCountryAttr.contains('mexic')) {
        return const ChannelCountryInfo(name: 'México', code: 'MX', flag: '🇲🇽', language: 'Español');
      }
      if (lowerCountryAttr == 'ar' || lowerCountryAttr.contains('argent')) {
        return const ChannelCountryInfo(name: 'Argentina', code: 'AR', flag: '🇦🇷', language: 'Español');
      }
      if (lowerCountryAttr == 'es' || lowerCountryAttr.contains('españ') || lowerCountryAttr.contains('spain')) {
        return const ChannelCountryInfo(name: 'España', code: 'ES', flag: '🇪🇸', language: 'Español');
      }
      if (lowerCountryAttr == 'us' || lowerCountryAttr.contains('united states') || lowerCountryAttr.contains('usa')) {
        return const ChannelCountryInfo(name: 'Estados Unidos', code: 'US', flag: '🇺🇸', language: 'Inglés');
      }
      if (lowerCountryAttr == 'pe' || lowerCountryAttr.contains('peru') || lowerCountryAttr.contains('perú')) {
        return const ChannelCountryInfo(name: 'Perú', code: 'PE', flag: '🇵🇪', language: 'Español');
      }
      if (lowerCountryAttr == 'cl' || lowerCountryAttr.contains('chile')) {
        return const ChannelCountryInfo(name: 'Chile', code: 'CL', flag: '🇨🇱', language: 'Español');
      }
      if (lowerCountryAttr == 'br' || lowerCountryAttr.contains('brazil') || lowerCountryAttr.contains('brasil')) {
        return const ChannelCountryInfo(name: 'Brasil', code: 'BR', flag: '🇧🇷', language: 'Portugués');
      }
    }

    // 2. Detección por group-title o nombre de canal
    final combined = '$lowerGroup $lowerName';

    if (combined.contains('colombia') ||
        combined.contains('caracol') ||
        combined.contains('rcn') ||
        combined.contains('win sports') ||
        combined.contains('señal colombia') ||
        combined.contains('teleantioquia')) {
      return const ChannelCountryInfo(name: 'Colombia', code: 'CO', flag: '🇨🇴', language: 'Español');
    }

    if (combined.contains('mexico') ||
        combined.contains('méxico') ||
        combined.contains('televisa') ||
        combined.contains('azteca') ||
        combined.contains('las estrellas') ||
        combined.contains('canal 5')) {
      return const ChannelCountryInfo(name: 'México', code: 'MX', flag: '🇲🇽', language: 'Español');
    }

    if (combined.contains('argentina') ||
        combined.contains('telefe') ||
        combined.contains('el trece') ||
        combined.contains('tyc') ||
        combined.contains('c5n') ||
        combined.contains('tn argentina')) {
      return const ChannelCountryInfo(name: 'Argentina', code: 'AR', flag: '🇦🇷', language: 'Español');
    }

    if (combined.contains('españa') ||
        combined.contains('spain') ||
        combined.contains('rtve') ||
        combined.contains('antena 3') ||
        combined.contains('la sexta') ||
        combined.contains('telecinco') ||
        combined.contains('cuatro') ||
        combined.contains('movistar')) {
      return const ChannelCountryInfo(name: 'España', code: 'ES', flag: '🇪🇸', language: 'Español');
    }

    if (combined.contains('peru') ||
        combined.contains('perú') ||
        combined.contains('america tv') ||
        combined.contains('atv') ||
        combined.contains('panamericana')) {
      return const ChannelCountryInfo(name: 'Perú', code: 'PE', flag: '🇵🇪', language: 'Español');
    }

    if (combined.contains('chile') ||
        combined.contains('tvn chile') ||
        combined.contains('mega') ||
        combined.contains('chilevision')) {
      return const ChannelCountryInfo(name: 'Chile', code: 'CL', flag: '🇨🇱', language: 'Español');
    }

    if (combined.contains('venezuela') || combined.contains('venevision') || combined.contains('televen')) {
      return const ChannelCountryInfo(name: 'Venezuela', code: 'VE', flag: '🇻🇪', language: 'Español');
    }

    if (combined.contains('ecuador') || combined.contains('ecuavisa') || combined.contains('teleamazonas')) {
      return const ChannelCountryInfo(name: 'Ecuador', code: 'EC', flag: '🇪🇨', language: 'Español');
    }

    if (combined.contains('uruguay') || combined.contains('teledoce') || combined.contains('canal 10 uruguay')) {
      return const ChannelCountryInfo(name: 'Uruguay', code: 'UY', flag: '🇺🇾', language: 'Español');
    }

    if (combined.contains('brasil') || combined.contains('brazil') || combined.contains('globo') || combined.contains('sbt')) {
      return const ChannelCountryInfo(name: 'Brasil', code: 'BR', flag: '🇧🇷', language: 'Portugués');
    }

    if (combined.contains('usa') ||
        combined.contains('united states') ||
        combined.contains('nbc') ||
        combined.contains('cbs') ||
        combined.contains('abc') ||
        combined.contains('fox news')) {
      return const ChannelCountryInfo(name: 'Estados Unidos', code: 'US', flag: '🇺🇸', language: 'Inglés');
    }

    // Por defecto para canales de IPTV hispanos comunes
    final detectedLang = (tvgLanguage != null && tvgLanguage.toLowerCase().contains('eng')) ? 'Inglés' : 'Español';
    return ChannelCountryInfo(name: 'Latinoamérica', code: 'LAT', flag: '🌎', language: detectedLang);
  }

  /// Devuelve la URL oficial verificada en PNG para canales populares cuando la lista M3U no incluye tvg-logo
  static String? resolveOfficialLogo(String channelName) {
    final lower = channelName.toLowerCase().trim();

    // 1. Caracol Televisión
    if (lower.contains('caracol hd 2') || lower.contains('caracol hd2')) {
      return 'https://i.imgur.com/Fww94l9.png';
    }
    if (lower.contains('caracol')) {
      return 'https://i.imgur.com/WbfdJbk.png';
    }

    // 2. RCN Televisión
    if (lower.contains('rcn hd 2') || lower.contains('rcn hd2')) {
      return 'https://i.imgur.com/SrMPTfc.png';
    }
    if (lower.contains('rcn novelas')) {
      return 'https://i.imgur.com/9wxdWNQ.png';
    }
    if (lower.contains('rcn')) {
      return 'https://i.imgur.com/5PhTaHp.png';
    }

    // 3. A&E / AE
    if (lower.contains('a&e') || lower.startsWith('ae ') || lower == 'ae' || lower.contains('ae hd')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/df/A%26E_Network_logo.svg/960px-A%26E_Network_logo.svg.png';
    }

    // 4. AMC
    if (lower.contains('amc')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/34/AMC_logo_2019.svg/960px-AMC_logo_2019.svg.png';
    }

    // 5. AXN
    if (lower.contains('axn')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/52/AXN_logo_%282015%29.svg/960px-AXN_logo_%282015%29.svg.png';
    }

    // 6. América TV
    if (lower.contains('america') || lower.contains('américa')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c8/Am%C3%A9rica_TV_%28Nuevo_logo_Junio_2020%29.png/500px-Am%C3%A9rica_TV_%28Nuevo_logo_Junio_2020%29.png';
    }

    // 7. Cartoon Network
    if (lower.contains('cartoon') || lower.contains('cn hd')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/80/Cartoon_Network_2010_logo.svg/960px-Cartoon_Network_2010_logo.svg.png';
    }

    // 8. Cinecanal
    if (lower.contains('cinecanal')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e6/CinecanalLA.png/960px-CinecanalLA.png';
    }

    // 9. Comedy Central
    if (lower.contains('comedy')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/aa/Comedy_Central_2018.svg/960px-Comedy_Central_2018.svg.png';
    }

    // 10. Discovery Channel & Discovery Kids
    if (lower.contains('discovery kids')) {
      return 'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/7f/Discovery_Kids_2021_2D_sin_wordmark.svg/960px-Discovery_Kids_2021_2D_sin_wordmark.svg.png';
    }
    if (lower.contains('discovery')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f1/2019_Discovery_logo.svg/960px-2019_Discovery_logo.svg.png';
    }

    // 11. ESPN
    if (lower.contains('espn')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2f/ESPN_wordmark.svg/960px-ESPN_wordmark.svg.png';
    }

    // 12. HBO
    if (lower.contains('hbo')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/de/HBO_logo.svg/960px-HBO_logo.svg.png';
    }

    // 13. TNT
    if (lower.contains('tnt')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/24/TNT_Logo_2016.svg/960px-TNT_Logo_2016.svg.png';
    }

    // 14. Warner Channel
    if (lower.contains('warner') || lower.contains('wb')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b0/Warner_Channel_2026.svg/960px-Warner_Channel_2026.svg.png';
    }

    // 15. Win Sports
    if (lower.contains('win sport') || lower.contains('win+')) {
      return 'https://i.imgur.com/DuSSrHV.png';
    }

    // 16. Fox Sports
    if (lower.contains('fox sport')) {
      return 'https://i.imgur.com/O9BapV9.png';
    }

    // 17. Sony
    if (lower.contains('sony')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9b/Sony_Movies_Logo.svg/500px-Sony_Movies_Logo.svg.png';
    }

    // 18. Telemundo
    if (lower.contains('telemundo')) {
      return 'https://imgx.fubo.tv/station_logos/telemundo_c.png';
    }

    // 19. Canal 1
    if (lower.contains('canal 1') || lower.contains('canal uno')) {
      return 'https://i.imgur.com/YFywPLC.png';
    }

    // 20. Citytv Bogotá
    if (lower.contains('citytv') || lower.contains('city tv')) {
      return 'https://i.imgur.com/h7K9EW9.png';
    }

    // 21. History Channel
    if (lower.contains('history')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/01/History_%282021%29.svg/500px-History_%282021%29.svg.png';
    }

    // 22. MTV
    if (lower.contains('mtv')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/68/MTV_2021_%28brand_version%29.svg/960px-MTV_2021_%28brand_version%29.svg.png';
    }

    // 23. Nickelodeon / Nick Jr
    if (lower.contains('nick jr')) {
      return 'https://i.imgur.com/KT4tdQs.png';
    }
    if (lower.contains('nickelodeon') || lower.contains('nick')) {
      return 'https://i.imgur.com/E84jnP8.png';
    }

    // 24. Universal TV / Studio Universal
    if (lower.contains('universal')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/42/Universal_TV_logo.svg/960px-Universal_TV_logo.svg.png';
    }

    // 25. Star Channel
    if (lower.contains('star channel') || lower.contains('fox channel')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/89/Star_Channel_2020.svg/960px-Star_Channel_2020.svg.png';
    }

    // 26. FX
    if (lower.contains('fx')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4d/FX_International_logo.svg/960px-FX_International_logo.svg.png';
    }

    // 27. TCM
    if (lower.contains('tcm')) {
      return 'https://i.imgur.com/QpDkrmT.png';
    }

    // 28. DW Español
    if (lower.contains('dw ') || lower.contains('deutsche welle')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/75/Deutsche_Welle_symbol_2012.svg/320px-Deutsche_Welle_symbol_2012.svg.png';
    }

    // 29. NASA TV
    if (lower.contains('nasa')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e5/NASA_logo.svg/320px-NASA_logo.svg.png';
    }

    // 30. France 24
    if (lower.contains('france 24')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/France_24_logo.svg/320px-France_24_logo.svg.png';
    }

    // 31. TeleSUR
    if (lower.contains('telesur')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/ea/TeleSUR_logo.svg/320px-TeleSUR_logo.svg.png';
    }

    // 32. RTVE 24h
    if (lower.contains('rtve') || lower.contains('24h')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/RTVE_24h_logo_2008.svg/320px-RTVE_24h_logo_2008.svg.png';
    }

    return null;
  }

  /// Resuelve la identidad visual y marca distintiva del canal para evitar cuadrados vacíos
  static ChannelBrandBadge resolveBrandBadge(String channelName, String category) {
    final lower = channelName.toLowerCase().trim();

    // 1. CARACOL TELEVISIÓN
    if (lower.contains('caracol')) {
      return const ChannelBrandBadge(
        label: 'CARACOL',
        shortLabel: 'CRC',
        primaryColor: Color(0xFF003882),
        secondaryColor: Color(0xFF0072CE),
        icon: Icons.all_inclusive_rounded,
      );
    }

    // 2. ESPN
    if (lower.contains('espn')) {
      String espnLabel = 'ESPN';
      String shortLabel = 'ESPN';
      if (lower.contains('2')) {
        espnLabel = 'ESPN 2';
        shortLabel = 'E2';
      } else if (lower.contains('3')) {
        espnLabel = 'ESPN 3';
        shortLabel = 'E3';
      } else if (lower.contains('4')) {
        espnLabel = 'ESPN 4';
        shortLabel = 'E4';
      } else if (lower.contains('plus') || lower.contains('+')) {
        espnLabel = 'ESPN+';
        shortLabel = 'E+';
      }
      return ChannelBrandBadge(
        label: espnLabel,
        shortLabel: shortLabel,
        primaryColor: const Color(0xFFB00020),
        secondaryColor: const Color(0xFFD50000),
        icon: Icons.sports_soccer_rounded,
      );
    }

    // 3. DISCOVERY / DISCOVERY KIDS
    if (lower.contains('discovery kids')) {
      return const ChannelBrandBadge(
        label: 'D•KIDS',
        shortLabel: 'DK',
        primaryColor: Color(0xFF00897B),
        secondaryColor: Color(0xFFFFB300),
        icon: Icons.child_care_rounded,
      );
    }
    if (lower.contains('discovery')) {
      return const ChannelBrandBadge(
        label: 'DISCOVERY',
        shortLabel: 'DSC',
        primaryColor: Color(0xFF002244),
        secondaryColor: Color(0xFF005596),
        icon: Icons.public_rounded,
      );
    }

    // 4. CARTOON NETWORK
    if (lower.contains('cartoon') || lower.contains('cn hd')) {
      return const ChannelBrandBadge(
        label: 'CN',
        shortLabel: 'CN',
        primaryColor: Color(0xFF111111),
        secondaryColor: Color(0xFF333333),
        icon: Icons.grid_view_rounded,
      );
    }

    // 5. CINECANAL
    if (lower.contains('cinecanal')) {
      return const ChannelBrandBadge(
        label: 'CINECANAL',
        shortLabel: 'CC',
        primaryColor: Color(0xFF3A1C71),
        secondaryColor: Color(0xFFD76D77),
        icon: Icons.movie_filter_rounded,
      );
    }

    // 6. AMC
    if (lower.contains('amc')) {
      return const ChannelBrandBadge(
        label: 'AMC',
        shortLabel: 'AMC',
        primaryColor: Color(0xFF1E272C),
        secondaryColor: Color(0xFF37474F),
        icon: Icons.theaters_rounded,
      );
    }

    // 7. AXN
    if (lower.contains('axn')) {
      return const ChannelBrandBadge(
        label: 'AXN',
        shortLabel: 'AXN',
        primaryColor: Color(0xFF1A1A1A),
        secondaryColor: Color(0xFFD50000),
        icon: Icons.flash_on_rounded,
      );
    }

    // 8. A&E / AE
    if (lower.contains('a&e') || lower.startsWith('ae ') || lower == 'ae') {
      return const ChannelBrandBadge(
        label: 'A&E',
        shortLabel: 'A&E',
        primaryColor: Color(0xFF263238),
        secondaryColor: Color(0xFFCFB53B),
        icon: Icons.live_tv_rounded,
      );
    }

    // 9. COMEDY CENTRAL
    if (lower.contains('comedy')) {
      return const ChannelBrandBadge(
        label: 'COMEDY',
        shortLabel: 'COM',
        primaryColor: Color(0xFFF9A825),
        secondaryColor: Color(0xFFFF8F00),
        icon: Icons.sentiment_very_satisfied_rounded,
      );
    }

    // 10. AMERICA TV
    if (lower.contains('america') || lower.contains('américa')) {
      return const ChannelBrandBadge(
        label: 'AMÉRICA',
        shortLabel: 'ATV',
        primaryColor: Color(0xFFC2185B),
        secondaryColor: Color(0xFFE91E63),
        icon: Icons.tv_rounded,
      );
    }

    // 11. HBO
    if (lower.contains('hbo')) {
      return const ChannelBrandBadge(
        label: 'HBO',
        shortLabel: 'HBO',
        primaryColor: Color(0xFF000000),
        secondaryColor: Color(0xFF424242),
        icon: Icons.movie_rounded,
      );
    }

    // 12. TNT
    if (lower.contains('tnt')) {
      return const ChannelBrandBadge(
        label: 'TNT',
        shortLabel: 'TNT',
        primaryColor: Color(0xFFD81B60),
        secondaryColor: Color(0xFFFF4081),
        icon: Icons.local_movies_rounded,
      );
    }

    // 13. WARNER
    if (lower.contains('warner') || lower.contains('wb')) {
      return const ChannelBrandBadge(
        label: 'WARNER',
        shortLabel: 'WB',
        primaryColor: Color(0xFF0D47A1),
        secondaryColor: Color(0xFF1976D2),
        icon: Icons.shield_rounded,
      );
    }

    // 14. FOX SPORTS / TYC / WIN
    if (lower.contains('fox sport')) {
      return const ChannelBrandBadge(
        label: 'FOX SPORT',
        shortLabel: 'FOX',
        primaryColor: Color(0xFF002244),
        secondaryColor: Color(0xFFFFB300),
        icon: Icons.sports_rounded,
      );
    }
    if (lower.contains('tyc')) {
      return const ChannelBrandBadge(
        label: 'TyC',
        shortLabel: 'TyC',
        primaryColor: Color(0xFF003366),
        secondaryColor: Color(0xFF006699),
        icon: Icons.sports_soccer_rounded,
      );
    }
    if (lower.contains('win sport')) {
      return const ChannelBrandBadge(
        label: 'WIN+',
        shortLabel: 'WIN',
        primaryColor: Color(0xFFE65100),
        secondaryColor: Color(0xFFFF6D00),
        icon: Icons.sports_soccer_rounded,
      );
    }

    // 15. RCN
    if (lower.contains('rcn')) {
      return const ChannelBrandBadge(
        label: 'RCN',
        primaryColor: Color(0xFF002244),
        secondaryColor: Color(0xFFFFB300),
        icon: Icons.tv_rounded,
      );
    }

    // 16. SONY
    if (lower.contains('sony')) {
      return const ChannelBrandBadge(
        label: 'SONY',
        primaryColor: Color(0xFF000000),
        secondaryColor: Color(0xFF333333),
        icon: Icons.live_tv_rounded,
      );
    }

    // 17. TELEMUNDO / UNIVISION
    if (lower.contains('telemundo')) {
      return const ChannelBrandBadge(
        label: 'TELEMUNDO',
        primaryColor: Color(0xFFC62828),
        secondaryColor: Color(0xFFEF5350),
        icon: Icons.tv_rounded,
      );
    }
    if (lower.contains('univision')) {
      return const ChannelBrandBadge(
        label: 'UNIVISION',
        primaryColor: Color(0xFF4A148C),
        secondaryColor: Color(0xFF7B1FA2),
        icon: Icons.tv_rounded,
      );
    }

    // 18. CNN / NOTICIAS
    if (lower.contains('cnn')) {
      return const ChannelBrandBadge(
        label: 'CNN',
        primaryColor: Color(0xFFCC0000),
        secondaryColor: Color(0xFF880000),
        icon: Icons.newspaper_rounded,
      );
    }

    // Generador por Categoría con Monograma Limpio
    final monogram = _generateMonogram(channelName);
    switch (category) {
      case 'Deportes':
        return ChannelBrandBadge(
          label: monogram,
          primaryColor: const Color(0xFF0F382A),
          secondaryColor: const Color(0xFF1E6B4F),
          icon: Icons.sports_soccer_rounded,
        );
      case 'Cine':
        return ChannelBrandBadge(
          label: monogram,
          primaryColor: const Color(0xFF2C1338),
          secondaryColor: const Color(0xFF5E2B77),
          icon: Icons.movie_filter_rounded,
        );
      case 'Infantil':
        return ChannelBrandBadge(
          label: monogram,
          primaryColor: const Color(0xFF4A2800),
          secondaryColor: const Color(0xFF8C4C00),
          icon: Icons.child_care_rounded,
        );
      case 'Noticias':
        return ChannelBrandBadge(
          label: monogram,
          primaryColor: const Color(0xFF0E274D),
          secondaryColor: const Color(0xFF1B498E),
          icon: Icons.newspaper_rounded,
        );
      case 'Cultura':
        return ChannelBrandBadge(
          label: monogram,
          primaryColor: const Color(0xFF1B3A36),
          secondaryColor: const Color(0xFF347068),
          icon: Icons.public_rounded,
        );
      case 'Adultos':
        return ChannelBrandBadge(
          label: monogram,
          primaryColor: const Color(0xFF4A0E17),
          secondaryColor: const Color(0xFF8A1E2E),
          icon: Icons.lock_rounded,
        );
      default:
        return ChannelBrandBadge(
          label: monogram,
          primaryColor: const Color(0xFF161F30),
          secondaryColor: const Color(0xFF273855),
          icon: Icons.tv_rounded,
        );
    }
  }

  static String _generateMonogram(String name) {
    final cleaned = name
        .replaceAll(RegExp(r'\b(hd|fhd|4k|sd|tv|canal|channel|latino|plus|\+)\b', caseSensitive: false), '')
        .trim();
    final words = cleaned.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return 'TV';
    if (words.length == 1) {
      final w = words.first;
      return w.length <= 4 ? w.toUpperCase() : w.substring(0, 3).toUpperCase();
    }
    return (words[0].substring(0, 1) + words[1].substring(0, 1)).toUpperCase();
  }
}
