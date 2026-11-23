import 'package:flutter/material.dart';

class AccentOption {
  final String name;
  final String label;
  final Color color;
  final IconData icon;

  const AccentOption({
    required this.name,
    required this.label,
    required this.color,
    this.icon = Icons.palette_rounded,
  });
}

class AccentTheme {
  static const List<AccentOption> options = [
    AccentOption(
      name: 'Rojo',
      label: 'Cinema Rojo',
      color: Color(0xFFE50914),
      icon: Icons.movie_filter_rounded,
    ),
    AccentOption(
      name: 'Azul',
      label: 'Apple Azul',
      color: Color(0xFF0A84FF),
      icon: Icons.tv_rounded,
    ),
    AccentOption(
      name: 'Oro',
      label: 'IMAX Oro',
      color: Color(0xFFFFB300),
      icon: Icons.star_rounded,
    ),
    AccentOption(
      name: 'Verde',
      label: 'Estudio Esmeralda',
      color: Color(0xFF00E676),
      icon: Icons.live_tv_rounded,
    ),
    AccentOption(
      name: 'Violeta',
      label: 'Amatista Velvet',
      color: Color(0xFFAF52DE),
      icon: Icons.auto_awesome_rounded,
    ),
    AccentOption(
      name: 'Cian',
      label: 'Cyber Cian',
      color: Color(0xFF00E5FF),
      icon: Icons.bolt_rounded,
    ),
  ];

  static AccentOption fromName(String? name) {
    if (name == null) return options[0]; // Cinema Rojo por defecto
    return options.firstWhere(
      (opt) => opt.name.toLowerCase() == name.toLowerCase() ||
               opt.label.toLowerCase() == name.toLowerCase(),
      orElse: () => options[0],
    );
  }
}
