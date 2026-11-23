import 'package:flutter/material.dart';
import '../core/app_scope.dart';
import '../core/app_theme.dart';
import '../models/playlist.dart';
import 'add_playlist_dialog.dart';

class PlaylistSelectorSheet extends StatelessWidget {
  final PlaylistType type;

  const PlaylistSelectorSheet({
    super.key,
    required this.type,
  });

  static Future<void> show(BuildContext context, {required PlaylistType type}) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => PlaylistSelectorSheet(type: type),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final accent = state.accent.color;
    final playlists = type == PlaylistType.tv ? state.tvPlaylists : state.vodPlaylists;
    final activePlaylist = type == PlaylistType.tv ? state.activeTvPlaylist : state.activeVodPlaylist;

    final typeLabel = type == PlaylistType.tv ? 'Canales Live TV' : 'Películas y Series (VOD)';
    final defaultLabel = type == PlaylistType.tv ? 'IPTV Abierta Predeterminada (IPTV-Org)' : 'Catálogo VOD Predeterminado';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Row(
                children: [
                  Icon(
                    type == PlaylistType.tv ? Icons.live_tv_rounded : Icons.movie_filter_rounded,
                    color: accent,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cambiar Lista - $typeLabel',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Selecciona qué lista de reproducción deseas ver ahora',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      AddPlaylistDialog.show(context, initialType: type);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Nueva Lista', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // Contenido: Lista de listas
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // Opción de Lista por Defecto
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: activePlaylist == null ? accent.withValues(alpha: 0.12) : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: activePlaylist == null ? accent : AppColors.border,
                        width: activePlaylist == null ? 1.5 : 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Icon(
                        activePlaylist == null ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: activePlaylist == null ? accent : AppColors.textMuted,
                      ),
                      title: Text(
                        defaultLabel,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: activePlaylist == null ? FontWeight.bold : FontWeight.normal,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: const Text(
                        'Lista curada de acceso abierto sin enlaces externos',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                      trailing: activePlaylist == null
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'ACTIVA',
                                style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            )
                          : null,
                      onTap: () async {
                        Navigator.of(context).pop();
                        if (type == PlaylistType.tv) {
                          await state.resetCustomM3uPlaylist();
                        } else {
                          await state.resetCustomVodPlaylist();
                        }
                      },
                    ),
                  ),

                  // Listas personalizadas guardadas
                  ...playlists.map((pl) {
                    final isActive = pl.isActive;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isActive ? accent.withValues(alpha: 0.12) : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive ? accent : AppColors.border,
                          width: isActive ? 1.5 : 1,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: Icon(
                          isActive ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: isActive ? accent : AppColors.textMuted,
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                pl.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'ACTIVA',
                                  style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 3),
                            Text(
                              pl.url,
                              style: const TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: AppColors.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${pl.itemCount} ${type == PlaylistType.tv ? "canales" : "títulos"}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isActive ? accent : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.refresh, size: 18, color: AppColors.textSecondary),
                              tooltip: 'Refrescar contenido',
                              onPressed: () async {
                                final count = await state.refreshPlaylist(pl.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Lista "${pl.name}" actualizada ($count elementos).')),
                                  );
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                              tooltip: 'Eliminar lista',
                              onPressed: () async {
                                await state.deletePlaylist(pl.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Lista "${pl.name}" eliminada.')),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                        onTap: () async {
                          Navigator.of(context).pop();
                          if (!isActive) {
                            await state.activatePlaylist(pl.id);
                          }
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
