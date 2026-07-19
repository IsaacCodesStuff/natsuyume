import 'package:flutter/material.dart';
import '../theme/natsuyume_theme.dart';

class PlaylistTrack {
  final String title;
  final String artist;
  final String album;
  final String duration;
  final ImageProvider? albumArt;

  const PlaylistTrack({
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    this.albumArt,
  });
}

class PlaylistTrackList extends StatelessWidget {
  final List<PlaylistTrack> tracks;
  final int currentTrackIndex;
  final void Function(int index) onTrackTap;
  final void Function(int index) onMoreTap;

  const PlaylistTrackList({
    super.key,
    required this.tracks,
    required this.currentTrackIndex,
    required this.onTrackTap,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = NatsuyumeTheme.of(context).colors;

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final track = tracks[index];
        final isPlaying = index == currentTrackIndex;

        return GestureDetector(
          onTap: () => onTrackTap(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isPlaying
                  ? colors.accent.withValues(alpha: 0.15)
                  : colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: isPlaying
                  ? Border.all(
                      color: colors.accent.withValues(alpha: 0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                // Index or equalizer
                SizedBox(
                  width: 24,
                  child: isPlaying
                      ? _EqualizerIcon(color: colors.accent)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                ),
                const SizedBox(width: 10),
                // Album art
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: track.albumArt != null
                      ? Image(
                          image: track.albumArt!,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 44,
                          height: 44,
                          color: colors.surfaceVariant,
                          child: Icon(
                            Icons.music_note,
                            size: 20,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                // Track info — title, artist, album
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        track.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isPlaying ? colors.accent : colors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        track.artist,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        track.album,
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
                // Duration
                Text(
                  track.duration,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                // More
                GestureDetector(
                  onTap: () => onMoreTap(index),
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
      }, childCount: tracks.length),
    );
  }
}

class _EqualizerIcon extends StatelessWidget {
  final Color color;

  const _EqualizerIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _Bar(height: 8, color: color),
        const SizedBox(width: 2),
        _Bar(height: 14, color: color),
        const SizedBox(width: 2),
        _Bar(height: 10, color: color),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  final double height;
  final Color color;

  const _Bar({required this.height, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
