import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../core/app_scope.dart';
import '../core/app_theme.dart';
import '../core/channel_categories.dart';
import '../core/player_tuning.dart';
import '../models/channel.dart';
import '../state/app_state.dart';
import '../widgets/channel_card.dart';
import '../widgets/channel_logo.dart';
import '../widgets/neon_spinner.dart';
import '../widgets/nexus_focusable.dart';
import 'player_screen.dart';

class TvScreen extends StatefulWidget {
  const TvScreen({super.key});

  @override
  State<TvScreen> createState() => _TvScreenState();
}

class _TvScreenState extends State<TvScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSplitView = true;
  Channel? _focusedChannel;
  bool _isPreviewMuted = true;
  bool _isPreviewBuffering = false;

  late final Player _previewPlayer;
  late final VideoController _previewVideoController;
  StreamSubscription? _previewBufSub;

  @override
  void initState() {
    super.initState();
    _previewPlayer = Player(
      configuration: const PlayerConfiguration(
        bufferSize: 16 * 1024 * 1024,
      ),
    );
    _previewVideoController = VideoController(_previewPlayer);
    _previewPlayer.setVolume(0); // Muted en previa para no saturar al explorar

    _previewBufSub = _previewPlayer.stream.buffering.listen((buffering) {
      if (mounted) setState(() => _isPreviewBuffering = buffering);
    });
  }

  @override
  void dispose() {
    _previewBufSub?.cancel();
    _previewPlayer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _previewChannel(Channel channel) {
    if (_focusedChannel?.id == channel.id) return;
    setState(() {
      _focusedChannel = channel;
      _isPreviewBuffering = true;
    });

    try {
      _previewPlayer.open(
        Media(
          channel.streamUrl,
          httpHeaders: PlayerTuning.getHttpHeaders(source: channel.source),
        ),
      );
    } catch (_) {}
  }

  void _openFullScreen(BuildContext context, Channel channel) async {
    _previewPlayer.pause();

    final state = AppScope.of(context);
    state.setCurrentChannel(channel);

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerScreen(channel: channel),
      ),
    );

    if (mounted && _focusedChannel != null) {
      _previewPlayer.play();
    }
  }

  void _togglePreviewAudio() {
    setState(() {
      _isPreviewMuted = !_isPreviewMuted;
      _previewPlayer.setVolume(_isPreviewMuted ? 0 : 100);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final accent = state.accent.color;
    final channels = state.filteredChannels;
    final width = MediaQuery.of(context).size.width;

    // En pantallas estrechas (< 900px), cambiamos automáticamente a modo mosaico
    final effectiveSplitView = _isSplitView && width >= 900;

    // Si aún no hay canal enfocado pero hay canales, enfocamos el primero
    if (_focusedChannel == null && channels.isNotEmpty) {
      _focusedChannel = channels.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _focusedChannel != null) {
          _previewChannel(_focusedChannel!);
        }
      });
    }

    return Column(
      children: [
        // Barra de Control Superior (Búsqueda + Selector de Vista + Orden)
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 2, 24, 8),
          child: Row(
            children: [
              // Barra de búsqueda con diseño cinema
              Expanded(
                flex: 3,
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                    onChanged: (val) => state.setSearchQuery(val),
                    decoration: InputDecoration(
                      hintText: 'Buscar entre ${state.channels.length} canales (ej: Caracol, ESPN, Colombia)...',
                      hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textMuted),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16, color: AppColors.textMuted),
                              onPressed: () {
                                _searchController.clear();
                                state.setSearchQuery('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Selector del Tipo de Filtro (Categorías | Países | Idiomas)
              Container(
                height: 40,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    _buildFilterTypePill(
                      label: 'Categorías',
                      icon: Icons.label_outline_rounded,
                      isSelected: state.filterType == ChannelFilterType.category,
                      accent: accent,
                      onTap: () => state.setFilterType(ChannelFilterType.category),
                    ),
                    const SizedBox(width: 3),
                    _buildFilterTypePill(
                      label: 'Países',
                      icon: Icons.public_rounded,
                      isSelected: state.filterType == ChannelFilterType.country,
                      accent: accent,
                      onTap: () => state.setFilterType(ChannelFilterType.country),
                    ),
                    const SizedBox(width: 3),
                    _buildFilterTypePill(
                      label: 'Idiomas',
                      icon: Icons.translate_rounded,
                      isSelected: state.filterType == ChannelFilterType.language,
                      accent: accent,
                      onTap: () => state.setFilterType(ChannelFilterType.language),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Menú de Ordenación
              PopupMenuButton<ChannelSortMode>(
                initialValue: state.sortMode,
                tooltip: 'Ordenar canales',
                onSelected: (mode) => state.setSortMode(mode),
                color: AppColors.backgroundSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sort_rounded, size: 16, color: accent),
                      const SizedBox(width: 6),
                      Text(
                        _getSortModeName(state.sortMode),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.textMuted),
                    ],
                  ),
                ),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: ChannelSortMode.original,
                    child: Text('Orden original de lista', style: TextStyle(fontSize: 13)),
                  ),
                  const PopupMenuItem(
                    value: ChannelSortMode.nameAsc,
                    child: Text('Nombre (A - Z)', style: TextStyle(fontSize: 13)),
                  ),
                  const PopupMenuItem(
                    value: ChannelSortMode.nameDesc,
                    child: Text('Nombre (Z - A)', style: TextStyle(fontSize: 13)),
                  ),
                  const PopupMenuItem(
                    value: ChannelSortMode.country,
                    child: Text('Por País', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),

              const SizedBox(width: 10),

              // Selector de Vista (Estudio vs Mosaico)
              if (width >= 900)
                Container(
                  height: 40,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      _buildViewModeButton(
                        icon: Icons.splitscreen_rounded,
                        label: 'Estudio',
                        isSelected: _isSplitView,
                        accent: accent,
                        onTap: () => setState(() => _isSplitView = true),
                      ),
                      const SizedBox(width: 4),
                      _buildViewModeButton(
                        icon: Icons.grid_view_rounded,
                        label: 'Mosaico',
                        isSelected: !_isSplitView,
                        accent: accent,
                        onTap: () {
                          setState(() => _isSplitView = false);
                          _previewPlayer.pause();
                        },
                      ),
                    ],
                  ),
                ),

              const SizedBox(width: 8),

              // Botón de refresco
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 19, color: AppColors.textSecondary),
                tooltip: 'Recargar lista de canales',
                onPressed: () => state.loadChannels(forceRefresh: true),
              ),
            ],
          ),
        ),

        // Barra Dinámica de Filtro (Categorías, Países o Idiomas)
        SizedBox(
          height: 38,
          child: _buildDynamicFilterBar(state, accent),
        ),

        const SizedBox(height: 10),

        // Cuerpo Principal
        Expanded(
          child: Builder(
            builder: (ctx) {
              if (state.isLoading) {
                return Center(
                  child: NeonSpinner(
                    label: 'Sincronizando canales...',
                    size: 54,
                    color: accent,
                  ),
                );
              }

              if (channels.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.tv_off_rounded, size: 54, color: AppColors.textMuted),
                      const SizedBox(height: 14),
                      const Text(
                        'No hay canales disponibles para los filtros seleccionados.',
                        style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () {
                          _searchController.clear();
                          state.setSearchQuery('');
                          state.selectCategory('Todos');
                          state.selectCountry('Todos');
                          state.selectLanguage('Todos');
                        },
                        child: const Text('Restablecer todos los filtros'),
                      ),
                    ],
                  ),
                );
              }

              if (effectiveSplitView) {
                return _buildSplitStage(context, state, channels, accent);
              }

              return _buildGridView(context, state, channels);
            },
          ),
        ),
      ],
    );
  }

  String _getSortModeName(ChannelSortMode mode) {
    switch (mode) {
      case ChannelSortMode.original:
        return 'Original';
      case ChannelSortMode.nameAsc:
        return 'A-Z';
      case ChannelSortMode.nameDesc:
        return 'Z-A';
      case ChannelSortMode.country:
        return 'País';
    }
  }

  Widget _buildFilterTypePill({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? accent.withValues(alpha: 0.22) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: isSelected ? accent.withValues(alpha: 0.5) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? accent : AppColors.textMuted),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicFilterBar(AppState state, Color accent) {
    List<String> items = [];
    String selectedItem = '';
    void Function(String) onSelect = (_) {};

    switch (state.filterType) {
      case ChannelFilterType.category:
        items = ChannelCategories.list;
        selectedItem = state.selectedCategory;
        onSelect = (cat) => state.selectCategory(cat);
        break;
      case ChannelFilterType.country:
        items = state.availableCountries;
        selectedItem = state.selectedCountry;
        onSelect = (ctry) => state.selectCountry(ctry);
        break;
      case ChannelFilterType.language:
        items = state.availableLanguages;
        selectedItem = state.selectedLanguage;
        onSelect = (lang) => state.selectLanguage(lang);
        break;
    }

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = item == selectedItem;

        return Focus(
          child: Builder(builder: (ctx) {
            final isFocused = Focus.of(ctx).hasFocus;

            return InkWell(
              onTap: () => onSelect(item),
              borderRadius: BorderRadius.circular(18),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? accent.withValues(alpha: 0.22)
                      : (isFocused ? AppColors.surfaceLight : AppColors.surface),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isFocused
                        ? accent
                        : (isSelected ? accent.withValues(alpha: 0.7) : AppColors.border),
                    width: isFocused ? 1.8 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.2),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      item,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildViewModeButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? accent.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? accent : AppColors.textMuted,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? accent : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- MODO ESTUDIO: SPLIT STAGE CON PREVIA EN DIRECTO ---
  Widget _buildSplitStage(
    BuildContext context,
    dynamic state,
    List<Channel> channels,
    Color accent,
  ) {
    final curChannel = _focusedChannel ?? channels.first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Columna Izquierda: Guía de Canales Vertical
          Container(
            width: 360,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabecera de la guía
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: AppColors.card,
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.format_list_bulleted_rounded, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        '${channels.length} canales filtrados',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const Spacer(),
                      const Text('D-Pad / Enter', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                    ],
                  ),
                ),

                // Lista de Canales
                Expanded(
                  child: ListView.builder(
                    itemCount: channels.length,
                    itemBuilder: (ctx, index) {
                      final ch = channels[index];
                      final isFocused = ch.id == curChannel.id;

                      return NexusFocusable(
                        onSelect: () {
                          _previewChannel(ch);
                          _openFullScreen(context, ch);
                        },
                        scale: 1.02,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isFocused
                                ? accent.withValues(alpha: 0.16)
                                : AppColors.card.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isFocused ? accent : Colors.transparent,
                              width: 1.2,
                            ),
                          ),
                          child: InkWell(
                            onTap: () => _previewChannel(ch),
                            borderRadius: BorderRadius.circular(10),
                            child: Row(
                              children: [
                                // Número del canal
                                SizedBox(
                                  width: 28,
                                  child: Text(
                                    '${index + 1}'.padLeft(2, '0'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isFocused ? accent : AppColors.textMuted,
                                    ),
                                  ),
                                ),

                                // Logo del canal con generador de insignia
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceLight,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: ChannelLogo(
                                    logoUrl: ch.logo,
                                    channelName: ch.name,
                                    category: ch.category,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // Nombre, País e Idioma
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ch.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isFocused ? FontWeight.bold : FontWeight.w500,
                                          color: isFocused ? accent : AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        '${ch.flag} ${ch.country} • ${ch.category}',
                                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                      ),
                                    ],
                                  ),
                                ),

                                // Indicador de emisión o favorito
                                if (isFocused) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: accent.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 5,
                                          height: 5,
                                          decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'PREVIA',
                                          style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: accent),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else if (ch.isFavorite) ...[
                                  const Icon(Icons.favorite_rounded, size: 14, color: AppColors.neonPink),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          // Columna Derecha: Escenario Principal / Hero Preview Deck
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Marco de Video Previa
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Video Player Previa
                        Center(
                          child: Video(
                            controller: _previewVideoController,
                            controls: NoVideoControls,
                            fit: BoxFit.contain,
                          ),
                        ),

                        // Spinner mientras conecta la previa
                        if (_isPreviewBuffering)
                          Center(
                            child: NeonSpinner(
                              color: accent,
                              size: 48,
                              label: 'Conectando con señal...',
                            ),
                          ),

                        // Barra Superior Flotante sobre la Previa
                        Positioned(
                          top: 14,
                          left: 14,
                          right: 14,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'TRANSMISIÓN EN DIRECTO',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.6,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              // Botón de silenciar / audio en previa
                              IconButton(
                                icon: Icon(
                                  _isPreviewMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black.withValues(alpha: 0.6),
                                ),
                                tooltip: _isPreviewMuted ? 'Activar sonido de previa' : 'Silenciar previa',
                                onPressed: _togglePreviewAudio,
                              ),
                            ],
                          ),
                        ),

                        // Botón Central "Pantalla Completa"
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: () => _openFullScreen(context, curChannel),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 6,
                            ),
                            icon: const Icon(Icons.fullscreen_rounded, size: 22),
                            label: const Text(
                              'Pantalla Completa',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Ficha Técnica y Metadatos del Canal Seleccionado
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ChannelLogo(
                          logoUrl: curChannel.logo,
                          channelName: curChannel.name,
                          category: curChannel.category,
                          size: 46,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              curChannel.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  '${curChannel.flag} ${curChannel.country} • ${curChannel.category} (${curChannel.language})',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: accent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: accent.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    '1080p FHD • 60 FPS • HLS',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: accent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Botón Favorito
                      IconButton(
                        icon: Icon(
                          curChannel.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: curChannel.isFavorite ? AppColors.neonPink : AppColors.textMuted,
                          size: 24,
                        ),
                        onPressed: () {
                          state.toggleFavorite(curChannel);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- MODO MOSAICO: CINEMA WALL GRID ---
  Widget _buildGridView(BuildContext context, dynamic state, List<Channel> channels) {
    final width = MediaQuery.of(context).size.width;
    int crossAxisCount = 5;
    if (width < 600) {
      crossAxisCount = 2;
    } else if (width < 900) {
      crossAxisCount = 3;
    } else if (width < 1400) {
      crossAxisCount = 4;
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 1.35,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: channels.length,
      itemBuilder: (context, index) {
        final ch = channels[index];
        final isPlaying = state.currentChannel?.id == ch.id;

        return ChannelCard(
          channel: ch,
          isPlaying: isPlaying,
          onSelect: () => _openFullScreen(context, ch),
        );
      },
    );
  }
}
