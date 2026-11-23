import 'package:flutter/material.dart';
import '../core/app_scope.dart';
import '../core/app_theme.dart';
import '../models/channel.dart';
import 'channel_logo.dart';
import 'nexus_focusable.dart';

class ChannelCard extends StatelessWidget {
  final Channel channel;
  final VoidCallback onSelect;
  final bool isPlaying;

  const ChannelCard({
    super.key,
    required this.channel,
    required this.onSelect,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final accent = state.accent.color;

    return NexusFocusable(
      onSelect: onSelect,
      borderRadius: BorderRadius.circular(14),
      scale: 1.04,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isPlaying
                ? [
                    AppColors.cardSelected,
                    accent.withValues(alpha: 0.18),
                  ]
                : [
                    AppColors.card,
                    AppColors.card.withValues(alpha: 0.8),
                  ],
          ),
          border: Border.all(
            color: isPlaying ? accent : AppColors.border,
            width: isPlaying ? 1.8 : 1.0,
          ),
          boxShadow: isPlaying
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                  ),
                  child: ChannelLogo(
                    logoUrl: channel.logo,
                    channelName: channel.name,
                    category: channel.category,
                    size: 44,
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => state.toggleFavorite(channel),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        channel.isFavorite ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                        color: channel.isFavorite ? AppColors.neonPink : AppColors.textMuted,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              channel.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isPlaying ? accent : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 0.2,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${channel.flag} ${channel.country} • ${channel.category}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (isPlaying)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: accent.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'EN VIVO',
                          style: TextStyle(
                            color: accent,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                    ),
                    child: const Text(
                      'HD',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
