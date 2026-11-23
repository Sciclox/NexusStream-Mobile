import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../core/app_scope.dart';
import '../core/app_theme.dart';
import '../core/player_tuning.dart';
import '../models/channel.dart';
import '../widgets/channel_logo.dart';
import '../widgets/neon_spinner.dart';
import '../widgets/nexus_focusable.dart';

class PlayerScreen extends StatefulWidget {
  final Channel channel;

  const PlayerScreen({super.key, required this.channel});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final Player _player;
  late final VideoController _videoController;

  late Channel _currentChannel;
  bool _isBuffering = true;
  bool _hasError = false;
  String? _errorMessage;
  bool _showOsd = true;
  bool _showMiniGuide = false;
  double _volume = 1.0;

  // Modos de aspecto de pantalla
  BoxFit _aspectRatioMode = BoxFit.contain;
  final List<Map<String, dynamic>> _aspectModes = [
    {'name': '16:9 Original', 'fit': BoxFit.contain, 'icon': Icons.aspect_ratio},
    {'name': 'Zoom Cine', 'fit': BoxFit.cover, 'icon': Icons.crop_free},
    {'name': 'Estirar Todo', 'fit': BoxFit.fill, 'icon': Icons.fullscreen},
    {'name': 'Ajustar Ancho', 'fit': BoxFit.fitWidth, 'icon': Icons.fit_screen},
  ];
  int _aspectIndex = 0;

  // Métricas de VOD y tiempo
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = true;

  Timer? _osdTimer;
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _bufSub;
  StreamSubscription? _errSub;
  StreamSubscription? _playSub;

  final TextEditingController _miniGuideSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentChannel = widget.channel;
    WakelockPlus.enable();

    // Inicializar reproductor de media_kit con buffer de alto rendimiento
    _player = Player(
      configuration: const PlayerConfiguration(
        bufferSize: 32 * 1024 * 1024,
      ),
    );
    _videoController = VideoController(_player);

    _bufSub = _player.stream.buffering.listen((buffering) {
      if (mounted) setState(() => _isPreviewBuffering(buffering));
    });

