import 'package:flutter/material.dart';
import '../core/app_scope.dart';
import '../core/app_theme.dart';
import '../widgets/channel_collection.dart';
import '../widgets/feedback.dart';
import 'player_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final favorites = state.favoriteChannels;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Favoritos',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Los canales que guardaste en este dispositivo.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              if (favorites.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () async {
                    final confirmed = await AppFeedback.confirmDeleteFavorites(context);
                    if (confirmed) {
                      await state.clearAllFavorites();
                      if (context.mounted) {
                        AppFeedback.showSnackBar(context, 'Favoritos eliminados correctamente.');
                      }
                    }
                  },
                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                  label: const Text(
                    'Borrar todos',
                    style: TextStyle(color: AppColors.error, fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
            ],
          ),
        ),

        // Lista de favoritos o estado vacío
        Expanded(
          child: favorites.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.favorite_border,
                          size: 64,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Aún no tienes favoritos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Toca el corazón en cualquier canal para guardarlo aquí y acceder a él al instante.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => state.setTabIndex(0),
                          icon: const Icon(Icons.tv),
                          label: const Text('Explorar canales'),
                        ),
                      ],
                    ),
                  ),
                )
              : ChannelCollection(
                  channels: favorites,
                  onChannelSelected: (ch) {
                    state.setCurrentChannel(ch);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PlayerScreen(channel: ch),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
