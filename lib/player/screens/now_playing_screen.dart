import 'package:flutter/material.dart';
import '../../theme/natsuyume_theme.dart';
import '../../widgets/now_playing_bar.dart';
import '../../widgets/squiggly_slider.dart';
import 'lyrics_editor_screen.dart';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  bool _showLyrics = false;
  bool _isPlaying = true;
  bool _isFavorite = false;
  bool _isShuffle = false;
  bool _isRepeat = false;
  double _seekValue = 0.5;

  // Placeholder lyrics
  final List<_LyricLine> _lyrics = const [
    _LyricLine(text: 'パパパパパラアドレナレナ', isCurrent: false, isPast: true),
    _LyricLine(text: 'パパパララパラアドレナレナ', isCurrent: false, isPast: true),
    _LyricLine(
      text: 'さあ何回でも imagine, imagine',
      isCurrent: false,
      isPast: false,
    ),
    _LyricLine(
      text: '君に伝えたいのは？Loving you, もう答えは出でる',
      isCurrent: false,
      isPast: false,
    ),
    _LyricLine(
      text: 'そう恋も愛も liberty, liberty',
      isCurrent: false,
      isPast: false,
    ),
    _LyricLine(
      text: '今にも溢れそうな love in me, 白黒つけるの',
      isCurrent: false,
      isPast: false,
    ),
    _LyricLine(
      text: 'Yes or no, don\'t stop the heart',
      isCurrent: true,
      isPast: false,
    ),
    _LyricLine(
      text: 'Yes or no, don\'t stop the feeling',
      isCurrent: false,
      isPast: false,
    ),
    _LyricLine(
      text: 'Yes or no, don\'t stop the rush',
      isCurrent: false,
      isPast: false,
    ),
    _LyricLine(
      text: 'Yes or no, don\'t stop the love',
      isCurrent: false,
      isPast: false,
    ),
    _LyricLine(text: 'そう 曖昧で未完成な', isCurrent: false, isPast: false),
    _LyricLine(text: 'この想いは 難解で未解明', isCurrent: false, isPast: false),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = NatsuyumeTheme.of(context).colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          // Blurred background (always present, more visible in lyrics mode)
          _buildBackground(colors),
          // Main content
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(colors),
                Expanded(
                  child: _showLyrics
                      ? _buildLyricsView(colors)
                      : _buildNormalView(colors),
                ),
                _buildControlRow(colors),
                _buildSeekBar(colors),
                _buildPlaybackButtons(colors),
                _buildUpNextPill(colors),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(NatsuyumeColorScheme colors) {
    return IgnorePointer(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _showLyrics
            ? SizedBox.expand(
                key: const ValueKey('blurred'),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(color: colors.accent.withValues(alpha: 0.6)),
                    Container(color: colors.background.withValues(alpha: 0.3)),
                  ],
                ),
              )
            : SizedBox.expand(
                key: const ValueKey('normal'),
                child: Container(color: colors.background),
              ),
      ),
    );
  }

  Widget _buildTopBar(NatsuyumeColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          // Dismiss chevron
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Icon(
              Icons.keyboard_arrow_down,
              size: 28,
              color: colors.onSurface,
            ),
          ),
          // Title + subtitle
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
                  'From THE BOOK for,',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Edit button (lyrics mode only)
          if (_showLyrics) ...[
            _TopBarButton(
              icon: Icons.edit_outlined,
              colors: colors,
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const FractionallySizedBox(
                    heightFactor: 1.0,
                    child: LyricsEditorScreen(),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
          // Typography / lyrics toggle
          _TopBarButton(
            icon: Icons.text_fields,
            colors: colors,
            selected: _showLyrics,
            onTap: () => setState(() => _showLyrics = !_showLyrics),
          ),
        ],
      ),
    );
  }

  Widget _buildNormalView(NatsuyumeColorScheme colors) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 24),
        // Album art
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
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
        // Track title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'アドレナ',
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
          'THE BOOK for,',
          style: TextStyle(fontSize: 15, color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        Text(
          'YOASOBI',
          style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildLyricsView(NatsuyumeColorScheme colors) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      itemCount: _lyrics.length,
      itemBuilder: (context, index) {
        final line = _lyrics[index];
        final double fontSize = line.isCurrent ? 22 : 15;
        final Color textColor = line.isCurrent
            ? colors.onBackground
            : line.isPast
            ? colors.onSurfaceVariant.withOpacity(0.5)
            : colors.onSurfaceVariant.withOpacity(0.75);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            line.text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: line.isCurrent ? FontWeight.w700 : FontWeight.w400,
              color: textColor,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  Widget _buildControlRow(NatsuyumeColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Shuffle
          _ControlIcon(
            icon: Icons.shuffle,
            active: _isShuffle,
            colors: colors,
            onTap: () => setState(() => _isShuffle = !_isShuffle),
          ),
          // Repeat
          _ControlIcon(
            icon: Icons.repeat,
            active: _isRepeat,
            colors: colors,
            onTap: () => setState(() => _isRepeat = !_isRepeat),
          ),
          // Favorite (larger)
          GestureDetector(
            onTap: () => setState(() => _isFavorite = !_isFavorite),
            child: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              size: 32,
              color: _isFavorite ? colors.accent : colors.onSurface,
            ),
          ),
          // Add to playlist
          _ControlIcon(
            icon: Icons.playlist_add,
            active: false,
            colors: colors,
            onTap: () {},
          ),
          // Equalizer
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

  Widget _buildSeekBar(NatsuyumeColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          M3ESquigglySlider(
            value: _seekValue,
            isPlaying: _isPlaying,
            onChanged: (v) => setState(() => _seekValue = v),
            onChangeStart: (_) {},
            onChangeEnd: (_) {},
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '1:34',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                Text(
                  '3:07',
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

  Widget _buildPlaybackButtons(NatsuyumeColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _PlaybackButton(
            icon: Icons.skip_previous,
            colors: colors,
            onTap: () {},
          ),
          _PlaybackButton(
            icon: Icons.fast_rewind,
            colors: colors,
            onTap: () {},
          ),
          _PlaybackButton(
            icon: _isPlaying ? Icons.pause : Icons.play_arrow,
            colors: colors,
            large: true,
            onTap: () => setState(() => _isPlaying = !_isPlaying),
          ),
          _PlaybackButton(
            icon: Icons.fast_forward,
            colors: colors,
            onTap: () {},
          ),
          _PlaybackButton(icon: Icons.skip_next, colors: colors, onTap: () {}),
        ],
      ),
    );
  }

  Widget _buildUpNextPill(NatsuyumeColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Up next info pill
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
                          'Up next in THE BOOK for,:',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'UNDEAD - YOASOBI',
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
                    isPlaying: _isPlaying,
                    barWidth: 3,
                    maxHeight: 18,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Info button
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

class _TopBarButton extends StatelessWidget {
  final IconData icon;
  final NatsuyumeColorScheme colors;
  final bool selected;
  final VoidCallback onTap;

  const _TopBarButton({
    required this.icon,
    required this.colors,
    this.selected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: selected ? colors.accent.withOpacity(0.2) : colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: selected
              ? Border.all(color: colors.accent.withOpacity(0.4))
              : null,
        ),
        child: Icon(
          icon,
          size: 20,
          color: selected ? colors.accent : colors.onSurface,
        ),
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
