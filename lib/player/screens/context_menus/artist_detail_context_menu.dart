import 'package:flutter/material.dart';
import '../../../widgets/context_menu.dart';
import '../artists_screen.dart';
import '../artist_editor_screen.dart';
import '../metadata_editor_screen.dart';
import '../../../core/library_types.dart';

class ArtistDetailContextMenu {
  static Future<void> show(
    BuildContext context, {
    required ArtistData artist,
    required VoidCallback onPlayAfterCurrent,
    required VoidCallback onAddToCurrentQueue,
    required VoidCallback onAddToQueue,
    required VoidCallback onAddToPlaylists,
    required VoidCallback onSelectMultiple,
  }) {
    return ContextMenuSheet.show(
      context,
      header: CollectionContextHeader(
        name: artist.name,
        subtitle: artist.subtitle,
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
          icon: Icons.person_outline,
          label: 'Edit artist profile',
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => FractionallySizedBox(
                heightFactor: 1.0,
                child: ArtistEditorScreen(
                  initialName: artist.name,
                  initialImage: artist.photo,
                ),
              ),
            );
          },
        ),
        ContextMenuOption(
          icon: Icons.edit_outlined,
          label: 'Edit artist info',
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => FractionallySizedBox(
                heightFactor: 1.0,
                child: MetadataEditorScreen(
                  tracks: List.generate(
                    artist.albumCount,
                    (_) => TrackMetadata(artist: artist.name),
                  ),
                ),
              ),
            );
          },
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
