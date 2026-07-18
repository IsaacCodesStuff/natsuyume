import 'package:flutter/material.dart';
import '../theme/natsuyume_theme.dart';

enum PlayerTab { queues, albums, artists, playlists, settings }

class NatsuyumeBottomNavBar extends StatelessWidget {
  final PlayerTab currentTab;
  final void Function(PlayerTab tab) onTabSelected;

  const NatsuyumeBottomNavBar({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = NatsuyumeTheme.of(context).colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.divider, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: PlayerTab.values.map((tab) {
              final selected = tab == currentTab;
              return GestureDetector(
                onTap: () => onTabSelected(tab),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 64,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _iconFor(tab),
                        size: 24,
                        color: selected
                            ? colors.accent
                            : colors.onSurfaceVariant,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _labelFor(tab),
                        style: TextStyle(
                          fontSize: 11,
                          color: selected
                              ? colors.accent
                              : colors.onSurfaceVariant,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  IconData _iconFor(PlayerTab tab) {
    switch (tab) {
      case PlayerTab.queues:
        return Icons.queue_music;
      case PlayerTab.albums:
        return Icons.album_outlined;
      case PlayerTab.artists:
        return Icons.person_outline;
      case PlayerTab.playlists:
        return Icons.playlist_play;
      case PlayerTab.settings:
        return Icons.settings_outlined;
    }
  }

  String _labelFor(PlayerTab tab) {
    switch (tab) {
      case PlayerTab.queues:
        return 'Queues';
      case PlayerTab.albums:
        return 'Albums';
      case PlayerTab.artists:
        return 'Artists';
      case PlayerTab.playlists:
        return 'Playlists';
      case PlayerTab.settings:
        return 'More';
    }
  }
}
