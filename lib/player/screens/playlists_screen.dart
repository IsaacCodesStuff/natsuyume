import 'package:flutter/material.dart';
import '../../theme/natsuyume_theme.dart';
import '../../widgets/library_top_bar.dart';
import '../../widgets/album_grid_item.dart';
import '../../widgets/album_list_item.dart';
import 'playlist_detail_screen.dart';
import '../../widgets/sort_dialog.dart';
import 'context_menus/playlist_tab_context_menu.dart';

class PlaylistData {
  final String name;
  final int songCount;
  final ImageProvider? coverArt;

  const PlaylistData({
    required this.name,
    required this.songCount,
    this.coverArt,
  });

  String get subtitle => '$songCount songs';
}

final _placeholderPlaylists = [
  PlaylistData(name: 'mood', songCount: 10),
  PlaylistData(name: 'Inori-chan <3', songCount: 20),
  PlaylistData(name: 'beats for locking in', songCount: 17),
  PlaylistData(name: 'chinese music i found on yt', songCount: 19),
  PlaylistData(name: 'cool ass beats', songCount: 15),
  PlaylistData(name: 'Inori love songs', songCount: 32),
  PlaylistData(name: 'national "anthems"', songCount: 2),
  PlaylistData(name: 'meme tracks from discord', songCount: 7),
];

class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  LibraryLayout _layout = LibraryLayout.grid;
  String _searchQuery = '';
  final int _playingPlaylistIndex = 1;

  List<PlaylistData> get _filteredPlaylists {
    if (_searchQuery.isEmpty) return _placeholderPlaylists;
    final q = _searchQuery.toLowerCase();
    return _placeholderPlaylists
        .where((p) => p.name.toLowerCase().contains(q))
        .toList();
  }

  void _openPlaylist(PlaylistData playlist) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlaylistDetailScreen(
          playlist: playlist,
          isPlaylistPlaying:
              _placeholderPlaylists.indexOf(playlist) == _playingPlaylistIndex,
        ),
      ),
    );
  }

  void _showMoreSheet(BuildContext context, NatsuyumeColorScheme colors) {
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
            leading: Icon(Icons.sort, color: colors.onSurface),
            title: Text('Sort', style: TextStyle(color: colors.onSurface)),
            onTap: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (_) => AlbumSortDialog(
                  selectedField: AlbumSortField.name,
                  direction: SortDirection.ascending,
                  onChanged: (field, direction) {},
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.add, color: colors.onSurface),
            title: Text(
              'New playlist',
              style: TextStyle(color: colors.onSurface),
            ),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  AlbumData _toAlbumData(PlaylistData playlist) => AlbumData(
    title: playlist.name,
    artist: playlist.subtitle,
    year: 0,
    songCount: playlist.songCount,
    coverArt: playlist.coverArt,
  );

  @override
  Widget build(BuildContext context) {
    final colors = NatsuyumeTheme.of(context).colors;
    final playlists = _filteredPlaylists;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            LibraryTopBar(
              searchHint: 'Search a playlist...',
              searchQuery: _searchQuery,
              onSearchChanged: (q) => setState(() => _searchQuery = q),
              currentLayout: _layout,
              onLayoutChanged: (l) => setState(() => _layout = l),
              onMoreTap: () => _showMoreSheet(context, colors),
            ),
            Expanded(
              child: _layout == LibraryLayout.grid
                  ? _buildGrid(playlists, colors)
                  : _buildList(playlists, colors),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(List<PlaylistData> playlists, NatsuyumeColorScheme colors) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        return AlbumGridItem(
          album: _toAlbumData(playlists[index]),
          isPlaying:
              _placeholderPlaylists.indexOf(playlists[index]) ==
              _playingPlaylistIndex,
          onTap: () => _openPlaylist(playlists[index]),
          onLongPress: () => PlaylistTabContextMenu.show(
            context,
            playlist: playlists[index],
            onExportM3U: () {},
            onRenamePlaylist: () {},
            onRemovePlaylist: () {},
            onPlayAfterCurrent: () {},
            onAddToCurrentQueue: () {},
            onAddToQueue: () {},
            onAddToPlaylists: () {},
            onSelectAll: () {},
          ),
        );
      },
    );
  }

  Widget _buildList(List<PlaylistData> playlists, NatsuyumeColorScheme colors) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        return AlbumListItem(
          album: _toAlbumData(playlists[index]),
          isPlaying:
              _placeholderPlaylists.indexOf(playlists[index]) ==
              _playingPlaylistIndex,
          onTap: () => _openPlaylist(playlists[index]),
          onMoreTap: () {},
          onLongPress: () => PlaylistTabContextMenu.show(
            context,
            playlist: playlists[index],
            onExportM3U: () {},
            onRenamePlaylist: () {},
            onRemovePlaylist: () {},
            onPlayAfterCurrent: () {},
            onAddToCurrentQueue: () {},
            onAddToQueue: () {},
            onAddToPlaylists: () {},
            onSelectAll: () {},
          ),
        );
      },
    );
  }
}
