import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'app.dart';
import 'core/device_profile.dart';
import 'services/m3u_service.dart';
import 'services/storage_service.dart';
import 'services/vpn_service.dart';
import 'services/wallpaper_service.dart';
import 'state/app_state.dart';
import 'wiwy/wiwy_portal.dart';
import 'wiwy/wiwy_source.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar media_kit (MPV)
  MediaKit.ensureInitialized();

  // Detectar perfil de hardware (Android TV, Mobile, Desktop)
  await DeviceProfile.initialize();

  // Inicializar almacenamiento persistente
  final storage = await StorageService.init();

  // Inicializar servicios
  final m3uService = M3uService(storage);
  final vpnService = VpnService();
  await vpnService.initialize();

  final wallpaperService = WallpaperService(storage);
  final wiwyPortal = WiwyPortal(storage: storage);
  final wiwySource = WiwySource(wiwyPortal);

  // Instanciar el estado global
  final state = AppState(
    storage: storage,
    m3uService: m3uService,
    vpnService: vpnService,
    wallpaperService: wallpaperService,
    wiwyPortal: wiwyPortal,
    wiwySource: wiwySource,
  );

  runApp(NexusStreamApp(state: state));

  // Cargar canales en segundo plano tras renderizar la interfaz
  state.loadChannels();
}
