import 'package:flutter/material.dart';
import '../theme/natsuyume_theme.dart';

class MiniPlayerData {
  final String title;
  final String artist;
  final String album;
  final ImageProvider? albumArt;
  final bool isPlaying;
  final bool isFavorite;

  const MiniPlayerData({
    required this.title,
    required this.artist,
    required this.album,
    this.albumArt,
    required this.isPlaying,
    required this.isFavorite,
  });
}

class MiniPlayer extends StatelessWidget {
  final MiniPlayerData data;
  final VoidCallback onTap;
  final VoidCallback onPlayPause;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onFavorite;

  const MiniPlayer({
    super.key,
    required this.data,
    required this.onTap,
    required this.onPlayPause,
    required this.onPrevious,
    required this.onNext,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final colors = NatsuyumeTheme.of(context).colors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: colors.surface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(height: 1, color: colors.divider),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // Album art
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: data.albumArt != null
                        ? Image(
                            image: data.albumArt!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 48,
                            height: 48,
                            color: colors.surfaceVariant,
                            child: Icon(
                              Icons.music_note,
                              color: colors.onSurfaceVariant,
                              size: 24,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  // Track info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          data.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          data.artist,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          data.album,
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
                  // Controls
                  IconButton(
                    onPressed: onFavorite,
                    icon: Icon(
                      data.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: data.isFavorite
                          ? colors.accent
                          : colors.onSurfaceVariant,
                      size: 22,
                    ),
                  ),
                  IconButton(
                    onPressed: onPrevious,
                    icon: Icon(
                      Icons.skip_previous,
                      color: colors.onSurface,
                      size: 22,
                    ),
                  ),
                  IconButton(
                    onPressed: onPlayPause,
                    icon: Icon(
                      data.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: colors.onSurface,
                      size: 26,
                    ),
                  ),
                  IconButton(
                    onPressed: onNext,
                    icon: Icon(
                      Icons.skip_next,
                      color: colors.onSurface,
                      size: 22,
                    ),
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
