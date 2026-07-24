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
                          ? LyricsView(
                              key: ValueKey(track.path),
                              trackPath: track.path,
                              positionMs: posMs,
                              colors: colors,
                            )
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
            onChanged: (v) {
              // Update displayed time while dragging without notifying core
              setState(() {
                _isSeeking = true;
                _seekValue = v;
              });
            },
            onChangeStart: (_) => setState(() => _isSeeking = true),
            onChangeEnd: (v) {
              // v is now the actual final drag position from the slider
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
                  // Show scrub position while dragging
                  _isSeeking
                      ? formatMs((_seekValue * durMs).round())
                      : formatMs(posMs),
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

// ---------------------------------------------------------------------------
// LyricsView — self-contained widget, manages its own scroll and active line
// ---------------------------------------------------------------------------

class LyricsView extends StatefulWidget {
  final String trackPath;
  final int positionMs;
  final NatsuyumeColorScheme colors;

  const LyricsView({
    super.key,
    required this.trackPath,
    required this.positionMs,
    required this.colors,
  });

  @override
  State<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<LyricsView> {
  final ScrollController _scrollController = ScrollController();
  List<_LrcLine> _lines = [];
  int _activeIndex = -1;
  bool _userScrolling = false;
  String _plainLyrics = '';
  bool _isSynced = false;

  // Height per lyric line — used to compute scroll offset
  static const double _lineHeight = 56.0;
  // How long to wait after user scroll before resuming auto-scroll
  static const Duration _resumeDelay = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _loadLyrics();
  }

  void _loadLyrics() {
    if (widget.trackPath.isEmpty) return;
    final raw = NatsuyumeCore.instance.getLyrics(widget.trackPath);
    if (raw.isEmpty) {
      setState(() {
        _lines = [];
        _plainLyrics = '';
        _isSynced = false;
      });
      return;
    }

    // Detect synced vs unsynced
    final hasTimestamp = RegExp(r'\[\d{1,3}:\d{2}').hasMatch(raw);
    if (hasTimestamp) {
      setState(() {
        _lines = _parseLrc(raw);
        _plainLyrics = '';
        _isSynced = true;
      });
    } else {
      setState(() {
        _lines = [];
        _plainLyrics = raw.trim();
        _isSynced = false;
      });
    }
  }

  // Dart-side LRC parser — mirrors the C++ LrcParser logic
  List<_LrcLine> _parseLrc(String lrc) {
    final timestampRe = RegExp(r'\[(\d{1,3}):(\d{2})[.:](\d{1,3})\]');
    final metaRe = RegExp(r'\[[a-z]+:.*?\]');
    final result = <_LrcLine>[];

    for (final rawLine in lrc.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      final matches = timestampRe.allMatches(line).toList();
      if (matches.isEmpty) continue;

      // Strip timestamps and meta tags to get lyric text
      String text = line
          .replaceAll(timestampRe, '')
          .replaceAll(metaRe, '')
          .trim();

      for (final m in matches) {
        final mins = int.parse(m.group(1)!);
        final secs = int.parse(m.group(2)!);
        final csStr = m.group(3)!;
        int ms = int.parse(csStr);
        if (csStr.length <= 2) ms *= 10; // centiseconds → ms
        final timestamp = mins * 60000 + secs * 1000 + ms;
        result.add(_LrcLine(timestamp: timestamp, text: text));
      }
    }

    result.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return result;
  }

  int _findActiveIndex(int posMs) {
    if (_lines.isEmpty) return -1;
    int lo = 0, hi = _lines.length - 1, result = -1;
    while (lo <= hi) {
      final mid = (lo + hi) ~/ 2;
      if (_lines[mid].timestamp <= posMs) {
        result = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return result;
  }

  void _scrollToActive(int index) {
    if (!_scrollController.hasClients) return;
    if (_userScrolling) return;
    if (index < 0) return;

    final viewportHeight = _scrollController.position.viewportDimension;
    // Target: active line centered in viewport
    final targetOffset =
        (index * _lineHeight) - (viewportHeight / 2) + (_lineHeight / 2);
    final clampedOffset = targetOffset.clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    _scrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void didUpdateWidget(LyricsView old) {
    super.didUpdateWidget(old);

    // Track changed — reload lyrics
    if (old.trackPath != widget.trackPath) {
      _loadLyrics();
      _activeIndex = -1;
      return;
    }

    // Position changed — find active line and scroll
    final newIndex = _findActiveIndex(widget.positionMs);
    if (newIndex != _activeIndex) {
      setState(() => _activeIndex = newIndex);
      _scrollToActive(newIndex);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;

    // No lyrics at all
    if (_lines.isEmpty && _plainLyrics.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lyrics_outlined,
              size: 48,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'No lyrics available',
              style: TextStyle(fontSize: 15, color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 6),
            Text(
              'Add an .lrc file or embed lyrics in the track',
              style: TextStyle(
                fontSize: 12,
                color: colors.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    // Unsynced plain text
    if (!_isSynced && _plainLyrics.isNotEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
        child: Text(
          _plainLyrics,
          style: TextStyle(
            fontSize: 16,
            color: colors.onSurfaceVariant,
            height: 1.8,
          ),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollStartNotification &&
            notification.dragDetails != null) {
          // User initiated scroll — pause auto-scroll
          _userScrolling = true;
        } else if (notification is ScrollEndNotification) {
          // Resume auto-scroll after delay
          Future.delayed(_resumeDelay, () {
            if (mounted) _userScrolling = false;
          });
        }
        return false;
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
        itemCount: _lines.length,
        itemExtent: _lineHeight,
        itemBuilder: (context, index) {
          final line = _lines[index];
          final isActive = index == _activeIndex;
          final isPast = index < _activeIndex;

          return GestureDetector(
            onTap: () {
              NatsuyumeCore.instance.seekTo(line.timestamp);
            },
            child: Container(
              height: _lineHeight,
              alignment: Alignment.centerLeft,
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: isActive ? 20 : 16,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  color: isActive
                      ? colors.onBackground
                      : isPast
                      ? colors.onSurfaceVariant.withValues(alpha: 0.5)
                      : colors.onSurfaceVariant,
                  height: 1.3,
                ),
                child: Text(
                  line.text.isEmpty ? '♪' : line.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data + private widgets
// ---------------------------------------------------------------------------

class _LrcLine {
  final int timestamp;
  final String text;
  const _LrcLine({required this.timestamp, required this.text});
}

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
