import 'package:flutter/material.dart';
import '../theme/natsuyume_theme.dart';

class AlbumData {
  final String title;
  final String artist;
  final int year;
  final int songCount;
  final ImageProvider? coverArt;

  const AlbumData({
    required this.title,
    required this.artist,
    required this.year,
    required this.songCount,
    this.coverArt,
  });

  String get subtitle => '$artist · $year · $songCount songs';
}

class AlbumGridItem extends StatelessWidget {
  final AlbumData album;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const AlbumGridItem({
    super.key,
    required this.album,
    required this.isPlaying,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final colors = NatsuyumeTheme.of(context).colors;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isPlaying
              ? colors.accent.withValues(alpha: 0.15)
              : colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: isPlaying
              ? Border.all(
                  color: colors.accent.withValues(alpha: 0.3),
                  width: 1,
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover art
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: album.coverArt != null
                    ? Image(image: album.coverArt!, fit: BoxFit.cover)
                    : Container(
                        color: colors.surfaceVariant,
                        child: Icon(
                          Icons.album,
                          size: 48,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isPlaying ? colors.accent : colors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    album.subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
