import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexusstream/core/network_defaults.dart';
import 'package:nexusstream/services/vpn_service.dart';

void main() {
  group('Extracted Cluster & VPN Integration Tests', () {
    test('NetworkDefaults contains all 4 extracted cluster domains', () {
      expect(NetworkDefaults.wiwyClusterHosts, contains('https://eslitx.7jpeq68c.com'));
      expect(NetworkDefaults.wiwyClusterHosts, contains('https://c2tgd.izvhrdcjb.com'));
      expect(NetworkDefaults.wiwyClusterHosts, contains('https://eaeylu.bvsvfb8c.com'));
      expect(NetworkDefaults.wiwyClusterHosts, contains('https://brkhzs.udigkkrc.com'));
    });

    test('OpenVPN servers and asset paths match extracted profile configurations', () {
      expect(NetworkDefaults.vpnServerPrimary, equals('public-vpn-194.opengw.net:443'));
      expect(NetworkDefaults.vpnServerBackup, equals('public-vpn-206.opengw.net:443'));
      expect(NetworkDefaults.vpnAssetDefault, equals('assets/default.ovpn'));
      expect(NetworkDefaults.vpnAssetConfig, equals('assets/vpn/config.ovpn'));
      expect(NetworkDefaults.vpnAssetVpnok, equals('assets/vpn/vpnok.ovpn'));

      final defaultOvpnFile = File('assets/default.ovpn');
      expect(defaultOvpnFile.existsSync(), isTrue);
      final defaultContent = defaultOvpnFile.readAsStringSync();
      expect(defaultContent, contains('remote public-vpn-194.opengw.net 443'));

      final vpnokOvpnFile = File('assets/vpn/vpnok.ovpn');
      expect(vpnokOvpnFile.existsSync(), isTrue);
      final vpnokContent = vpnokOvpnFile.readAsStringSync();
      expect(vpnokContent, contains('remote public-vpn-206.opengw.net 443'));
    });

    test('VpnProfile enum supports primary, backup and auto-failover', () {
      final vpnService = VpnService();
      expect(vpnService.selectedProfile, equals(VpnProfile.auto));
      expect(vpnService.currentServer, equals(NetworkDefaults.vpnServerPrimary));

      vpnService.setSelectedProfile(VpnProfile.backup206);
      expect(vpnService.selectedProfile, equals(VpnProfile.backup206));
    });
  });
}
