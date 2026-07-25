import 'package:flutter/material.dart';
import '../theme/natsuyume_theme.dart';
import '../core/natsuyume_core.dart';
import '../core/cover_service.dart';
import 'mini_player.dart';
import '../player/screens/now_playing_screen.dart';

class FloatingMiniPlayer extends StatelessWidget {
  /// Extra bottom offset — pass the height of any bottom bar in the
  /// parent screen (e.g. nav bar height) so the player floats above it.
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
                child: Container(
                  height: height,
                  decoration: track.isEmpty
                      ? null // no decoration when hidden — eliminates shadow
                      : BoxDecoration(
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
                  child: track.isEmpty
                      ? null // no child when hidden
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: MiniPlayer(
                            data: MiniPlayerData(
                              title: track.title,
                              artist: track.artist,
                              album: track.album,
                              albumArt: albumArt,
                              isPlaying: isPlaying,
                              isFavorite: track.isFavorite,
                            ),
                            onTap: () => _openNowPlaying(context),
                            onPlayPause: () {
                              if (isPlaying) {
                                core.pause();
                              } else {
                                core.play();
                              }
                            },
                            onPrevious: core.previous,
                            onNext: core.next,
                            onFavorite: () {},
                          ),
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
