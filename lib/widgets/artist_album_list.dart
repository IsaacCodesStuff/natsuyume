import 'package:flutter/material.dart';
import '../theme/natsuyume_theme.dart';
import 'album_grid_item.dart';

class ArtistAlbumEntry {
  final String title;
  final int year;
  final int songCount;
  final ImageProvider? coverArt;

  const ArtistAlbumEntry({
    required this.title,
    required this.year,
    required this.songCount,
    this.coverArt,
  });

  String get subtitle => '$year · $songCount songs';
}

class ArtistAlbumList extends StatelessWidget {
  final String allSongsLabel;
  final int allSongsCount;
  final List<ArtistAlbumEntry> albums;
  final int? currentAlbumIndex;
  final VoidCallback onAllSongsTap;
  final void Function(int index) onAlbumTap;
  final void Function(int index) onAlbumMoreTap;
  final VoidCallback onAllSongsMoreTap;

  const ArtistAlbumList({
    super.key,
    required this.allSongsLabel,
    required this.allSongsCount,
    required this.albums,
    required this.currentAlbumIndex,
    required this.onAllSongsTap,
    required this.onAlbumTap,
    required this.onAlbumMoreTap,
    required this.onAllSongsMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = NatsuyumeTheme.of(context).colors;

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          // First item is always "All songs"
          if (index == 0) {
            return _buildAllSongsRow(colors);
          }

          final albumIndex = index - 1;
          final album = albums[albumIndex];
          final isPlaying = albumIndex == currentAlbumIndex;

          return GestureDetector(
            onTap: () => onAlbumTap(albumIndex),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isPlaying
                    ? colors.accent.withOpacity(0.15)
                    : colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: isPlaying
                    ? Border.all(
                        color: colors.accent.withOpacity(0.3),
                        width: 1,
                      )
                    : null,
              ),
              child: Row(
                children: [
                  // Cover art
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: album.coverArt != null
                        ? Image(
                            image: album.coverArt!,
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 52,
                            height: 52,
                            color: colors.surfaceVariant,
                            child: Icon(
                              Icons.album,
                              size: 26,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          album.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isPlaying ? colors.accent : colors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          album.subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // More
                  GestureDetector(
                    onTap: () => onAlbumMoreTap(albumIndex),
                    child: Icon(
                      Icons.more_vert,
                      size: 20,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        childCount: albums.length + 1, // +1 for "All songs" header
      ),
    );
  }

  Widget _buildAllSongsRow(NatsuyumeColorScheme colors) {
    return GestureDetector(
      onTap: onAllSongsTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    allSongsLabel,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$allSongsCount songs',
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onAllSongsMoreTap,
              child: Icon(
                Icons.more_vert,
                size: 20,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
