import 'package:flutter/material.dart';
import '../../../widgets/context_menu.dart';
import '../playlists_screen.dart';
import '../playlist_editor_screen.dart';
import '../metadata_editor_screen.dart';
import '../playlist_organizer_screen.dart';

class PlaylistDetailContextMenu {
  static Future<void> show(
    BuildContext context, {
    required PlaylistData playlist,
    required VoidCallback onExportM3U,
    required VoidCallback onRenamePlaylist,
    required VoidCallback onRemovePlaylist,
    required VoidCallback onPlayAfterCurrent,
    required VoidCallback onAddToCurrentQueue,
    required VoidCallback onAddToQueue,
    required VoidCallback onAddToPlaylists,
    required VoidCallback onSelectMultiple,
    required VoidCallback onOrganizeSongs,
  }) {
    return ContextMenuSheet.show(
      context,
      header: CollectionContextHeader(
        name: playlist.name,
        subtitle: playlist.subtitle,
      ),
      options: [
        ContextMenuOption(
          icon: Icons.file_upload_outlined,
          label: 'Export as .M3U file',
          onTap: onExportM3U,
        ),
        ContextMenuOption(
          icon: Icons.drive_file_rename_outline,
          label: 'Rename playlist',
          onTap: onRenamePlaylist,
        ),
        ContextMenuOption(
          icon: Icons.delete_outline,
          label: 'Remove playlist',
          onTap: onRemovePlaylist,
          isDestructive: true,
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
          icon: Icons.image_outlined,
          label: 'Edit playlist profile',
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => FractionallySizedBox(
                heightFactor: 1.0,
                child: PlaylistEditorScreen(
                  initialName: playlist.name,
                  initialImage: playlist.coverArt,
                ),
              ),
            );
          },
        ),
        ContextMenuOption(
          icon: Icons.edit_outlined,
          label: 'Edit playlist info',
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => FractionallySizedBox(
                heightFactor: 1.0,
                child: MetadataEditorScreen(
                  tracks: List.generate(
                    playlist.songCount,
                    (_) => TrackMetadata(),
                  ),
                ),
              ),
            );
          },
        ),
        ContextMenuOption(
          icon: Icons.sort,
          label: 'Organize songs',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PlaylistOrganizerScreen(
                  playlistName: playlist.name,
                  tracks: const [],
                  // Real tracks wired in 0.8.x
                ),
              ),
            );
          },
        ),
        ContextMenuOption(
          icon: Icons.sort,
          label: 'Organize songs',
          onTap: onOrganizeSongs,
        ),
        ContextMenuOption(
          icon: Icons.checklist,
          label: 'Select multiple',
          onTap: onSelectMultiple,
        ),
      ],
    );
  }
}
