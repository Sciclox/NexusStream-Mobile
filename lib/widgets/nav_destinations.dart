import 'package:flutter/material.dart';

class NavDestinationItem {
  final int index;
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const NavDestinationItem({
    required this.index,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

class NavDestinations {
  static const List<NavDestinationItem> items = [
    NavDestinationItem(
      index: 0,
      label: 'TV Directo',
      icon: Icons.live_tv_outlined,
      selectedIcon: Icons.live_tv,
    ),
    NavDestinationItem(
      index: 1,
      label: 'Catálogo VOD',
      icon: Icons.movie_outlined,
      selectedIcon: Icons.movie,
    ),
    NavDestinationItem(
      index: 2,
      label: 'Favoritos',
      icon: Icons.favorite_border,
      selectedIcon: Icons.favorite,
    ),
    NavDestinationItem(
      index: 3,
      label: 'Ajustes',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
    ),
  ];
}
