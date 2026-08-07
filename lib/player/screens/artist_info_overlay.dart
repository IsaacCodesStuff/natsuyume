import 'package:flutter/material.dart';
import '../../widgets/collection_info_overlay.dart';
import 'artist_editor_screen.dart';
import '../../core/library_types.dart';

class ArtistInfoOverlay extends StatelessWidget {
  final ArtistData artist; // add this line
  final int totalAlbums;
  final int totalTracks;
  final String totalDuration;
  final String description;
  final ImageProvider? customImage;
  final VoidCallback? onSaved;

  const ArtistInfoOverlay({
    super.key,
    required this.artist,
    this.totalAlbums = 0,
    this.totalTracks = 0,
    this.totalDuration = '0:00',
    this.description = '',
    this.customImage,
    this.onSaved,
  });

  @override
  Widget build(BuildContext context) {
    return CollectionInfoOverlay(
      name: artist.name,
      image: customImage ?? artist.photo,
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
              initialImage: customImage ?? artist.photo,
            ),
          ),
        ).then((_) => onSaved?.call());
      },
      onSaveImage: () {
        // Save image to gallery — wired in 0.8.x
      },
    );
  }
}
