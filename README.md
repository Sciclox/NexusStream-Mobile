# NexusStream - Proyecto Reconstruido de Ingeniería Inversa

Este repositorio contiene la reconstrucción limpia y estructurada en Flutter del proyecto **NexusStream (v1.0.0+16)** a partir de la decompilación y análisis forense del APK compilado (`libapp.so`, `assets`, `AndroidManifest.xml`).

---

## 🎯 Objetivos de este Proyecto
1. **Auditoría de Seguridad y Análisis de Red**: Comprender la arquitectura de aplicaciones que combinan streaming IPTV con túneles VPN integrados.
2. **Estudio de Arquitectura Multiplataforma**: Examinar la adaptación dinámica de interfaz para **Android TV (Leanback)**, **Móvil (Touch)** y **Desktop (Windows/Linux)** con `media_kit` (MPV).
3. **Análisis Forense**: Documentar el mecanismo de leeching/scraping contra la infraestructura de **Magis TV / Tele Latino** y las razones de sus fallos de concurrencia (`HTTP 401/409`).

---

## 📁 Estructura del Código

```text
APK-NexusStream/
├── assets/
│   ├── banner.png                  # Banner original para Android TV Leanback
│   ├── icono.png                   # Logotipo principal
│   ├── launcher_icon.png           # Ícono del lanzador
│   ├── temas/                      # Fondos de pantalla estacionales (Año Nuevo, Carnaval, Halloween, Navidad)
│   └── vpn/                        # Perfiles OpenVPN extraídos (config.ovpn, vpnok.ovpn)
├── lib/
│   ├── main.dart                   # Punto de entrada e inicialización de media_kit
│   ├── app.dart                    # Configuración de MaterialApp y tema dinámico
│   ├── core/
│   │   ├── accent_theme.dart       # 9 colores de acento neón identificados
│   │   ├── app_layout.dart         # Cálculo responsivo de columnas y paddings
│   │   ├── app_scope.dart          # Inyección de dependencias con InheritedNotifier
│   │   ├── app_theme.dart          # Tema Cyber-Dark (#090B10)
│   │   ├── channel_categories.dart # Categorías normalizadas (Deportes, Noticias, Cine, etc.)
│   │   ├── device_profile.dart     # Detección de Android TV vs Móvil vs PC
│   │   ├── formatters.dart         # Formateo de canales, duración y bitrate
│   │   ├── network_defaults.dart   # Endpoints de Magis TV y semillas hardcodeadas
│   │   ├── player_tuning.dart      # Opciones MPV de bajo nivel (buffers, demuxers)
│   │   └── seasonal_theme.dart     # Control de fondos de pantalla de temporada
│   ├── models/
│   │   └── channel.dart            # Modelo de canal con serialización JSON
│   ├── screens/
│   │   ├── root_shell.dart         # Contenedor adaptativo según el dispositivo
│   │   ├── tv_screen.dart          # Grilla de canales en directo con filtros
│   │   ├── player_screen.dart      # Reproductor MPV con controles OSD y D-pad
│   │   ├── vod_screen.dart         # Catálogo VOD de películas y series
│   │   ├── favorites_screen.dart   # Colección persistente de favoritos
│   │   └── settings_screen.dart    # Ajustes de VPN, temas, colores y fuentes
│   ├── services/
│   │   ├── m3u_parser.dart         # Parser robusto de listas M3U/M3U8
│   │   ├── m3u_service.dart        # Gestor de listas IPTV abiertas
│   │   ├── proxy_service.dart      # Gestor de proxies
│   │   ├── storage_service.dart    # Persistencia local con SharedPreferences
│   │   ├── vpn_service.dart        # Integración de OpenVPN con reintentos
│   │   └── wallpaper_service.dart  # Gestión de wallpapers estacionales
│   ├── state/
│   │   └── app_state.dart          # Gestor de estado global (ChangeNotifier)
│   ├── widgets/
│   │   ├── app_background.dart     # Fondo degradado con imagen de temporada
│   │   ├── brand.dart              # Logo y badge oficial
│   │   ├── category_filter.dart    # Selector horizontal de categorías
│   │   ├── channel_card.dart       # Tarjeta de canal con animaciones de foco
│   │   ├── channel_collection.dart # Grilla adaptativa de canales
│   │   ├── channel_logo.dart       # Logo con fallback inteligente
│   │   ├── desktop_sidebar.dart    # Barra lateral para Windows / Desktop
│   │   ├── feedback.dart           # Notificaciones y diálogos de confirmación
│   │   ├── mobile_nav_bar.dart     # Barra de navegación inferior para móviles
│   │   ├── nav_destinations.dart   # Definición de pestañas
│   │   ├── neon_spinner.dart       # Spinner neón rotativo
│   │   ├── nexus_focusable.dart    # Manejador de foco DPAD para Android TV
│   │   ├── search_field.dart       # Campo de búsqueda en vivo
│   │   └── tv_nav_bar.dart         # Barra superior optimizada para Android TV
│   └── wiwy/
│       ├── wiwy_des.dart           # Primitivas de descifrado DES del protocolo
│       ├── wiwy_portal.dart        # Handshake contra backend eslitx.7jpeq68c.com
│       ├── wiwy_source.dart        # Adaptador de señales Wiwy a Channel
│       └── wiwy_vod.dart           # Cliente de catálogo VOD
├── ANALISIS_ARQUITECTURA_Y_SEGURIDAD.md # Informe técnico detallado de la ingeniería inversa
└── pubspec.yaml                    # Dependencias y recursos declarados
```

---

## 🛠️ Cómo Ejecutar el Proyecto
Para compilar o depurar esta aplicación:
```bash
# 1. Instalar dependencias
flutter pub get

# 2. Ejecutar en Windows Desktop
flutter run -d windows

# 3. Ejecutar en emulador o dispositivo Android TV
flutter run -d <emulator-id>
```
