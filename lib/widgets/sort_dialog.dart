import 'package:flutter/material.dart';
import '../theme/natsuyume_theme.dart';

// Sort direction — only for collection sorts
enum SortDirection { ascending, descending }

// Normal sort fields (universal track list)
enum TrackSortField {
  title,
  album,
  artist,
  albumArtist,
  composer,
  genre,
  trackNumber,
  duration,
  year,
}

extension TrackSortFieldLabel on TrackSortField {
  String get label {
    switch (this) {
      case TrackSortField.title:
        return 'Title';
      case TrackSortField.album:
        return 'Album';
      case TrackSortField.artist:
        return 'Artist';
      case TrackSortField.albumArtist:
        return 'Album-Artist';
      case TrackSortField.composer:
        return 'Composer';
      case TrackSortField.genre:
        return 'Genre';
      case TrackSortField.trackNumber:
        return 'Track Number';
      case TrackSortField.duration:
        return 'Duration';
      case TrackSortField.year:
        return 'Year';
    }
  }
}

// Special sort options — context specific
enum SpecialTrackSort {
  // Queue specific
  randomize,
  reverse,
  // Shared
  mostPlayedFirst,
  leastPlayedFirst,
  // Playlist specific
  manual,
}

extension SpecialTrackSortLabel on SpecialTrackSort {
  String get label {
    switch (this) {
      case SpecialTrackSort.randomize:
        return 'Randomize';
      case SpecialTrackSort.reverse:
        return 'Reverse';
      case SpecialTrackSort.mostPlayedFirst:
        return 'Most played first';
      case SpecialTrackSort.leastPlayedFirst:
        return 'Least played first';
      case SpecialTrackSort.manual:
        return 'Manual';
    }
  }
}

// Album tab sort fields
enum AlbumSortField {
  name,
  numberOfSongs,
  duration,
  year,
  artist,
  albumArtist,
  composer,
}

extension AlbumSortFieldLabel on AlbumSortField {
  String get label {
    switch (this) {
      case AlbumSortField.name:
        return 'Name';
      case AlbumSortField.numberOfSongs:
        return 'Number of songs';
      case AlbumSortField.duration:
        return 'Duration';
      case AlbumSortField.year:
        return 'Year';
      case AlbumSortField.artist:
        return 'Artist';
      case AlbumSortField.albumArtist:
        return 'Album-Artist';
      case AlbumSortField.composer:
        return 'Composer';
    }
  }
}

// Artist tab sort fields
enum ArtistSortField { name, numberOfSongs, duration }

extension ArtistSortFieldLabel on ArtistSortField {
  String get label {
    switch (this) {
      case ArtistSortField.name:
        return 'Name';
      case ArtistSortField.numberOfSongs:
        return 'Number of songs';
      case ArtistSortField.duration:
        return 'Duration';
    }
  }
}

// ─────────────────────────────────────────────
// UNIVERSAL TRACK LIST SORT DIALOG
// Used by album/artist/playlist track lists
// with optional special tab
// ─────────────────────────────────────────────
class TrackSortDialog extends StatefulWidget {
  final TrackSortField selectedField;
  final SortDirection direction;
  final List<SpecialTrackSort>? specialOptions;
  final SpecialTrackSort? selectedSpecial;
  final void Function(TrackSortField field, SortDirection direction)
  onNormalChanged;
  final void Function(SpecialTrackSort special)? onSpecialChanged;

  const TrackSortDialog({
    super.key,
    required this.selectedField,
    required this.direction,
    this.specialOptions,
    this.selectedSpecial,
    required this.onNormalChanged,
    this.onSpecialChanged,
  });

  @override
  State<TrackSortDialog> createState() => _TrackSortDialogState();
}

class _TrackSortDialogState extends State<TrackSortDialog> {
  late TrackSortField _field;
  late SortDirection _direction;
  late SpecialTrackSort? _special;
  bool _showSpecial = false;

