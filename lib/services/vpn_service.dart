import 'package:flutter/services.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart';
import '../core/network_defaults.dart';

enum VpnStatus { disconnected, connecting, connected, error, denied }
enum VpnProfile { primary194, backup206, auto }

class VpnService {
  late OpenVPN _engine;
  VpnStatus _status = VpnStatus.disconnected;
  String _currentServer = NetworkDefaults.vpnServerPrimary;
  VpnProfile _selectedProfile = VpnProfile.auto;
  Function(VpnStatus status)? onStatusChanged;

  VpnStatus get status => _status;
  bool get isConnected => _status == VpnStatus.connected;
  String get currentServer => _currentServer;
  VpnProfile get selectedProfile => _selectedProfile;

  void setSelectedProfile(VpnProfile profile) {
    _selectedProfile = profile;
  }

  Future<void> initialize() async {
    try {
      _engine = OpenVPN(
        onVpnStatusChanged: (data) {
          // Callback de actualización de estado de tráfico
        },
        onVpnStageChanged: (stage, raw) {
          _handleStageChange(stage);
        },
      );

      await _engine.initialize(
        groupIdentifier: 'group.com.nexusstream.nexusstream',
        providerBundleIdentifier: 'com.nexusstream.nexusstream.VPNExtension',
        localizedDescription: 'NexusStream VPN Tunnel',
      );
    } catch (e) {
      _status = VpnStatus.error;
      onStatusChanged?.call(_status);
    }
  }

  void _handleStageChange(VPNStage? stage) {
    if (stage == null) return;
    switch (stage) {
      case VPNStage.connected:
        _status = VpnStatus.connected;
        break;
      case VPNStage.connecting:
      case VPNStage.authenticating:
      case VPNStage.vpn_generate_config:
      case VPNStage.wait_connection:
        _status = VpnStatus.connecting;
        break;
      case VPNStage.disconnected:
        _status = VpnStatus.disconnected;
        break;
      case VPNStage.denied:
        _status = VpnStatus.denied;
        break;
      case VPNStage.error:
      default:
        _status = VpnStatus.error;
        break;
    }
    onStatusChanged?.call(_status);
  }

  /// Conecta usando la configuración especificada o con failover automático
  Future<void> connect({bool useBackup = false, VpnProfile? profile}) async {
    final effectiveProfile = profile ?? (useBackup ? VpnProfile.backup206 : _selectedProfile);
    _selectedProfile = effectiveProfile;

    String primaryAsset;
    String serverLabel;

    if (effectiveProfile == VpnProfile.backup206) {
      primaryAsset = NetworkDefaults.vpnAssetVpnok;
      serverLabel = NetworkDefaults.vpnServerBackup;
    } else {
      primaryAsset = NetworkDefaults.vpnAssetDefault;
      serverLabel = NetworkDefaults.vpnServerPrimary;
    }

    _currentServer = serverLabel;
    _status = VpnStatus.connecting;
    onStatusChanged?.call(_status);

    try {
      String configContent;
      try {
        configContent = await rootBundle.loadString(primaryAsset);
      } catch (_) {
        // Respaldo en caso de que default.ovpn no esté copiado
        configContent = await rootBundle.loadString(NetworkDefaults.vpnAssetConfig);
      }

      _engine.connect(
        configContent,
        serverLabel,
        certIsRequired: false,
        bypassPackages: [],
      );
    } catch (e) {
      if (effectiveProfile == VpnProfile.auto) {
        // Fallback automático al servidor secundario 206
        try {
          final fallbackContent = await rootBundle.loadString(NetworkDefaults.vpnAssetVpnok);
          _currentServer = NetworkDefaults.vpnServerBackup;
          _engine.connect(
            fallbackContent,
            NetworkDefaults.vpnServerBackup,
            certIsRequired: false,
            bypassPackages: [],
          );
          return;
        } catch (_) {}
      }
      _status = VpnStatus.error;
      onStatusChanged?.call(_status);
    }
  }

  Future<void> disconnect() async {
    try {
      _engine.disconnect();
      _status = VpnStatus.disconnected;
      onStatusChanged?.call(_status);
    } catch (e) {
      // Ignorar error al desconectar
    }
  }
}
