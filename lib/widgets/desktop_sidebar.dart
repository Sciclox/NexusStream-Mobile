import 'package:flutter/material.dart';
import '../core/app_scope.dart';
import '../core/app_theme.dart';
import '../services/vpn_service.dart';
import 'brand.dart';
import 'nav_destinations.dart';

class DesktopSidebar extends StatelessWidget {
  const DesktopSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final accent = state.accent.color;

    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BrandLogo(size: 32),
          const SizedBox(height: 36),
          Expanded(
            child: ListView(
              children: NavDestinations.items.map((item) {
                final isSelected = state.currentTabIndex == item.index;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => state.setTabIndex(item.index),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? accent.withValues(alpha: 0.18) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? accent.withValues(alpha: 0.6) : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? item.selectedIcon : item.icon,
                            color: isSelected ? accent : AppColors.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            item.label,
                            style: TextStyle(
                              color: isSelected ? accent : AppColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // VPN Card
          _buildVpnCard(context, state),
        ],
      ),
    );
  }

  Widget _buildVpnCard(BuildContext context, dynamic state) {
    final isVpn = state.vpnStatus == VpnStatus.connected;
    final isConnecting = state.vpnStatus == VpnStatus.connecting;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isVpn ? Icons.shield : Icons.shield_outlined,
                size: 16,
                color: isVpn
                    ? AppColors.neonGreen
                    : (isConnecting ? AppColors.warning : AppColors.textMuted),
              ),
              const SizedBox(width: 8),
              Text(
                isVpn ? 'Túnel Seguro Activo' : 'Túnel Desconectado',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            state.vpnService.currentServer,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: OutlinedButton(
              onPressed: () => state.toggleVpn(),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                side: BorderSide(
                  color: isVpn ? AppColors.error : AppColors.neonCyan,
                ),
              ),
              child: Text(
                isVpn ? 'Desconectar' : 'Conectar VPN',
                style: TextStyle(
                  fontSize: 12,
                  color: isVpn ? AppColors.error : AppColors.neonCyan,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
