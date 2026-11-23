import 'package:flutter/material.dart';
import '../core/app_scope.dart';
import '../core/device_profile.dart';
import '../widgets/app_background.dart';
import '../widgets/cinema_nav_bar.dart';
import '../widgets/mobile_nav_bar.dart';
import 'favorites_screen.dart';
import 'settings_screen.dart';
import 'tv_screen.dart';
import 'vod_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  final List<Widget> _screens = const [
    TvScreen(),
    VodScreen(),
    FavoritesScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    DeviceProfile.evaluateSize(context);
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 720;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              if (!isCompact) const CinemaNavBar(),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: KeyedSubtree(
                    key: ValueKey<int>(state.currentTabIndex),
                    child: _screens[state.currentTabIndex],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: isCompact ? const MobileNavBar() : null,
    );
  }
}
