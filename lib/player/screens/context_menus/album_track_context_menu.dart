import 'package:flutter/material.dart';
import '../../../widgets/context_menu.dart';
import '../../../widgets/album_track_list.dart';
import '../metadata_editor_screen.dart';

class AlbumTrackContextMenu {
  static Future<void> show(
    BuildContext context, {
    required CollectionTrack track,
    required bool isFavorite,
    required VoidCallback onFavoriteTap,
    required VoidCallback onSongInfo,
    required VoidCallback onPlayAfterCurrent,
    required VoidCallback onAddToCurrentQueue,
    required VoidCallback onAddToQueue,
    required VoidCallback onAddToPlaylists,
  }) {
    return ContextMenuSheet.show(
      context,
      header: TrackContextHeader(
        trackName: track.title,
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
          icon: Icons.edit_outlined,
          label: 'Edit album info',
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => FractionallySizedBox(
                heightFactor: 1.0,
                child: MetadataEditorScreen(
                  tracks: [
                    TrackMetadata(title: track.title, artist: track.artist),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
