import 'package:flutter/material.dart';
import '../../../widgets/context_menu.dart';
import '../metadata_editor_screen.dart';

class QueueMultiselectMenu {
  static Future<void> show(
    BuildContext context, {
    required int count,
    required VoidCallback onRemoveFromQueue,
    required VoidCallback onPlayAfterCurrent,
    required VoidCallback onAddToQueue,
    required VoidCallback onAddToPlaylists,
    required VoidCallback onAddToFavorites,
    required VoidCallback onRemoveFromFavorites,
    required List<TrackMetadata> tracks,
  }) {
    return ContextMenuSheet.show(
      context,
      header: MultiSelectContextHeader(count: count),
      options: [
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
          icon: Icons.favorite_border,
          label: 'Add to favorites',
          onTap: onAddToFavorites,
        ),
        ContextMenuOption(
          icon: Icons.heart_broken_outlined,
          label: 'Remove from favorites',
          onTap: onRemoveFromFavorites,
        ),
        ContextMenuOption(
          icon: Icons.edit_outlined,
          label: 'Bulk edits',
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => FractionallySizedBox(
                heightFactor: 1.0,
                child: MetadataEditorScreen(tracks: tracks),
              ),
            );
          },
        ),
      ],
    );
  }
}
