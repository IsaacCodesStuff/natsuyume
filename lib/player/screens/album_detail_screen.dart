import 'package:flutter/material.dart';
import '../../theme/natsuyume_theme.dart';
import '../../widgets/album_grid_item.dart';
import '../../widgets/album_track_list.dart';
import '../../widgets/collection_detail_bar.dart';

// Placeholder tracks for the album detail
final _placeholderTracks = [
  CollectionTrack(
    title: 'Summer Challenger',
    artist: '水瀬いのり',
    duration: '4:25',
  ),
  CollectionTrack(title: 'ハートノフレーバー', artist: '水瀬いのり', duration: '5:12'),
  CollectionTrack(title: 'リフローレセンス', artist: '水瀬いのり', duration: '4:31'),
];

class AlbumDetailScreen extends StatefulWidget {
  final AlbumData album;
  final bool isAlbumPlaying;

  const AlbumDetailScreen({
    super.key,
    required this.album,
    required this.isAlbumPlaying,
  });

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showTitleInBar = false;
  int _currentTrackIndex = 1;

  // The hero cover height — title appears in bar once we scroll past this
  static const double _coverThreshold = 260.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final shouldShow = _scrollController.offset > _coverThreshold;
    if (shouldShow != _showTitleInBar) {
      setState(() => _showTitleInBar = shouldShow);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  String get _totalDuration => '14:38';

  @override
  Widget build(BuildContext context) {
    final colors = NatsuyumeTheme.of(context).colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Main scrollable content
            CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Space for the top bar
                const SliverToBoxAdapter(child: SizedBox(height: 56)),
                // Cover art hero with parallax fade
                SliverToBoxAdapter(child: _buildCoverHero(colors)),
                // Album info + action buttons
                SliverToBoxAdapter(child: _buildAlbumInfo(colors)),
                // Track list
                AlbumTrackList(
                  tracks: _placeholderTracks,
                  currentTrackIndex: _currentTrackIndex,
                  onTrackTap: (i) => setState(() => _currentTrackIndex = i),
                  onMoreTap: (i) => _showTrackMenu(context, i, colors),
                ),
                // Bottom padding
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
            // Floating top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: CollectionDetailBar(
                title: widget.album.title,
                showTitle: _showTitleInBar,
                onBack: () => Navigator.of(context).pop(),
                onMoreTap: () => _showAlbumMenu(context, colors),
              ),
            ),
            // Pinned shuffle + play buttons (visible when title shows in bar)
            if (_showTitleInBar)
              Positioned(
                right: 16,
                bottom: 16,
                child: _buildActionButtons(colors, small: true),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverHero(NatsuyumeColorScheme colors) {
    return AnimatedBuilder(
      animation: _scrollController,
      builder: (context, child) {
        final offset = _scrollController.hasClients
            ? _scrollController.offset
            : 0.0;
        final opacity = (1.0 - (offset / _coverThreshold)).clamp(0.0, 1.0);
        final parallaxOffset = offset * 0.4;

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, -parallaxOffset),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 1,
            child: widget.album.coverArt != null
                ? Image(image: widget.album.coverArt!, fit: BoxFit.cover)
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
    );
  }

  Widget _buildAlbumInfo(NatsuyumeColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + artist
          Text(
            widget.album.title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: colors.onBackground,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.album.artist,
            style: TextStyle(fontSize: 16, color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          // Chips row
          Row(
            children: [
              _InfoChip(label: '${widget.album.year}', colors: colors),
              const SizedBox(width: 8),
              _InfoChip(
                label: '${widget.album.songCount} songs',
                colors: colors,
              ),
              const SizedBox(width: 8),
              _InfoChip(label: _totalDuration, colors: colors),
            ],
          ),
          const SizedBox(height: 20),
          // Action buttons
          _buildActionButtons(colors, small: false),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    NatsuyumeColorScheme colors, {
    required bool small,
  }) {
    final size = small ? 48.0 : 56.0;
    final iconSize = small ? 20.0 : 24.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionButton(
          icon: Icons.shuffle,
          colors: colors,
          size: size,
          iconSize: iconSize,
          onTap: () {},
        ),
        const SizedBox(width: 12),
        _ActionButton(
          icon: Icons.play_arrow,
          colors: colors,
          size: size,
          iconSize: iconSize,
          onTap: () {},
        ),
      ],
    );
  }

  void _showAlbumMenu(BuildContext context, NatsuyumeColorScheme colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.queue_music, color: colors.onSurface),
            title: Text(
              'Add to queue',
              style: TextStyle(color: colors.onSurface),
            ),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Icon(Icons.save_outlined, color: colors.onSurface),
            title: Text(
              'Save as playlist',
              style: TextStyle(color: colors.onSurface),
            ),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Icon(Icons.share_outlined, color: colors.onSurface),
            title: Text('Share', style: TextStyle(color: colors.onSurface)),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showTrackMenu(
    BuildContext context,
    int index,
    NatsuyumeColorScheme colors,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.play_arrow, color: colors.onSurface),
            title: Text('Play next', style: TextStyle(color: colors.onSurface)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Icon(Icons.queue_music, color: colors.onSurface),
            title: Text(
              'Add to queue',
              style: TextStyle(color: colors.onSurface),
            ),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Icon(Icons.save_outlined, color: colors.onSurface),
            title: Text(
              'Save to playlist',
              style: TextStyle(color: colors.onSurface),
            ),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Icon(Icons.info_outline, color: colors.onSurface),
            title: Text(
              'Track info',
              style: TextStyle(color: colors.onSurface),
            ),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final NatsuyumeColorScheme colors;

  const _InfoChip({required this.label, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final NatsuyumeColorScheme colors;
  final double size;
  final double iconSize;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.colors,
    required this.size,
    required this.iconSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, size: iconSize, color: colors.onSurface),
      ),
    );
  }
}