    _errSub = _player.stream.error.listen((error) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'La señal se interrumpió o no responde en este momento.';
        });
      }
    });

    _posSub = _player.stream.position.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });

    _durSub = _player.stream.duration.listen((dur) {
      if (mounted) setState(() => _duration = dur);
    });

    _playSub = _player.stream.playing.listen((playing) {
      if (mounted) setState(() => _isPlaying = playing);
    });

    _playChannel(_currentChannel);
    _scheduleOsdAutoHide(seconds: 3);
  }

  void _isPreviewBuffering(bool buffering) {
    _isBuffering = buffering;
  }

  void _scheduleOsdAutoHide({int seconds = 3}) {
    _osdTimer?.cancel();
    _osdTimer = Timer(Duration(seconds: seconds), () {
      if (mounted && _showOsd && !_showMiniGuide) {
        setState(() => _showOsd = false);
      }
    });
  }

  void _resetOsdTimer() {
    if (!_showOsd) {
      setState(() => _showOsd = true);
    }
    _scheduleOsdAutoHide(seconds: 3);
  }

  void _playChannel(Channel channel) {
    setState(() {
      _currentChannel = channel;
      _isBuffering = true;
      _hasError = false;
      _errorMessage = null;
      _position = Duration.zero;
      _duration = Duration.zero;
    });

    try {
      _player.open(
        Media(
          channel.streamUrl,
          httpHeaders: PlayerTuning.getHttpHeaders(source: channel.source),
        ),
      );
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'No se pudo reproducir esta señal: $e';
      });
    }
  }

  void _cycleAspectRatio() {
    _resetOsdTimer();
    setState(() {
      _aspectIndex = (_aspectIndex + 1) % _aspectModes.length;
      _aspectRatioMode = _aspectModes[_aspectIndex]['fit'] as BoxFit;
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 1),
        backgroundColor: AppColors.surface,
        content: Text(
          'Aspecto: ${_aspectModes[_aspectIndex]['name']}',
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _seekRelative(int seconds) {
    _resetOsdTimer();
    final newPos = _position + Duration(seconds: seconds);
    final clamped = newPos < Duration.zero
        ? Duration.zero
        : (_duration > Duration.zero && newPos > _duration ? _duration : newPos);
    _player.seek(clamped);
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _osdTimer?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _bufSub?.cancel();
    _errSub?.cancel();
    _playSub?.cancel();
    _miniGuideSearchController.dispose();
    _player.dispose();
    super.dispose();
  }

  void _switchNextChannel(bool forward) {
    _resetOsdTimer();
    final state = AppScope.of(context);
    final list = state.channels;
    if (list.isEmpty) return;

    final currentIndex = list.indexWhere((c) => c.id == _currentChannel.id);
    if (currentIndex == -1) return;

    final nextIndex = forward
        ? (currentIndex + 1) % list.length
        : (currentIndex - 1 + list.length) % list.length;

    _playChannel(list[nextIndex]);
    state.setCurrentChannel(list[nextIndex]);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final accent = state.accent.color;
    // Solo es VOD si explícitamente proviene de VOD (NO si es señal en vivo de IPTV)
    final isVodMode = _currentChannel.source == 'vod';

    return Scaffold(
      backgroundColor: Colors.black,
      body: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.arrowUp): () => _switchNextChannel(false),
          const SingleActivator(LogicalKeyboardKey.arrowDown): () => _switchNextChannel(true),
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () => isVodMode ? _seekRelative(-10) : null,
          const SingleActivator(LogicalKeyboardKey.arrowRight): () => isVodMode ? _seekRelative(10) : null,
          const SingleActivator(LogicalKeyboardKey.space): () {
            _resetOsdTimer();
            _player.playOrPause();
          },
          const SingleActivator(LogicalKeyboardKey.select): () {
            setState(() => _showOsd = !_showOsd);
            if (_showOsd) _scheduleOsdAutoHide(seconds: 3);
          },
          const SingleActivator(LogicalKeyboardKey.enter): () {
            setState(() => _showOsd = !_showOsd);
            if (_showOsd) _scheduleOsdAutoHide(seconds: 3);
          },
          const SingleActivator(LogicalKeyboardKey.escape): () {
            if (_showMiniGuide) {
              setState(() => _showMiniGuide = false);
            } else {
              Navigator.of(context).pop();
            }
          },
        },
        child: Focus(
          autofocus: true,
          child: MouseRegion(
            onHover: (_) => _resetOsdTimer(),
            child: GestureDetector(
              onTap: () {
                setState(() => _showOsd = !_showOsd);
                if (_showOsd) _scheduleOsdAutoHide(seconds: 3);
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Renderizado de Video Limpio sin bordes
                  Center(
                    child: Video(
                      controller: _videoController,
                      controls: NoVideoControls,
                      fit: _aspectRatioMode,
                    ),
                  ),

                  // Spinner de buffering sutil
                  if (_isBuffering && !_hasError)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: NeonSpinner(
                          color: accent,
                          size: 52,
                          label: 'Cargando señal...',
                        ),
                      ),
                    ),

                  // Mensaje de Error
                  if (_hasError)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
                        constraints: const BoxConstraints(maxWidth: 420),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.error),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.warning_amber_rounded, size: 44, color: AppColors.error),
                            const SizedBox(height: 12),
                            Text(
                              _errorMessage ?? 'Error al reproducir la señal.',
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _playChannel(_currentChannel),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: accent,
                                    foregroundColor: Colors.black,
                                  ),
                                  icon: const Icon(Icons.refresh, size: 18),
                                  label: const Text('Reintentar'),
                                ),
                                const SizedBox(width: 12),
                                OutlinedButton.icon(
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.textSecondary,
                                    side: const BorderSide(color: AppColors.border),
                                  ),
                                  icon: const Icon(Icons.arrow_back, size: 18),
                                  label: const Text('Volver'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                  // OSD Flotante (Auto-ocultable en 3 segundos para dejar pantalla 100% limpia)
                  if (_showOsd) ...[
                    // Barra Superior OSD
                    Positioned(
                      top: 24,
                      left: 24,
                      right: 24,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.background.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.specularBorder),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
                                  tooltip: 'Volver',
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                                const SizedBox(width: 10),
                                ChannelLogo(
                                  logoUrl: _currentChannel.logo,
                                  channelName: _currentChannel.name,
                                  category: _currentChannel.category,
                                  size: 40,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _currentChannel.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Text(
                                            '${_currentChannel.flag} ${_currentChannel.country} • ${_currentChannel.category}',
                                            style: const TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 11,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isVodMode
                                                  ? Colors.amber.withValues(alpha: 0.2)
                                                  : Colors.red.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(
                                                color: isVodMode ? Colors.amber : Colors.red,
                                                width: 0.8,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (!isVodMode) ...[
                                                  Container(
                                                    width: 5,
                                                    height: 5,
                                                    decoration: const BoxDecoration(
                                                      color: Colors.red,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                ],
                                                Text(
                                                  isVodMode ? 'VOD PELÍCULA' : 'EN VIVO',
                                                  style: TextStyle(
                                                    color: isVodMode ? Colors.amber : Colors.red,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Botón cambio de aspecto
                                IconButton(
                                  icon: Icon(_aspectModes[_aspectIndex]['icon'] as IconData, color: Colors.white, size: 20),
                                  tooltip: 'Aspecto: ${_aspectModes[_aspectIndex]['name']}',
                                  onPressed: _cycleAspectRatio,
                                ),

                                // Botón Mini Guía lateral (solo para canales en vivo)
                                if (!isVodMode)
                                  IconButton(
                                    icon: Icon(
                                      _showMiniGuide ? Icons.view_sidebar : Icons.view_sidebar_outlined,
                                      color: _showMiniGuide ? accent : Colors.white,
                                      size: 20,
                                    ),
                                    tooltip: 'Mini Guía de Canales',
                                    onPressed: () {
                                      setState(() => _showMiniGuide = !_showMiniGuide);
                                      _scheduleOsdAutoHide(seconds: 4);
                                    },
                                  ),

                                // Favorito
                                IconButton(
                                  icon: Icon(
                                    _currentChannel.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                    color: _currentChannel.isFavorite ? AppColors.neonPink : Colors.white,
                                    size: 22,
                                  ),
                                  onPressed: () {
                                    state.toggleFavorite(_currentChannel);
                                    setState(() {
                                      _currentChannel = _currentChannel.copyWith(
                                        isFavorite: !_currentChannel.isFavorite,
                                      );
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Barra Inferior: SOLO si es VOD muestra el Slider de tiempo; si es Live TV muestra una píldora limpia informativa
                    Positioned(
                      bottom: 24,
                      left: 24,
                      right: 24,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.background.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.specularBorder),
                            ),
                            child: isVodMode
                                ? _buildVodControls(context, accent)
                                : _buildLiveTvControls(context, accent),
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Panel Lateral: Mini Guía de Canales (Slide-in Drawer)
                  if (_showMiniGuide && !isVodMode)
                    Positioned(
                      top: 0,
                      bottom: 0,
                      right: 0,
                      width: 320,
                      child: ClipRRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.backgroundSecondary.withValues(alpha: 0.95),
                              border: const Border(left: BorderSide(color: AppColors.border)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                                  child: Row(
                                    children: [
                                      Icon(Icons.list_alt_rounded, size: 20, color: accent),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Text(
                                          'Guía Rápida',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close, size: 20, color: AppColors.textMuted),
                                        onPressed: () => setState(() => _showMiniGuide = false),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Container(
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: AppColors.card,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: TextField(
                                      controller: _miniGuideSearchController,
                                      style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                                      onChanged: (_) => setState(() {}),
                                      decoration: const InputDecoration(
                                        hintText: 'Filtrar canal...',
                                        hintStyle: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                        prefixIcon: Icon(Icons.search, size: 16, color: AppColors.textMuted),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Expanded(
                                  child: Builder(
                                    builder: (_) {
                                      final q = _miniGuideSearchController.text.trim().toLowerCase();
                                      final channels = state.channels.where((c) {
                                        return q.isEmpty ||
                                            c.name.toLowerCase().contains(q) ||
                                            c.category.toLowerCase().contains(q) ||
                                            c.country.toLowerCase().contains(q);
                                      }).toList();

                                      return ListView.builder(
                                        itemCount: channels.length,
                                        itemBuilder: (ctx, idx) {
                                          final ch = channels[idx];
                                          final isCur = ch.id == _currentChannel.id;

                                          return NexusFocusable(
                                            onSelect: () {
                                              _playChannel(ch);
                                              state.setCurrentChannel(ch);
                                            },
                                            scale: 1.02,
                                            borderRadius: BorderRadius.circular(8),
                                            child: Container(
                                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: isCur ? accent.withValues(alpha: 0.18) : AppColors.card,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: isCur ? accent : Colors.transparent,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  ChannelLogo(
                                                    logoUrl: ch.logo,
                                                    channelName: ch.name,
                                                    category: ch.category,
                                                    size: 28,
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          ch.name,
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: isCur ? FontWeight.bold : FontWeight.w500,
                                                            color: isCur ? accent : AppColors.textPrimary,
                                                          ),
                                                        ),
                                                        Text(
                                                          '${ch.flag} ${ch.category}',
                                                          style: const TextStyle(
                                                            fontSize: 10,
                                                            color: AppColors.textMuted,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  if (isCur)
                                                    Icon(Icons.volume_up_rounded, size: 16, color: accent),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- CONTROLES LIMPIOS PARA TV EN VIVO (SIN BARRA DE CARGA NI TIMELINE) ---
  Widget _buildLiveTvControls(BuildContext context, Color accent) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 22),
              tooltip: 'Canal anterior (Flecha Arriba)',
              onPressed: () => _switchNextChannel(false),
            ),
            IconButton(
              icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 22),
              tooltip: 'Canal siguiente (Flecha Abajo)',
              onPressed: () => _switchNextChannel(true),
            ),
          ],
        ),

        const Row(
          children: [
            Icon(Icons.keyboard_arrow_up_rounded, size: 16, color: AppColors.textMuted),
            Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.textMuted),
            SizedBox(width: 6),
            Text(
              'Usa Flechas Arriba/Abajo para cambiar canal  •  Clic para ocultar información',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        Row(
          children: [
            Icon(
              _volume == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              color: Colors.white,
              size: 18,
            ),
            SizedBox(
              width: 90,
              child: Slider(
                value: _volume,
                activeColor: accent,
                onChanged: (v) {
                  _resetOsdTimer();
                  setState(() => _volume = v);
                  _player.setVolume(v * 100);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- CONTROLES EXCLUSIVOS PARA PELÍCULAS Y SERIES VOD ---
  Widget _buildVodControls(BuildContext context, Color accent) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              _formatDuration(_position),
              style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: accent,
                  inactiveTrackColor: AppColors.border,
                  thumbColor: accent,
                  overlayColor: accent.withValues(alpha: 0.2),
                  trackHeight: 3.5,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                ),
                child: Slider(
                  value: _position.inMilliseconds.toDouble().clamp(0.0, _duration.inMilliseconds.toDouble()),
                  max: _duration.inMilliseconds > 0 ? _duration.inMilliseconds.toDouble() : 1.0,
                  onChanged: (val) {
                    _resetOsdTimer();
                    _player.seek(Duration(milliseconds: val.toInt()));
                  },
                ),
              ),
            ),
            Text(
              _formatDuration(_duration),
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 22),
                  tooltip: 'Retroceder 10s',
                  onPressed: () => _seekRelative(-10),
                ),
                IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                    color: accent,
                    size: 34,
                  ),
                  tooltip: _isPlaying ? 'Pausar' : 'Reproducir',
                  onPressed: () {
                    _resetOsdTimer();
                    _player.playOrPause();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.forward_10_rounded, color: Colors.white, size: 22),
                  tooltip: 'Adelantar 10s',
                  onPressed: () => _seekRelative(10),
                ),
              ],
            ),
            Text(
              'Espacio: Pausa  •  ← / → : Buscar ±10s',
              style: TextStyle(
                color: accent,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            Row(
              children: [
                Icon(
                  _volume == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                SizedBox(
                  width: 90,
                  child: Slider(
                    value: _volume,
                    activeColor: accent,
                    onChanged: (v) {
                      _resetOsdTimer();
                      setState(() => _volume = v);
                      _player.setVolume(v * 100);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
