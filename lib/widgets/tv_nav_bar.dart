import 'package:flutter/material.dart';
import '../core/app_scope.dart';
import '../core/app_theme.dart';
import '../services/vpn_service.dart';
import 'brand.dart';
import 'nav_destinations.dart';

class TvNavBar extends StatelessWidget {
  const TvNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final accent = state.accent.color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const BrandLogo(size: 34),
          Row(
            children: NavDestinations.items.map((item) {
              final isSelected = state.currentTabIndex == item.index;

              return Focus(
                child: Builder(builder: (ctx) {
                  final isFocused = Focus.of(ctx).hasFocus;

                  return InkWell(
                    onTap: () => state.setTabIndex(item.index),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? accent.withValues(alpha: 0.18)
                            : (isFocused ? AppColors.surfaceLight : Colors.transparent),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isFocused
                              ? accent
                              : (isSelected ? accent.withValues(alpha: 0.5) : Colors.transparent),
                          width: isFocused ? 2 : 1,
                        ),
                        boxShadow: isFocused
                            ? [
                                BoxShadow(
                                  color: accent.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? item.selectedIcon : item.icon,
                            color: isSelected ? accent : AppColors.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item.label,
                            style: TextStyle(
                              color: isSelected ? accent : AppColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 15,
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
          // Indicador de VPN
          _buildVpnPill(context, state),
        ],
      ),
    );
  }

  Widget _buildVpnPill(BuildContext context, dynamic state) {
    final isVpn = state.vpnStatus == VpnStatus.connected;
    final isConnecting = state.vpnStatus == VpnStatus.connecting;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isVpn
            ? AppColors.neonGreen.withValues(alpha: 0.15)
            : (isConnecting ? AppColors.warning.withValues(alpha: 0.15) : AppColors.surfaceLight),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isVpn
              ? AppColors.neonGreen
              : (isConnecting ? AppColors.warning : AppColors.border),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVpn ? Icons.vpn_lock : Icons.vpn_key_outlined,
            size: 14,
            color: isVpn
                ? AppColors.neonGreen
                : (isConnecting ? AppColors.warning : AppColors.textMuted),
          ),
          const SizedBox(width: 6),
          Text(
            isVpn ? 'VPN OK' : (isConnecting ? 'CONECTANDO...' : 'VPN OFF'),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isVpn
                  ? AppColors.neonGreen
                  : (isConnecting ? AppColors.warning : AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
