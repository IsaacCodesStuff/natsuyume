import 'package:flutter/material.dart';
import '../../../widgets/context_menu.dart';
import '../../../widgets/album_grid_item.dart';
import '../album_detail_screen.dart';
import '../metadata_editor_screen.dart';

class AlbumTabContextMenu {
  static Future<void> show(
    BuildContext context, {
    required AlbumData album,
    required VoidCallback onPlayAfterCurrent,
    required VoidCallback onAddToCurrentQueue,
    required VoidCallback onAddToQueue,
    required VoidCallback onAddToPlaylists,
    required VoidCallback onSelectAllSongs,
  }) {
    return ContextMenuSheet.show(
      context,
      header: CollectionContextHeader(
        name: album.title,
        subtitle: album.subtitle,
      ),
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
                  tracks: List.generate(
                    album.songCount,
                    (_) => TrackMetadata(
                      album: album.title,
                      artist: album.artist,
                      year: '${album.year}',
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        ContextMenuOption(
          icon: Icons.select_all,
          label: 'Select all songs of this album',
          onTap: onSelectAllSongs,
        ),
      ],
    );
  }
}
