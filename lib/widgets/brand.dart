import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class BrandLogo extends StatelessWidget {
  final double size;
  final bool showBadge;

  const BrandLogo({
    super.key,
    this.size = 32,
    this.showBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).primaryColor;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.25),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.3),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.25),
            child: Image.asset(
              'assets/icono.png',
              width: size,
              height: size,
              errorBuilder: (_, __, ___) => Icon(
                Icons.play_circle_fill_rounded,
                size: size,
                color: accent,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'NexusStream',
          style: TextStyle(
            fontSize: size * 0.65,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
            color: AppColors.textPrimary,
          ),
        ),
        if (showBadge) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accent.withValues(alpha: 0.25),
                  accent.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: accent.withValues(alpha: 0.6), width: 1),
            ),
            child: Text(
              '4K PRO',
              style: TextStyle(
                fontSize: size * 0.32,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
                color: accent,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
