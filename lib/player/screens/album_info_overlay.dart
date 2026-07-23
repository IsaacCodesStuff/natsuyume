import 'package:flutter/material.dart';
import '../../widgets/collection_info_overlay.dart';
import '../../widgets/album_grid_item.dart';
import 'metadata_editor_screen.dart';
import '../../core/library_types.dart';

class AlbumInfoOverlay extends StatelessWidget {
  final AlbumData album; // add this line
  final String artistName;
  final String albumArtist;
  final String composer;
  final String lyricist;
  final String genre;
  final int discCount;
  final String duration;

  const AlbumInfoOverlay({
    super.key,
    required this.album,
    this.artistName = '',
    this.albumArtist = '',
    this.composer = 'N/A',
    this.lyricist = 'N/A',
    this.genre = 'N/A',
    this.discCount = 1,
    this.duration = '0:00',
  });

  @override
  Widget build(BuildContext context) {
    return CollectionInfoOverlay(
      name: album.title,
      image: album.coverArt,
      sectionLabel: 'Album Details',
      details: [
        InfoRow(
          label: 'Artist',
          value: artistName.isNotEmpty ? artistName : 'N/A',
        ),
        InfoRow(
          label: 'Album Artist',
          value: albumArtist.isNotEmpty ? albumArtist : 'N/A',
        ),
        InfoRow(label: 'Composer', value: composer),
        InfoRow(label: 'Lyricist', value: lyricist),
        InfoRow(label: 'Genre', value: genre),
        InfoRow(label: 'Track Count', value: '${album.songCount}'),
        InfoRow(label: 'Disc Count', value: '$discCount'),
        InfoRow(label: 'Duration', value: duration),
        InfoRow(label: 'Year', value: '${album.year}'),
      ],
      onEditInfo: () {
        Navigator.of(context).pop();
        // Open multi-song metadata editor for all tracks in album
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => FractionallySizedBox(
            heightFactor: 1.0,
            child: MetadataEditorScreen(
              tracks: List.generate(
                album.songCount,
                (i) => TrackMetadata(
                  album: album.title,
                  artist: artistName,
                  albumArtist: albumArtist,
                  composer: composer == 'N/A' ? '' : composer,
                  genre: genre == 'N/A' ? '' : genre,
                  lyricist: lyricist == 'N/A' ? '' : lyricist,
                  year: '${album.year}',
                  albumArt: album.coverArt,
                ),
              ),
            ),
          ),
        );
      },
      onSaveImage: () {
        // Save album art to gallery — wired in 0.8.x
      },
    );
  }
}
