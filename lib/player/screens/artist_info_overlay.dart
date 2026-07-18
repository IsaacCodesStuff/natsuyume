import 'package:flutter/material.dart';
import '../../widgets/collection_info_overlay.dart';
import 'artists_screen.dart';
import 'artist_editor_screen.dart';

class ArtistInfoOverlay extends StatelessWidget {
  final ArtistData artist;

  // Placeholder stats — wired to userdata.db in 0.8.x
  final int totalAlbums;
  final int totalTracks;
  final String totalDuration;
  final String description;

  const ArtistInfoOverlay({
    super.key,
    required this.artist,
    this.totalAlbums = 0,
    this.totalTracks = 0,
    this.totalDuration = '0:00',
    this.description = '',
  });

  @override
  Widget build(BuildContext context) {
    return CollectionInfoOverlay(
      name: artist.name,
      image: artist.photo,
      sectionLabel: 'Artist Description',
      description: description,
      details: [
        InfoRow(label: 'Total Albums', value: '$totalAlbums'),
        InfoRow(label: 'Total Tracks', value: '$totalTracks'),
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
            child: ArtistEditorScreen(
              initialName: artist.name,
              initialDescription: description,
              initialImage: artist.photo,
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
