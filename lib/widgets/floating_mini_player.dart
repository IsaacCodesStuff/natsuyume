import 'package:flutter/material.dart';
import '../theme/natsuyume_theme.dart';
import '../core/natsuyume_core.dart';
import '../core/cover_service.dart';
import '../player/screens/now_playing_screen.dart';
import '../widgets/now_playing_bar.dart';

class FloatingMiniPlayer extends StatelessWidget {
  final double bottomOffset;

  const FloatingMiniPlayer({super.key, this.bottomOffset = 0});

  static const double height = 72.0;
  static const double horizontalMargin = 16.0;
  static const double gap = 12.0;

  void _openNowPlaying(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FractionallySizedBox(
        heightFactor: 1.0,
        child: NowPlayingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = NatsuyumeTheme.of(context).colors;
    final core = NatsuyumeCore.instance;

    return Positioned(
      left: horizontalMargin,
      right: horizontalMargin,
      bottom: gap + bottomOffset,
      child: ListenableBuilder(
        listenable: core.playerState,
        builder: (context, _) {
          final track = core.playerState.currentTrack;
          final isPlaying = core.playerState.isPlaying;

          ImageProvider? albumArt;
          if (!track.isEmpty) {
            final bytes = CoverService.instance.getCoverForTrack(track.path);
            if (bytes != null) albumArt = MemoryImage(bytes);
          }

          return AnimatedSlide(
            offset: track.isEmpty ? const Offset(0, 1.5) : Offset.zero,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              opacity: track.isEmpty ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: track.isEmpty,
                child: track.isEmpty
                    ? const SizedBox(height: height)
                    : _buildContent(
                        context,
                        colors,
                        core,
                        track,
                        isPlaying,
                        albumArt,
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    NatsuyumeColorScheme colors,
    NatsuyumeCore core,
    CoreTrack track,
    bool isPlaying,
    ImageProvider? albumArt,
  ) {
    return GestureDetector(
      onTap: () => _openNowPlaying(context),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Material(
            type: MaterialType.transparency,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  // Album art
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: albumArt != null
                        ? Image(
                            image: albumArt,
                            width: 46,
                            height: 46,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 46,
                            height: 46,
                            color: colors.surfaceVariant,
                            child: Icon(
                              Icons.music_note,
                              size: 22,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  // Track info
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.title.isEmpty ? 'Unknown Title' : track.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          track.artist.isEmpty
                              ? 'Unknown Artist'
                              : track.artist,
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
                  // Now playing indicator
                  if (isPlaying)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: NowPlayingBars(
                        color: colors.accent,
                        isPlaying: isPlaying,
                        barWidth: 3,
                        maxHeight: 16,
                      ),
                    ),
                  // Previous
                  IconButton(
                    onPressed: core.previous,
                    icon: Icon(
                      Icons.skip_previous,
                      color: colors.onSurface,
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                  // Play/pause
                  IconButton(
                    onPressed: () => isPlaying ? core.pause() : core.play(),
                    icon: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: colors.onSurface,
                      size: 26,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                  // Next
                  IconButton(
                    onPressed: core.next,
                    icon: Icon(
                      Icons.skip_next,
                      color: colors.onSurface,
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
