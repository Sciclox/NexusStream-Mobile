import 'package:flutter/material.dart';
import '../core/app_scope.dart';
import '../core/app_theme.dart';

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final accent = state.accent.color;
    final orientation = MediaQuery.of(context).orientation;
    final asset = state.wallpaperService.getAssetForOrientation(orientation);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Color base oscuro cinematográfico
        Container(color: AppColors.background),

        // Resplandor ambiental de acento (Apple TV / PS5 Ambient Lighting)
        Positioned(
          top: -120,
          left: -80,
          right: -80,
          height: 380,
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.4),
                radius: 1.2,
                colors: [
                  accent.withValues(alpha: 0.12),
                  accent.withValues(alpha: 0.03),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Imagen de tema de temporada si está activa
        if (asset != null)
          Positioned.fill(
            child: Image.asset(
              asset,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),

        // Gradiente oscuro de contraste y viñeta
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.background.withValues(alpha: asset != null ? 0.85 : 0.4),
                  AppColors.background.withValues(alpha: asset != null ? 0.94 : 0.9),
                  AppColors.background,
                ],
              ),
            ),
          ),
        ),

        // Contenido de la app
        child,
      ],
    );
  }
}
