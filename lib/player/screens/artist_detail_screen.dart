import 'package:flutter/material.dart';
import '../../theme/natsuyume_theme.dart';
import '../../widgets/collection_detail_bar.dart';
import '../../widgets/artist_album_list.dart';
import 'artists_screen.dart';
import 'album_detail_screen.dart';
import '../../widgets/album_grid_item.dart';

final _placeholderArtistAlbums = [
  ArtistAlbumEntry(title: 'Summer Challenger', year: 2026, songCount: 3),
  ArtistAlbumEntry(title: 'Turquoise', year: 2025, songCount: 8),
  ArtistAlbumEntry(title: 'Travel Record', year: 2025, songCount: 23),
  ArtistAlbumEntry(title: 'heart bookmark', year: 2024, songCount: 7),
  ArtistAlbumEntry(title: 'スクラップアート', year: 2023, songCount: 3),
  ArtistAlbumEntry(title: 'アイオライト', year: 2023, songCount: 3),
  ArtistAlbumEntry(title: 'glow', year: 2022, songCount: 14),
];

class ArtistDetailScreen extends StatefulWidget {
  final ArtistData artist;
  final bool isArtistPlaying;

  const ArtistDetailScreen({
    super.key,
    required this.artist,
    required this.isArtistPlaying,
  });

  @override
  State<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showTitleInBar = false;
  int? _currentAlbumIndex = 0;

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

  void _openAlbum(int index) {
    final entry = _placeholderArtistAlbums[index];
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AlbumDetailScreen(
          album: AlbumData(
            title: entry.title,
            artist: widget.artist.name,
            year: entry.year,
            songCount: entry.songCount,
            coverArt: entry.coverArt,
          ),
          isAlbumPlaying: index == _currentAlbumIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = NatsuyumeTheme.of(context).colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Space for top bar
                const SliverToBoxAdapter(child: SizedBox(height: 56)),
                // Artist photo hero with parallax fade
                SliverToBoxAdapter(child: _buildPhotoHero(colors)),
                // Artist info + action buttons
                SliverToBoxAdapter(child: _buildArtistInfo(colors)),
                // Album list
                ArtistAlbumList(
                  allSongsLabel: 'All songs',
                  allSongsCount: 128,
                  albums: _placeholderArtistAlbums,
                  currentAlbumIndex: _currentAlbumIndex,
                  onAllSongsTap: () {
                    // Navigate to all songs view — coming after concept UI is ready
                  },
                  onAlbumTap: _openAlbum,
                  onAlbumMoreTap: (i) => _showAlbumMenu(context, i, colors),
                  onAllSongsMoreTap: () {},
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
            // Floating top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: CollectionDetailBar(
                title: widget.artist.name,
                showTitle: _showTitleInBar,
                onBack: () => Navigator.of(context).pop(),
                onMoreTap: () => _showArtistMenu(context, colors),
                extraActions: [
                  _BarButton(
                    icon: Icons.edit_outlined,
                    colors: colors,
                    onTap: () {
                      // Edit artist info — deferred to 0.9.x
                    },
                  ),
                ],
              ),
            ),
            // Pinned shuffle + play buttons when scrolled
            if (_showTitleInBar)
              Positioned(
                right: 16,
                bottom: 16,
                child: _buildActionButtons(colors),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoHero(NatsuyumeColorScheme colors) {
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
            child: widget.artist.photo != null
                ? Image(image: widget.artist.photo!, fit: BoxFit.cover)
                : Container(
                    color: colors.surfaceVariant,
                    child: Icon(
                      Icons.person,
                      size: 80,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildArtistInfo(NatsuyumeColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.artist.name,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: colors.onBackground,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          // Album count chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${widget.artist.albumCount} albums',
              style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 20),
          _buildActionButtons(colors),
        ],
      ),
    );
  }

  Widget _buildActionButtons(NatsuyumeColorScheme colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionButton(icon: Icons.shuffle, colors: colors, onTap: () {}),
        const SizedBox(width: 12),
        _ActionButton(icon: Icons.play_arrow, colors: colors, onTap: () {}),
      ],
    );
  }

  void _showArtistMenu(BuildContext context, NatsuyumeColorScheme colors) {
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
              'Add all to queue',
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

  void _showAlbumMenu(
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
}

class _BarButton extends StatelessWidget {
  final IconData icon;
  final NatsuyumeColorScheme colors;
  final VoidCallback onTap;

  const _BarButton({
    required this.icon,
    required this.colors,
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
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: colors.onSurface),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final NatsuyumeColorScheme colors;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, size: 24, color: colors.onSurface),
      ),
    );
  }
}
