import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/channel_metadata_helper.dart';

class ChannelLogo extends StatelessWidget {
  final String? logoUrl;
  final String channelName;
  final String category;
  final double size;

  const ChannelLogo({
    super.key,
    required this.logoUrl,
    required this.channelName,
    this.category = 'Entretenimiento',
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveUrl = (logoUrl != null && logoUrl!.trim().startsWith('http'))
        ? logoUrl!.trim()
        : ChannelMetadataHelper.resolveOfficialLogo(channelName);

    if (effectiveUrl != null && effectiveUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.22),
        child: Container(
          width: size,
          height: size,
          color: AppColors.surfaceLight,
          padding: const EdgeInsets.all(2),
          child: Image.network(
            effectiveUrl,
            width: size,
            height: size,
            fit: BoxFit.contain,
            cacheWidth: (size * 2.5).toInt(),
            cacheHeight: (size * 2.5).toInt(),
            headers: const {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) NexusStream/1.0',
            },
            errorBuilder: (_, __, ___) => _buildBrandBadge(context),
          ),
        ),
      );
    }
    return _buildBrandBadge(context);
  }

  Widget _buildBrandBadge(BuildContext context) {
    final badge = ChannelMetadataHelper.resolveBrandBadge(channelName, category);
    final r = BorderRadius.circular(size * 0.22);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: r,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            badge.secondaryColor,
            badge.primaryColor,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: badge.primaryColor.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 0.8,
        ),
      ),
      child: ClipRRect(
        borderRadius: r,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Icono de fondo sutil
            Positioned(
              right: -4,
              bottom: -4,
              child: Opacity(
                opacity: 0.18,
                child: Icon(
                  badge.icon,
                  size: size * 0.65,
                  color: Colors.white,
                ),
              ),
            ),
            // Nombre de marca o monograma central optimizado para legibilidad
            Builder(
              builder: (_) {
                final displayText = (size <= 36) ? badge.effectiveShortLabel : badge.label;
                final fontSize = displayText.length <= 2
                    ? size * 0.44
                    : (displayText.length <= 4
                        ? size * 0.36
                        : (displayText.length <= 6 ? size * 0.28 : size * 0.22));

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    displayText,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: fontSize,
                      letterSpacing: 0.3,
                      shadows: const [
                        Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
