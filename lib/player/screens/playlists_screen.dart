import 'package:flutter/material.dart';
import '../../theme/natsuyume_theme.dart';
import '../../widgets/library_top_bar.dart';
import '../../widgets/album_grid_item.dart';
import '../../widgets/album_list_item.dart';
import 'playlist_detail_screen.dart';
import '../../widgets/sort_dialog.dart';
import 'context_menus/playlist_tab_context_menu.dart';
import '../../core/library_types.dart';
import '../../core/natsuyume_core.dart';

class PlaylistData {
  final int id;
  final String name;
  final int songCount;
  final ImageProvider? coverArt;

  const PlaylistData({
    required this.id,
    required this.name,
    required this.songCount,
    this.coverArt,
  });

  String get subtitle => '$songCount songs';
}

class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  LibraryLayout _layout = LibraryLayout.grid;
  String _searchQuery = '';
  List<PlaylistData> _playlists = [];

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  void _loadPlaylists() {
    final raw = NatsuyumeCore.instance.getPlaylists();
    setState(() {
      _playlists = raw
          .map(
            (p) => PlaylistData(id: p.id, name: p.name, songCount: p.songCount),
          )
          .toList();
    });
  }

  List<PlaylistData> get _filteredPlaylists {
    if (_searchQuery.isEmpty) return _playlists;
    final q = _searchQuery.toLowerCase();
    return _playlists.where((p) => p.name.toLowerCase().contains(q)).toList();
  }

  void _openPlaylist(PlaylistData playlist) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => PlaylistDetailScreen(
              playlist: playlist,
              isPlaylistPlaying: false,
            ),
          ),
        )
        .then((_) => _loadPlaylists());
  }

  void _showCreatePlaylistDialog() {
    final controller = TextEditingController();
    final colors = NatsuyumeTheme.of(context).colors;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text('New playlist', style: TextStyle(color: colors.onSurface)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: colors.onSurface),
          decoration: InputDecoration(
            hintText: 'Playlist name',
            hintStyle: TextStyle(color: colors.onSurfaceVariant),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: colors.onSurfaceVariant),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: colors.accent),
            ),
          ),
          onSubmitted: (_) => _createPlaylist(controller.text),
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
            onPressed: () => _createPlaylist(controller.text),
            child: Text('Create', style: TextStyle(color: colors.accent)),
          ),
        ],
      ),
    );
  }

  void _createPlaylist(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    Navigator.pop(context);
    NatsuyumeCore.instance.createPlaylist(trimmed);
    _loadPlaylists();
  }

  void _renamePlaylist(PlaylistData playlist) {
    final controller = TextEditingController(text: playlist.name);
    final colors = NatsuyumeTheme.of(context).colors;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text(
          'Rename playlist',
          style: TextStyle(color: colors.onSurface),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: colors.onSurface),
          decoration: InputDecoration(
            hintText: 'Playlist name',
            hintStyle: TextStyle(color: colors.onSurfaceVariant),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: colors.onSurfaceVariant),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: colors.accent),
            ),
          ),
          onSubmitted: (_) => _doRename(playlist, controller.text),
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
            onPressed: () => _doRename(playlist, controller.text),
            child: Text('Rename', style: TextStyle(color: colors.accent)),
          ),
        ],
      ),
    );
  }

  void _doRename(PlaylistData playlist, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    Navigator.pop(context);
    NatsuyumeCore.instance.renamePlaylist(playlist.id, trimmed);
    _loadPlaylists();
  }

  void _deletePlaylist(PlaylistData playlist) {
    final colors = NatsuyumeTheme.of(context).colors;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text(
          'Delete playlist',
          style: TextStyle(color: colors.onSurface),
        ),
        content: Text(
          'Delete "${playlist.name}"? This cannot be undone.',
          style: TextStyle(color: colors.onSurfaceVariant),
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
              NatsuyumeCore.instance.deletePlaylist(playlist.id);
              _loadPlaylists();
            },
            child: Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
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
            leading: Icon(Icons.add, color: colors.onSurface),
            title: Text(
              'New playlist',
              style: TextStyle(color: colors.onSurface),
            ),
            onTap: () {
              Navigator.pop(context);
              _showCreatePlaylistDialog();
            },
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
              child: playlists.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.queue_music,
                            size: 48,
                            color: colors.onSurfaceVariant,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No playlists yet',
                            style: TextStyle(
                              fontSize: 15,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextButton(
                            onPressed: _showCreatePlaylistDialog,
                            child: Text(
                              'Create one',
                              style: TextStyle(color: colors.accent),
                            ),
                          ),
                        ],
                      ),
                    )
                  : _layout == LibraryLayout.grid
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
          isPlaying: false,
          onTap: () => _openPlaylist(playlists[index]),
          onLongPress: () => PlaylistTabContextMenu.show(
            context,
            playlist: playlists[index],
            onExportM3U: () {},
            onRenamePlaylist: () => _renamePlaylist(playlists[index]),
            onRemovePlaylist: () => _deletePlaylist(playlists[index]),
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
          isPlaying: false,
          onTap: () => _openPlaylist(playlists[index]),
          onMoreTap: () => _renamePlaylist(playlists[index]),
          onLongPress: () => PlaylistTabContextMenu.show(
            context,
            playlist: playlists[index],
            onExportM3U: () {},
            onRenamePlaylist: () => _renamePlaylist(playlists[index]),
            onRemovePlaylist: () => _deletePlaylist(playlists[index]),
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
