class SeasonalThemeItem {
  final String id;
  final String label;
  final String? landscapeAsset;
  final String? portraitAsset;

  const SeasonalThemeItem({
    required this.id,
    required this.label,
    this.landscapeAsset,
    this.portraitAsset,
  });
}

class SeasonalTheme {
  static const SeasonalThemeItem none = SeasonalThemeItem(
    id: 'none',
    label: 'Sin tema',
    landscapeAsset: null,
    portraitAsset: null,
  );

  static const List<SeasonalThemeItem> themes = [
    none,
    SeasonalThemeItem(
      id: 'carnaval',
      label: 'Carnaval',
      landscapeAsset: 'assets/temas/cr.jpg',
      portraitAsset: 'assets/temas/cr_v.jpg',
    ),
    SeasonalThemeItem(
      id: 'halloween',
      label: 'Halloween',
      landscapeAsset: 'assets/temas/hlw.jpg',
      portraitAsset: 'assets/temas/hlw_v.jpg',
    ),
    SeasonalThemeItem(
      id: 'navidad',
      label: 'Navidad',
      landscapeAsset: 'assets/temas/nv.jpg',
      portraitAsset: 'assets/temas/nv_v.jpg',
    ),
    SeasonalThemeItem(
      id: 'ano_nuevo',
      label: 'Año Nuevo',
      landscapeAsset: 'assets/temas/an.jpg',
      portraitAsset: 'assets/temas/an_v.jpg',
    ),
  ];

  static SeasonalThemeItem fromId(String? id) {
    if (id == null || id.isEmpty) return none;
    return themes.firstWhere(
      (t) => t.id == id,
      orElse: () => none,
    );
  }
}
