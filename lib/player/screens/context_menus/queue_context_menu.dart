import 'package:flutter/material.dart';
import '../../../widgets/context_menu.dart';
import '../metadata_editor_screen.dart';

class QueueContextMenu {
  static Future<void> show(
    BuildContext context, {
    required String trackName,
    required bool isFavorite,
    required VoidCallback onFavoriteTap,
    required VoidCallback onSongInfo,
    required VoidCallback onRemoveFromQueue,
    required VoidCallback onPlayAfterCurrent,
    required VoidCallback onAddToQueue,
    required VoidCallback onAddToPlaylists,
    required VoidCallback onStopAfterThis,
  }) {
    return ContextMenuSheet.show(
      context,
      header: TrackContextHeader(
        trackName: trackName,
        isFavorite: isFavorite,
        onFavoriteTap: onFavoriteTap,
      ),
      options: [
        ContextMenuOption(
          icon: Icons.info_outline,
          label: 'Song info',
          onTap: onSongInfo,
        ),
        ContextMenuOption(
          icon: Icons.remove_circle_outline,
          label: 'Remove from this queue',
          onTap: onRemoveFromQueue,
        ),
        ContextMenuOption(
          icon: Icons.queue_play_next,
          label: 'Play after current song',
          onTap: onPlayAfterCurrent,
        ),
        ContextMenuOption(
          icon: Icons.queue_music,
          label: 'Add to a queue',
          onTap: onAddToQueue,
        ),
        ContextMenuOption(
          icon: Icons.playlist_add,
          label: 'Add to playlists',
          onTap: onAddToPlaylists,
        ),
        ContextMenuOption(
          icon: Icons.stop_circle_outlined,
          label: 'Stop after this song',
          onTap: onStopAfterThis,
        ),
        ContextMenuOption(
          icon: Icons.edit_outlined,
          label: 'Edit info',
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => FractionallySizedBox(
                heightFactor: 1.0,
                child: MetadataEditorScreen(
                  tracks: [TrackMetadata(title: trackName)],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