  bool get _hasSpecial =>
      widget.specialOptions != null && widget.specialOptions!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _field = widget.selectedField;
    _direction = widget.direction;
    _special = widget.selectedSpecial;
  }

  @override
  Widget build(BuildContext context) {
    final colors = NatsuyumeTheme.of(context).colors;

    return _SortShell(
      colors: colors,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SortTitle(colors: colors),
          const SizedBox(height: 12),
          // Normal / Special tab toggle
          if (_hasSpecial)
            _TabToggle(
              leftLabel: 'Normal',
              rightLabel: 'Special',
              showRight: _showSpecial,
              colors: colors,
              onChanged: (showRight) =>
                  setState(() => _showSpecial = showRight),
            ),
          if (_hasSpecial) const SizedBox(height: 12),
          if (!_showSpecial) ...[
            // Ascending / Descending
            _DirectionToggle(
              direction: _direction,
              colors: colors,
              onChanged: (d) {
                setState(() => _direction = d);
                widget.onNormalChanged(_field, _direction);
              },
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            // Field list
            ...TrackSortField.values.map((field) {
              return _SortOption(
                label: field.label,
                selected: _field == field,
                colors: colors,
                onTap: () {
                  setState(() => _field = field);
                  widget.onNormalChanged(_field, _direction);
                },
              );
            }),
          ] else ...[
            const Divider(height: 1),
            ...widget.specialOptions!.map((option) {
              return _SortOption(
                label: option.label,
                selected: _special == option,
                colors: colors,
                onTap: () {
                  setState(() => _special = option);
                  widget.onSpecialChanged?.call(option);
                },
              );
            }),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// QUEUE SORT DIALOG
// Special only — no normal tab
// ─────────────────────────────────────────────
class QueueSortDialog extends StatefulWidget {
  final SpecialTrackSort? selected;
  final void Function(SpecialTrackSort special) onChanged;

  const QueueSortDialog({super.key, this.selected, required this.onChanged});

  @override
  State<QueueSortDialog> createState() => _QueueSortDialogState();
}

class _QueueSortDialogState extends State<QueueSortDialog> {
  late SpecialTrackSort? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    final colors = NatsuyumeTheme.of(context).colors;
    final options = [
      SpecialTrackSort.randomize,
      SpecialTrackSort.reverse,
      SpecialTrackSort.mostPlayedFirst,
      SpecialTrackSort.leastPlayedFirst,
    ];

    return _SortShell(
      colors: colors,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SortTitle(colors: colors),
          const SizedBox(height: 12),
          const Divider(height: 1),
          ...options.map((option) {
            return _SortOption(
              label: option.label,
              selected: _selected == option,
              colors: colors,
              onTap: () {
                setState(() => _selected = option);
                widget.onChanged(option);
              },
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ALBUM TAB SORT DIALOG
// ─────────────────────────────────────────────
class AlbumSortDialog extends StatefulWidget {
  final AlbumSortField selectedField;
  final SortDirection direction;
  final void Function(AlbumSortField field, SortDirection direction) onChanged;

  const AlbumSortDialog({
    super.key,
    required this.selectedField,
    required this.direction,
    required this.onChanged,
  });

  @override
  State<AlbumSortDialog> createState() => _AlbumSortDialogState();
}

class _AlbumSortDialogState extends State<AlbumSortDialog> {
  late AlbumSortField _field;
  late SortDirection _direction;

  @override
  void initState() {
    super.initState();
    _field = widget.selectedField;
    _direction = widget.direction;
  }

  @override
  Widget build(BuildContext context) {
    final colors = NatsuyumeTheme.of(context).colors;

    return _SortShell(
      colors: colors,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SortTitle(colors: colors),
          const SizedBox(height: 12),
          _DirectionToggle(
            direction: _direction,
            colors: colors,
            onChanged: (d) {
              setState(() => _direction = d);
              widget.onChanged(_field, _direction);
            },
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          ...AlbumSortField.values.map((field) {
            return _SortOption(
              label: field.label,
              selected: _field == field,
              colors: colors,
              onTap: () {
                setState(() => _field = field);
                widget.onChanged(_field, _direction);
              },
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ARTIST TAB SORT DIALOG
// ─────────────────────────────────────────────
class ArtistSortDialog extends StatefulWidget {
  final ArtistSortField selectedField;
  final SortDirection direction;
  final void Function(ArtistSortField field, SortDirection direction) onChanged;

  const ArtistSortDialog({
    super.key,
    required this.selectedField,
    required this.direction,
    required this.onChanged,
  });

  @override
  State<ArtistSortDialog> createState() => _ArtistSortDialogState();
}

class _ArtistSortDialogState extends State<ArtistSortDialog> {
  late ArtistSortField _field;
  late SortDirection _direction;

  @override
  void initState() {
    super.initState();
    _field = widget.selectedField;
    _direction = widget.direction;
  }

  @override
  Widget build(BuildContext context) {
    final colors = NatsuyumeTheme.of(context).colors;

    return _SortShell(
      colors: colors,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SortTitle(colors: colors),
          const SizedBox(height: 12),
          _DirectionToggle(
            direction: _direction,
            colors: colors,
            onChanged: (d) {
              setState(() => _direction = d);
              widget.onChanged(_field, _direction);
            },
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          ...ArtistSortField.values.map((field) {
            return _SortOption(
              label: field.label,
              selected: _field == field,
              colors: colors,
              onTap: () {
                setState(() => _field = field);
                widget.onChanged(_field, _direction);
              },
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SHARED INTERNAL WIDGETS
// ─────────────────────────────────────────────
class _SortShell extends StatelessWidget {
  final NatsuyumeColorScheme colors;
  final Widget child;

  const _SortShell({required this.colors, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

class _SortTitle extends StatelessWidget {
  final NatsuyumeColorScheme colors;

  const _SortTitle({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Sort',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: colors.onSurface,
        ),
      ),
    );
  }
}

class _TabToggle extends StatelessWidget {
  final String leftLabel;
  final String rightLabel;
  final bool showRight;
  final NatsuyumeColorScheme colors;
  final ValueChanged<bool> onChanged;

  const _TabToggle({
    required this.leftLabel,
    required this.rightLabel,
    required this.showRight,
    required this.colors,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TabButton(
            label: leftLabel,
            selected: !showRight,
            colors: colors,
            onTap: () => onChanged(false),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _TabButton(
            label: rightLabel,
            selected: showRight,
            colors: colors,
            onTap: () => onChanged(true),
          ),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final NatsuyumeColorScheme colors;
  final VoidCallback onTap;

  const _TabButton({
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
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? colors.accent : colors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? colors.background : colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _DirectionToggle extends StatelessWidget {
  final SortDirection direction;
  final NatsuyumeColorScheme colors;
  final ValueChanged<SortDirection> onChanged;

  const _DirectionToggle({
    required this.direction,
    required this.colors,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TabButton(
            label: '↑ Ascending',
            selected: direction == SortDirection.ascending,
            colors: colors,
            onTap: () => onChanged(SortDirection.ascending),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _TabButton(
            label: '↓ Descending',
            selected: direction == SortDirection.descending,
            colors: colors,
            onTap: () => onChanged(SortDirection.descending),
          ),
        ),
      ],
    );
  }
}

class _SortOption extends StatelessWidget {
  final String label;
  final bool selected;
  final NatsuyumeColorScheme colors;
  final VoidCallback onTap;

  const _SortOption({
    required this.label,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: selected
              ? colors.accent.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: selected ? colors.accent : colors.onSurface,
            fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
