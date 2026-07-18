import 'package:flutter/material.dart';
import '../../theme/natsuyume_theme.dart';

enum LyricsMode { normal, synced }

class SyncedLyricLine {
  String text;
  Duration timestamp;

  SyncedLyricLine({required this.text, this.timestamp = Duration.zero});
}

class LyricsEditorScreen extends StatefulWidget {
  final String initialLyrics;

  const LyricsEditorScreen({super.key, this.initialLyrics = ''});

  @override
  State<LyricsEditorScreen> createState() => _LyricsEditorScreenState();
}

class _LyricsEditorScreenState extends State<LyricsEditorScreen> {
  LyricsMode _mode = LyricsMode.normal;
  late TextEditingController _normalController;
  List<SyncedLyricLine> _syncedLines = [];
  final List<TextEditingController> _lineControllers = [];
  final List<TextEditingController> _timestampControllers = [];

  // Stub playback position — wired to core in 0.8.x
  Duration _playbackPosition = const Duration(seconds: 94);
  bool _isPlaying = false;
  double _seekValue = 0.5;

  @override
  void initState() {
    super.initState();
    _normalController = TextEditingController(text: widget.initialLyrics);
  }

  @override
  void dispose() {
    _normalController.dispose();
    for (final c in _lineControllers) c.dispose();
    for (final c in _timestampControllers) c.dispose();
    super.dispose();
  }

  void _switchMode(LyricsMode mode) {
    if (mode == _mode) return;

    if (mode == LyricsMode.synced) {
      _parseLinesFromNormal();
    }

    setState(() => _mode = mode);
  }

  void _parseLinesFromNormal() {
    for (final c in _lineControllers) c.dispose();
    for (final c in _timestampControllers) c.dispose();
    _lineControllers.clear();
    _timestampControllers.clear();

    final text = _normalController.text;
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      _syncedLines = [SyncedLyricLine(text: '')];
    } else {
      _syncedLines = lines.map((l) => SyncedLyricLine(text: l)).toList();
    }

    for (final line in _syncedLines) {
      _lineControllers.add(TextEditingController(text: line.text));
      _timestampControllers.add(
        TextEditingController(text: _formatDuration(line.timestamp)),
      );
    }
  }

  void _stampTimestamp(int index) {
    setState(() {
      _syncedLines[index].timestamp = _playbackPosition;
      _timestampControllers[index].text = _formatDuration(_playbackPosition);
    });
  }

  void _onTimestampEdited(int index, String value) {
    final duration = _parseDuration(value);
    if (duration != null) {
      setState(() => _syncedLines[index].timestamp = duration);
    }
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Duration? _parseDuration(String value) {
    final parts = value.split(':');
    if (parts.length != 3) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final s = int.tryParse(parts[2]);
    if (h == null || m == null || s == null) return null;
    return Duration(hours: h, minutes: m, seconds: s);
  }

  void _save() {
    // Will write to file/db in 0.8.x
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = NatsuyumeTheme.of(context).colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(colors),
            const SizedBox(height: 12),
            _buildModeToggle(colors),
            const SizedBox(height: 16),
            Expanded(
              child: _mode == LyricsMode.normal
                  ? _buildNormalEditor(colors)
                  : _buildSyncedEditor(colors),
            ),
            if (_mode == LyricsMode.synced) _buildPlaybackControls(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(NatsuyumeColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          // Close
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Icon(Icons.close, color: colors.onSurface, size: 24),
          ),
          // Title pill
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: colors.accent.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  'Lyrics Editor',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
              ),
            ),
          ),
          // Save
          GestureDetector(
            onTap: _save,
            child: Icon(Icons.check, color: colors.accent, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle(NatsuyumeColorScheme colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ModeButton(
          label: 'Normal',
          selected: _mode == LyricsMode.normal,
          colors: colors,
          onTap: () => _switchMode(LyricsMode.normal),
        ),
        const SizedBox(width: 12),
        _ModeButton(
          label: 'Synced',
          selected: _mode == LyricsMode.synced,
          colors: colors,
          onTap: () => _switchMode(LyricsMode.synced),
        ),
      ],
    );
  }

  Widget _buildNormalEditor(NatsuyumeColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colors.accent.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: TextField(
          controller: _normalController,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          style: TextStyle(fontSize: 14, color: colors.onSurface, height: 1.6),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.all(16),
            border: InputBorder.none,
            hintText: 'Paste or type lyrics here...',
            hintStyle: TextStyle(color: colors.onSurfaceVariant, fontSize: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildSyncedEditor(NatsuyumeColorScheme colors) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _syncedLines.length,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colors.accent.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Timestamp column
                GestureDetector(
                  onTap: () => _stampTimestamp(index),
                  child: Container(
                    width: 72,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: colors.accent.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.schedule_outlined,
                          size: 18,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _timestampControllers[index],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.onSurfaceVariant,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (v) => _onTimestampEdited(index, v),
                        ),
                      ],
                    ),
                  ),
                ),
                // Lyric line input
                Expanded(
                  child: TextField(
                    controller: _lineControllers[index],
                    style: TextStyle(fontSize: 14, color: colors.onSurface),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      border: InputBorder.none,
                      hintText: 'Lyric line...',
                      hintStyle: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                    onChanged: (v) => _syncedLines[index].text = v,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaybackControls(NatsuyumeColorScheme colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.divider, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Seek bar
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              activeTrackColor: colors.accent,
              inactiveTrackColor: colors.surfaceVariant,
              thumbColor: colors.accent,
              overlayColor: colors.accent.withValues(alpha: 0.1),
            ),
            child: Slider(
              value: _seekValue,
              onChanged: (v) => setState(() => _seekValue = v),
            ),
          ),
          const SizedBox(height: 8),
          // Playback buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PlayButton(
                icon: Icons.fast_rewind,
                colors: colors,
                onTap: () {
                  setState(() {
                    final newPos =
                        _playbackPosition - const Duration(seconds: 5);
                    _playbackPosition = newPos.isNegative
                        ? Duration.zero
                        : newPos;
                  });
                },
              ),
              const SizedBox(width: 16),
              _PlayButton(
                icon: _isPlaying ? Icons.pause : Icons.play_arrow,
                colors: colors,
                large: true,
                onTap: () => setState(() => _isPlaying = !_isPlaying),
              ),
              const SizedBox(width: 16),
              _PlayButton(
                icon: Icons.fast_forward,
                colors: colors,
                onTap: () {
                  setState(() {
                    _playbackPosition += const Duration(seconds: 5);
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final NatsuyumeColorScheme colors;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? colors.accent : colors.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: selected ? colors.background : colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  final IconData icon;
  final NatsuyumeColorScheme colors;
  final bool large;
  final VoidCallback onTap;

  const _PlayButton({
    required this.icon,
    required this.colors,
    this.large = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = large ? 56.0 : 44.0;
    final iconSize = large ? 28.0 : 22.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: large ? colors.accent : colors.surfaceVariant,
          borderRadius: BorderRadius.circular(large ? 18 : 14),
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
