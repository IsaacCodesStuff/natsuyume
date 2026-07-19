import 'package:flutter/material.dart';
import '../../../widgets/context_menu.dart';
import '../metadata_editor_screen.dart';

class AlbumTrackMultiselectMenu {
  static Future<void> show(
    BuildContext context, {
    required int count,
    required VoidCallback onPlayAfterCurrent,
    required VoidCallback onAddToCurrentQueue,
    required VoidCallback onAddToQueue,
    required VoidCallback onAddToPlaylists,
    required VoidCallback onAddToFavorites,
    required VoidCallback onRemoveFromFavorites,
    required VoidCallback onClearPlaybackHistory,
    required List<TrackMetadata> tracks,
  }) {
    return ContextMenuSheet.show(
      context,
      header: MultiSelectContextHeader(count: count),
      options: [
        ContextMenuOption(
          icon: Icons.queue_play_next,
          label: 'Play after current song',
          onTap: onPlayAfterCurrent,
        ),
        ContextMenuOption(
          icon: Icons.playlist_play,
          label: 'Add to currently playing queue',
          onTap: onAddToCurrentQueue,
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
        ContextMenuOption(
          icon: Icons.history,
          label: 'Clear playback history',
          onTap: onClearPlaybackHistory,
          isDestructive: true,
        ),
      ],
    );
  }
}
