import 'package:flutter/material.dart';
import '../../widgets/collection_info_overlay.dart';
import 'playlists_screen.dart';
import 'playlist_editor_screen.dart';

class PlaylistInfoOverlay extends StatelessWidget {
  final PlaylistData playlist;
  final String totalDuration;
  final String description;

  const PlaylistInfoOverlay({
    super.key,
    required this.playlist,
    this.totalDuration = '0:00',
    this.description = '',
  });

  @override
  Widget build(BuildContext context) {
    return CollectionInfoOverlay(
      name: playlist.name,
      image: playlist.coverArt,
      sectionLabel: 'Playlist Description',
      description: description,
      details: [
        InfoRow(label: 'Total Tracks', value: '${playlist.songCount}'),
        InfoRow(label: 'Total Duration', value: totalDuration),
      ],
      onEditInfo: () {
        Navigator.of(context).pop();
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => FractionallySizedBox(
            heightFactor: 1.0,
            child: PlaylistEditorScreen(
              initialName: playlist.name,
              initialDescription: description,
              initialImage: playlist.coverArt,
            ),
          ),
        );
      },
      onSaveImage: () {
        // Save image to gallery — wired in 0.8.x
      },
    );
  }
}
