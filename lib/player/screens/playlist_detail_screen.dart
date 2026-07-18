import 'package:flutter/material.dart';
import '../../theme/natsuyume_theme.dart';
import '../../widgets/collection_detail_bar.dart';
import '../../widgets/playlist_track_list.dart';
import 'playlists_screen.dart';
import 'playlist_editor_screen.dart';
import 'playlist_info_overlay.dart';

final _placeholderPlaylistTracks = [
  PlaylistTrack(
    title: 'Calling Blue (overture)',
    artist: 'Turquoise',
    album: '水瀬いのり',
    duration: '1:11',
  ),
  PlaylistTrack(
    title: 'Turquoise',
    artist: 'Turquoise',
    album: '水瀬いのり',
    duration: '3:32',
  ),
  PlaylistTrack(
    title: '夢のつぼみ',
    artist: '夢のつぼみ',
    album: '水瀬いのり',
    duration: '5:01',
  ),
  PlaylistTrack(
    title: '夏の約束',
    artist: 'Starry Wish',
    album: '水瀬いのり',
    duration: '4:10',
  ),
  PlaylistTrack(
    title: '風色Letter',
    artist: 'glow',
    album: '水瀬いのり',
    duration: '4:35',
  ),
  PlaylistTrack(
    title: '八月のスーベニア',
    artist: 'glow',
    album: '水瀬いのり',
    duration: '5:11',
  ),
  PlaylistTrack(
    title: '夏夢',
    artist: 'アイマイモコ',
    album: '水瀬いのり',
    duration: '4:59',
  ),
  PlaylistTrack(
    title: '水彩メモリー',
    artist: 'Catch the Rainbow!',
    album: '水瀬いのり',
    duration: '4:35',
  ),
];

class PlaylistDetailScreen extends StatefulWidget {
  final PlaylistData playlist;
  final bool isPlaylistPlaying;

  const PlaylistDetailScreen({
    super.key,
    required this.playlist,
    required this.isPlaylistPlaying,
  });

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showTitleInBar = false;
  int _currentTrackIndex = 1;

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

  String get _totalDuration => '1:29:43';

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
                const SliverToBoxAdapter(child: SizedBox(height: 56)),
                SliverToBoxAdapter(child: _buildCoverHero(colors)),
                SliverToBoxAdapter(child: _buildPlaylistInfo(colors)),
                PlaylistTrackList(
                  tracks: _placeholderPlaylistTracks,
                  currentTrackIndex: _currentTrackIndex,
                  onTrackTap: (i) => setState(() => _currentTrackIndex = i),
                  onMoreTap: (i) => _showTrackMenu(context, i, colors),
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
                title: widget.playlist.name,
                showTitle: _showTitleInBar,
                onBack: () => Navigator.of(context).pop(),
                onMoreTap: () => _showPlaylistMenu(context, colors),
                extraActions: [
                  _BarButton(
                    icon: Icons.edit_outlined,
                    colors: colors,
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => FractionallySizedBox(
                          heightFactor: 1.0,
                          child: PlaylistEditorScreen(
                            initialName: widget.playlist.name,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            // Pinned shuffle + play when scrolled
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
      child: GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => FractionallySizedBox(
              heightFactor: 1.0,
              child: PlaylistInfoOverlay(
                playlist: widget.playlist,
                totalDuration: _totalDuration,
                description: 'No description yet.',
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 1,
              child: widget.playlist.coverArt != null
                  ? Image(image: widget.playlist.coverArt!, fit: BoxFit.cover)
                  : Container(
                      color: colors.surfaceVariant,
                      child: Icon(
                        Icons.playlist_play,
                        size: 80,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistInfo(NatsuyumeColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.playlist.name,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: colors.onBackground,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _InfoChip(
                label: '${widget.playlist.songCount} songs',
                colors: colors,
              ),
              const SizedBox(width: 8),
              _InfoChip(label: _totalDuration, colors: colors),
            ],
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

  void _showPlaylistMenu(BuildContext context, NatsuyumeColorScheme colors) {
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
            leading: Icon(Icons.share_outlined, color: colors.onSurface),
            title: Text('Share', style: TextStyle(color: colors.onSurface)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: colors.onSurface),
            title: Text(
              'Delete playlist',
              style: TextStyle(color: colors.onSurface),
            ),
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
            leading: Icon(Icons.remove_circle_outline, color: colors.onSurface),
            title: Text(
              'Remove from playlist',
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
