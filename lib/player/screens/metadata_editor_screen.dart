import 'package:flutter/material.dart';
import '../../theme/natsuyume_theme.dart';

class TrackMetadata {
  final String title;
  final String album;
  final String artist;
  final String albumArtist;
  final String composer;
  final String genre;
  final String lyricist;
  final String trackNumber;
  final String discNumber;
  final String year;
  final String comment;
  final ImageProvider? albumArt;

  const TrackMetadata({
    this.title = '',
    this.album = '',
    this.artist = '',
    this.albumArtist = '',
    this.composer = '',
    this.genre = '',
    this.lyricist = '',
    this.trackNumber = '',
    this.discNumber = '',
    this.year = '',
    this.comment = '',
    this.albumArt,
  });
}

class MetadataEditorScreen extends StatefulWidget {
  final List<TrackMetadata> tracks;

  const MetadataEditorScreen({super.key, required this.tracks});

  @override
  State<MetadataEditorScreen> createState() => _MetadataEditorScreenState();
}

class _MetadataEditorScreenState extends State<MetadataEditorScreen> {
  bool get _isMultiEdit => widget.tracks.length > 1;
  bool _warningDismissed = false;

  late final Map<String, TextEditingController> _controllers;

  // Returns null if values differ across tracks (multi-edit)
  String? _commonValue(String Function(TrackMetadata) getter) {
    final values = widget.tracks.map(getter).toSet();
    return values.length == 1 ? values.first : null;
  }

  @override
  void initState() {
    super.initState();

    _controllers = {
      'title': TextEditingController(text: _commonValue((t) => t.title) ?? ''),
      'album': TextEditingController(text: _commonValue((t) => t.album) ?? ''),
      'artist': TextEditingController(
        text: _commonValue((t) => t.artist) ?? '',
      ),
      'albumArtist': TextEditingController(
        text: _commonValue((t) => t.albumArtist) ?? '',
      ),
      'composer': TextEditingController(
        text: _commonValue((t) => t.composer) ?? '',
      ),
      'genre': TextEditingController(text: _commonValue((t) => t.genre) ?? ''),
      'lyricist': TextEditingController(
        text: _commonValue((t) => t.lyricist) ?? '',
      ),
      'trackNumber': TextEditingController(
        text: _commonValue((t) => t.trackNumber) ?? '',
      ),
      'discNumber': TextEditingController(
        text: _commonValue((t) => t.discNumber) ?? '',
      ),
      'year': TextEditingController(text: _commonValue((t) => t.year) ?? ''),
      'comment': TextEditingController(
        text: _commonValue((t) => t.comment) ?? '',
      ),
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String? _hintFor(String field) {
    if (!_isMultiEdit) return null;
    final getters = <String, String Function(TrackMetadata)>{
      'title': (t) => t.title,
      'album': (t) => t.album,
      'artist': (t) => t.artist,
      'albumArtist': (t) => t.albumArtist,
      'composer': (t) => t.composer,
      'genre': (t) => t.genre,
      'lyricist': (t) => t.lyricist,
      'trackNumber': (t) => t.trackNumber,
      'discNumber': (t) => t.discNumber,
      'year': (t) => t.year,
      'comment': (t) => t.comment,
    };
    final getter = getters[field];
    if (getter == null) return null;
    final values = widget.tracks.map(getter).toSet();
    return values.length > 1 ? 'Unchanged' : null;
  }

  void _onSave() {
    if (_isMultiEdit) {
      _showMultiSaveConfirmDialog();
    } else {
      // Single edit — save immediately, wired to core in 0.8.x
      Navigator.of(context).pop();
    }
  }

  void _showMultiSaveConfirmDialog() {
    final colors = NatsuyumeTheme.of(context).colors;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Save changes?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
        content: Text(
          'You are about to modify ${widget.tracks.length} songs at once. '
          'Fields left blank will remain unchanged. '
          'This action cannot be undone.',
          style: TextStyle(fontSize: 14, color: colors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Save wired to core in 0.8.x
              Navigator.of(context).pop();
            },
            child: Text('Save', style: TextStyle(color: colors.accent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = NatsuyumeTheme.of(context).colors;
    final track = widget.tracks.first;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildTopBar(colors),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildArtHero(colors, track),
                      const SizedBox(height: 8),
                      _buildFields(colors),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
            // Warning banner
            if (_isMultiEdit && !_warningDismissed)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: _buildWarningBanner(colors),
              ),
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
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Icon(Icons.close, color: colors.onSurface, size: 24),
          ),
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
                  'Metadata Editor',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: _onSave,
            child: Icon(Icons.check, color: colors.accent, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildArtHero(NatsuyumeColorScheme colors, TrackMetadata track) {
    return SizedBox(
      height: 260,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Album art background
          track.albumArt != null
              ? Image(image: track.albumArt!, fit: BoxFit.cover)
              : Container(color: colors.surfaceVariant),
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  colors.background.withValues(alpha: 0.85),
                ],
              ),
            ),
          ),
          // Edit + delete buttons
          Positioned(
            left: 24,
            bottom: 24,
            child: Row(
              children: [
                _ArtButton(
                  icon: Icons.edit_outlined,
                  colors: colors,
                  onTap: () {
                    // Image picker wired in 0.8.x
                  },
                ),
                const SizedBox(width: 16),
                _ArtButton(
                  icon: Icons.delete_outline,
                  colors: colors,
                  onTap: () {
                    // Remove cover art wired in 0.8.x
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFields(NatsuyumeColorScheme colors) {
    final fields = [
      ('title', 'Title'),
      ('album', 'Album'),
      ('artist', 'Artist'),
      ('albumArtist', 'Album-Artist'),
      ('composer', 'Composer'),
      ('genre', 'Genre'),
      ('lyricist', 'Lyricist'),
      ('trackNumber', 'Track number'),
      ('discNumber', 'Disc number'),
      ('year', 'Year'),
      ('comment', 'Comment'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: fields.map((field) {
          final key = field.$1;
          final label = field.$2;
          final hint = _hintFor(key);

          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _controllers[key],
                  style: TextStyle(fontSize: 16, color: colors.onSurface),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      fontSize: 16,
                      color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: colors.divider, width: 1),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: colors.accent, width: 1.5),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWarningBanner(NatsuyumeColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.pink.shade900.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.pinkAccent,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'You are modifying multiple songs at once. '
              'Please review your changes carefully before continuing.',
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _warningDismissed = true),
            child: const Icon(Icons.close, color: Colors.white70, size: 18),
          ),
        ],
      ),
    );
  }
}

class _ArtButton extends StatelessWidget {
  final IconData icon;
  final NatsuyumeColorScheme colors;
  final VoidCallback onTap;

  const _ArtButton({
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: colors.background.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
