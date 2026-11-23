import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/accent_theme.dart';
import '../core/app_scope.dart';
import '../core/app_theme.dart';
import '../models/playlist.dart';
import '../services/vpn_service.dart';
import 'brand.dart';
import 'nav_destinations.dart';
import 'playlist_selector_sheet.dart';

class CinemaNavBar extends StatelessWidget {
  const CinemaNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final accent = state.accent.color;
    final activePlaylist = state.currentTabIndex == 1
        ? state.activeVodPlaylist
        : state.activeTvPlaylist;

    final isVpn = state.vpnStatus == VpnStatus.connected;
    final isConnecting = state.vpnStatus == VpnStatus.connecting;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      height: 62,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.specularBorder,
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                // Logotipo de la Marca
                const BrandLogo(size: 28),
                const SizedBox(width: 24),

                // Píldoras de Navegación Centrales
                Expanded(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.background.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: NavDestinations.items.map((item) {
                          final isSelected = state.currentTabIndex == item.index;

                          return Focus(
                            child: Builder(builder: (ctx) {
                              final isFocused = Focus.of(ctx).hasFocus;

                              return InkWell(
                                onTap: () => state.setTabIndex(item.index),
                                borderRadius: BorderRadius.circular(12),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOutCubic,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? accent.withValues(alpha: 0.22)
                                        : (isFocused ? AppColors.surfaceLight : Colors.transparent),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isFocused
                                          ? accent
                                          : (isSelected ? accent.withValues(alpha: 0.6) : Colors.transparent),
                                      width: isFocused ? 1.8 : 1,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: accent.withValues(alpha: 0.25),
                                              blurRadius: 10,
                                              spreadRadius: 0,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isSelected ? item.selectedIcon : item.icon,
                                        size: 17,
                                        color: isSelected ? accent : AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        item.label,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          color: isSelected ? accent : AppColors.textPrimary,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Selector Rápido de Lista Activa
                InkWell(
                  onTap: () => PlaylistSelectorSheet.show(
                    context,
                    type: state.currentTabIndex == 1 ? PlaylistType.vod : PlaylistType.tv,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.card.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          state.currentTabIndex == 1 ? Icons.movie_outlined : Icons.live_tv_rounded,
                          size: 15,
                          color: accent,
                        ),
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 130),
                          child: Text(
                            activePlaylist?.name ?? (state.currentTabIndex == 1 ? 'VOD Cine' : 'IPTV Global'),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Píldora de Seguridad VPN
                InkWell(
                  onTap: () => state.toggleVpn(),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isVpn
                          ? AppColors.neonGreen.withValues(alpha: 0.15)
                          : (isConnecting ? AppColors.warning.withValues(alpha: 0.15) : AppColors.card.withValues(alpha: 0.8)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isVpn
                            ? AppColors.neonGreen
                            : (isConnecting ? AppColors.warning : AppColors.border),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isVpn ? Icons.shield_rounded : Icons.shield_outlined,
                          size: 15,
                          color: isVpn
                              ? AppColors.neonGreen
                              : (isConnecting ? AppColors.warning : AppColors.textMuted),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isVpn ? 'VPN ACTIVA' : (isConnecting ? 'CONECTANDO...' : 'VPN OFF'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.4,
                            color: isVpn
                                ? AppColors.neonGreen
                                : (isConnecting ? AppColors.warning : AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Selector de Paleta / Tema Cinema (Cambio con 1 clic)
                PopupMenuButton<AccentOption>(
                  tooltip: 'Cambiar paleta de color',
                  initialValue: state.accent,
                  onSelected: (opt) => state.setAccent(opt),
                  color: AppColors.backgroundSecondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.card.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: accent.withValues(alpha: 0.6),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          state.accent.name,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                  itemBuilder: (_) => AccentTheme.options.map((opt) {
                    final isCur = opt.name == state.accent.name;
                    return PopupMenuItem<AccentOption>(
                      value: opt,
                      child: Row(
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: opt.color,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: opt.color.withValues(alpha: 0.5),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              opt.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isCur ? FontWeight.bold : FontWeight.normal,
                                color: isCur ? opt.color : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (isCur)
                            Icon(Icons.check_rounded, size: 16, color: opt.color),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
