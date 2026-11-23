class ChannelCategories {
  static const String all = 'Todos';
  static const String sports = 'Deportes';
  static const String news = 'Noticias';
  static const String movies = 'Cine';
  static const String kids = 'Infantil';
  static const String entertainment = 'Entretenimiento';
  static const String culture = 'Cultura';
  static const String adults = 'Adultos';

  static const List<String> list = [
    all,
    sports,
    news,
    movies,
    kids,
    entertainment,
    culture,
    adults,
  ];

  /// Clasifica automáticamente una categoría o grupo crudo de M3U al listado normalizado.
  static String normalize(String? rawCategory) {
    if (rawCategory == null || rawCategory.trim().isEmpty) {
      return entertainment;
    }
    final lower = rawCategory.toLowerCase();
    if (lower.contains('deport') || lower.contains('sport') || lower.contains('espn') || lower.contains('fox sport')) {
      return sports;
    }
    if (lower.contains('noticia') || lower.contains('news') || lower.contains('info') || lower.contains('canal n')) {
      return news;
    }
    if (lower.contains('cine') || lower.contains('pelicula') || lower.contains('movie') || lower.contains('film') || lower.contains('cinema')) {
      return movies;
    }
    if (lower.contains('infantil') || lower.contains('kid') || lower.contains('anim') || lower.contains('dibujo') || lower.contains('cartoon')) {
      return kids;
    }
    if (lower.contains('cultura') || lower.contains('docu') || lower.contains('historia') || lower.contains('ciencia')) {
      return culture;
    }
    if (lower.contains('adult') || lower.contains('xxx') || lower.contains('erotic') || lower.contains('+18')) {
      return adults;
    }
    return entertainment;
  }
}
