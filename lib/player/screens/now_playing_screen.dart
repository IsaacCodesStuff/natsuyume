import 'package:flutter/material.dart';
import '../../theme/natsuyume_theme.dart';
import '../../core/natsuyume_core.dart';
import '../../widgets/now_playing_bar.dart';
import '../../widgets/squiggly_slider.dart';
import 'lyrics_editor_screen.dart';
import 'dart:ui';
import 'dart:typed_data';
import '../../core/cover_service.dart';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  bool _showLyrics = false;
  bool _isSeeking = false;
  double _seekValue = 0.0;

  @override
  Widget build(BuildContext context) {
    final colors = NatsuyumeTheme.of(context).colors;
    final core = NatsuyumeCore.instance;

    return ListenableBuilder(
      listenable: core.playerState,
      builder: (context, _) {
        final track = core.playerState.currentTrack;
        final isPlaying = core.playerState.isPlaying;
        final posMs = core.playerState.positionMs;
        final durMs = core.playerState.durationMs;

        final seekValue = _isSeeking
            ? _seekValue
            : (durMs > 0 ? (posMs / durMs).clamp(0.0, 1.0) : 0.0);

        String formatMs(int ms) {
          final totalSec = ms ~/ 1000;
          final m = totalSec ~/ 60;
          final s = totalSec % 60;
          return '$m:${s.toString().padLeft(2, '0')}';
        }

        return Scaffold(
          backgroundColor: colors.background,
          body: Stack(
            children: [
              _buildBackground(colors),
              SafeArea(
                child: Column(
                  children: [
                    _buildTopBar(colors, track),
                    Expanded(
                      child: _showLyrics
                          ? _buildLyricsView(colors)
                          : _buildNormalView(colors, track),
                    ),
                    _buildControlRow(colors, core, track, isPlaying),
                    _buildSeekBar(
                      colors,
                      core,
                      seekValue,
                      posMs,
                      durMs,
                      isPlaying,
                      formatMs,
                    ),
                    _buildPlaybackButtons(colors, core, isPlaying),
                    _buildUpNextPill(colors, isPlaying),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBackground(NatsuyumeColorScheme colors) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: _showLyrics
          ? _BlurredBackground(key: const ValueKey('blurred'), colors: colors)
          : SizedBox.expand(
              key: const ValueKey('normal'),
              child: Container(color: colors.background),
            ),
    );
  }

  Widget _buildTopBar(NatsuyumeColorScheme colors, CoreTrack track) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Icon(
              Icons.keyboard_arrow_down,
              size: 28,
              color: colors.onSurface,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Now Playing',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                Text(
                  track.album.isEmpty ? '—' : track.album,
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
          if (_showLyrics) ...[
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => FractionallySizedBox(
                    heightFactor: 1.0,
                    child: LyricsEditorScreen(),
                  ),
                );
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: colors.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          GestureDetector(
            onTap: () => setState(() => _showLyrics = !_showLyrics),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _showLyrics
                    ? colors.accent.withValues(alpha: 0.2)
                    : colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: _showLyrics
                    ? Border.all(color: colors.accent.withValues(alpha: 0.4))
                    : null,
              ),
              child: Icon(
                Icons.text_fields,
                size: 20,
                color: _showLyrics ? colors.accent : colors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNormalView(NatsuyumeColorScheme colors, CoreTrack track) {
    final Uint8List? coverBytes = track.isEmpty
        ? null
        : CoverService.instance.getCoverForTrack(track.path);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: coverBytes != null
                  ? Image(image: MemoryImage(coverBytes), fit: BoxFit.cover)
                  : Container(
                      color: colors.surfaceVariant,
                      child: Icon(
                        Icons.album,
                        size: 80,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            track.isEmpty ? 'Not playing' : track.title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: colors.onBackground,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          track.album.isEmpty ? '—' : track.album,
          style: TextStyle(fontSize: 15, color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        Text(
          track.artist.isEmpty ? '—' : track.artist,
          style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildLyricsView(NatsuyumeColorScheme colors) {
    return Center(
      child: Text(
        'Lyrics not yet wired',
        style: TextStyle(color: colors.onSurfaceVariant),
      ),
    );
  }

  Widget _buildControlRow(
    NatsuyumeColorScheme colors,
    NatsuyumeCore core,
    CoreTrack track,
    bool isPlaying,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ControlIcon(
            icon: Icons.shuffle,
            active: false,
            colors: colors,
            onTap: () {},
          ),
          _ControlIcon(
            icon: Icons.repeat,
            active: false,
            colors: colors,
            onTap: () {},
          ),
          GestureDetector(
            onTap: () {},
            child: Icon(
              Icons.favorite_border,
              size: 32,
              color: colors.onSurface,
            ),
          ),
          _ControlIcon(
            icon: Icons.playlist_add,
            active: false,
            colors: colors,
            onTap: () {},
          ),
          _ControlIcon(
            icon: Icons.equalizer,
            active: false,
            colors: colors,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSeekBar(
    NatsuyumeColorScheme colors,
    NatsuyumeCore core,
    double seekValue,
    int posMs,
    int durMs,
    bool isPlaying,
    String Function(int) formatMs,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          M3ESquigglySlider(
            value: seekValue,
            isPlaying: isPlaying,
            onChanged: (v) => setState(() {
              _isSeeking = true;
              _seekValue = v;
            }),
            onChangeStart: (_) => setState(() => _isSeeking = true),
            onChangeEnd: (v) {
              final seekMs = (v * durMs).round();
              NatsuyumeCore.instance.seekTo(seekMs);
              setState(() => _isSeeking = false);
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatMs(posMs),
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                Text(
                  formatMs(durMs),
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybackButtons(
    NatsuyumeColorScheme colors,
    NatsuyumeCore core,
    bool isPlaying,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _PlaybackButton(
            icon: Icons.skip_previous,
            colors: colors,
            onTap: core.previous,
          ),
          _PlaybackButton(
            icon: Icons.fast_rewind,
            colors: colors,
            onTap: () => core.seekTo(
              (core.playerState.positionMs - 10000).clamp(
                0,
                core.playerState.durationMs,
              ),
            ),
          ),
          _PlaybackButton(
            icon: isPlaying ? Icons.pause : Icons.play_arrow,
            colors: colors,
            large: true,
            onTap: () => isPlaying ? core.pause() : core.play(),
          ),
          _PlaybackButton(
            icon: Icons.fast_forward,
            colors: colors,
            onTap: () => core.seekTo(
              (core.playerState.positionMs + 10000).clamp(
                0,
                core.playerState.durationMs,
              ),
            ),
          ),
          _PlaybackButton(
            icon: Icons.skip_next,
            colors: colors,
            onTap: core.next,
          ),
        ],
      ),
    );
  }

  Widget _buildUpNextPill(NatsuyumeColorScheme colors, bool isPlaying) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Up next',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '—',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: colors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  NowPlayingBars(
                    color: colors.accent,
                    isPlaying: isPlaying,
                    barWidth: 3,
                    maxHeight: 18,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.info_outline,
              color: colors.onSurfaceVariant,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

// Unchanged widget classes below — keep your existing ones
class _BlurredBackground extends StatelessWidget {
  final NatsuyumeColorScheme colors;

  const _BlurredBackground({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.accent.withValues(alpha: 0.8),
                  colors.background,
                ],
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(color: colors.background.withValues(alpha: 0.55)),
          ),
        ],
      ),
    );
  }
}

class _LyricLine {
  final String text;
  final bool isCurrent;
  final bool isPast;

  const _LyricLine({
    required this.text,
    required this.isCurrent,
    required this.isPast,
  });
}

class _ControlIcon extends StatelessWidget {
  final IconData icon;
  final bool active;
  final NatsuyumeColorScheme colors;
  final VoidCallback onTap;

  const _ControlIcon({
    required this.icon,
    required this.active,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        icon,
        size: 26,
        color: active ? colors.accent : colors.onSurface,
      ),
    );
  }
}

class _PlaybackButton extends StatelessWidget {
  final IconData icon;
  final NatsuyumeColorScheme colors;
  final bool large;
  final VoidCallback onTap;

  const _PlaybackButton({
    required this.icon,
    required this.colors,
    this.large = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = large ? 64.0 : 48.0;
    final iconSize = large ? 32.0 : 22.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: large ? colors.accent : colors.surface,
          borderRadius: BorderRadius.circular(large ? 20 : 14),
        ),
        child: Icon(
          icon,
          size: iconSize,
          color: large ? colors.background : colors.onSurface,
        ),
      ),
    );
  }
}
