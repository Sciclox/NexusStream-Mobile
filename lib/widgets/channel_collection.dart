import 'package:flutter/material.dart';
import '../core/app_layout.dart';
import '../core/app_scope.dart';
import '../core/app_theme.dart';
import '../models/channel.dart';
import 'channel_card.dart';

class ChannelCollection extends StatelessWidget {
  final List<Channel> channels;
  final Function(Channel channel) onChannelSelected;

  const ChannelCollection({
    super.key,
    required this.channels,
    required this.onChannelSelected,
  });

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    if (channels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.tv_off, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            const Text(
              'No hay canales que coincidan con la búsqueda.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                state.setSearchQuery('');
                state.selectCategory('Todos');
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Restablecer filtros'),
            ),
          ],
        ),
      );
    }

    final crossAxisCount = AppLayout.getGridCrossAxisCount(context);
    final aspectRatio = AppLayout.getCardAspectRatio(context);

    return GridView.builder(
      padding: AppLayout.getContentPadding(context),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: aspectRatio,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: channels.length,
      itemBuilder: (context, index) {
        final ch = channels[index];
        final isPlaying = state.currentChannel?.id == ch.id;

        return ChannelCard(
          channel: ch,
          isPlaying: isPlaying,
          onSelect: () => onChannelSelected(ch),
        );
      },
    );
  }
}
