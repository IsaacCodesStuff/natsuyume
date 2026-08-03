import 'package:flutter/material.dart';
import 'dart:io';
import '../../theme/natsuyume_theme.dart';
import '../../widgets/library_top_bar.dart';
import '../../widgets/album_grid_item.dart';
import '../../widgets/album_list_item.dart';
import 'playlist_detail_screen.dart';
import '../../widgets/sort_dialog.dart';
import 'context_menus/playlist_tab_context_menu.dart';
import '../../core/library_types.dart';
import '../../core/natsuyume_core.dart';
import '../../widgets/floating_mini_player.dart';

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

enum _PlaylistTab { builtIn, myPlaylists, external }

class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  LibraryLayout _layout = LibraryLayout.grid;
  String _searchQuery = '';
  List<PlaylistData> _playlists = [];
  _PlaylistTab _activeTab = _PlaylistTab.myPlaylists;

  // Built-in playlist IDs — special values from UserDataManager
  static const int _allSongsId = -2;
  static const int _favoritesId = -3;
  static const int _mostPlayedId = -4;
  static const int _notPlayedId = -5;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  void _loadPlaylists() {
    final raw = NatsuyumeCore.instance.getPlaylists();
    final enriched = raw.map((p) {
      final imagePath = NatsuyumeCore.instance.getPlaylistImage(p.id);
      return PlaylistData(
        id: p.id,
        name: p.name,
        songCount: p.songCount,
        coverArt: imagePath.isNotEmpty ? FileImage(File(imagePath)) : null,
      );
    }).toList();
    setState(() => _playlists = enriched);
  }

  List<PlaylistData> get _filteredPlaylists {
    final source = _activeTab == _PlaylistTab.myPlaylists
        ? _playlists
        : <PlaylistData>[];
    if (_searchQuery.isEmpty) return source;
    final q = _searchQuery.toLowerCase();
    return source.where((p) => p.name.toLowerCase().contains(q)).toList();
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

  void _showSortDialog(BuildContext context, NatsuyumeColorScheme colors) {
    showDialog(
      context: context,
      builder: (_) => AlbumSortDialog(
        selectedField: AlbumSortField.name,
        direction: SortDirection.ascending,
        onChanged: (field, direction) {
          // Sort wiring — deferred to 0.9.1
        },
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

    return Scaffold(
      backgroundColor: colors.background,
      floatingActionButton: _activeTab == _PlaylistTab.myPlaylists
          ? ListenableBuilder(
              listenable: NatsuyumeCore.instance.playerState,
              builder: (context, _) {
                final hasTrack =
                    !NatsuyumeCore.instance.playerState.currentTrack.isEmpty;
                final offset = hasTrack
                    ? FloatingMiniPlayer.height + FloatingMiniPlayer.gap * 2
                    : 0.0;
                return Padding(
                  padding: EdgeInsets.only(bottom: offset),
                  child: FloatingActionButton(
                    onPressed: _showCreatePlaylistDialog,
                    backgroundColor: colors.accent,
                    child: Icon(Icons.add, color: colors.background),
                  ),
                );
              },
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            LibraryTopBar(
              searchHint: 'Search a playlist...',
              searchQuery: _searchQuery,
              onSearchChanged: (q) => setState(() => _searchQuery = q),
              currentLayout: _layout,
              onLayoutChanged: (l) => setState(() => _layout = l),
              onMoreTap: () => _showSortDialog(context, colors),
            ),
            _buildTabBar(colors),
            Expanded(child: _buildTabContent(colors)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(NatsuyumeColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          _Tab(
            label: 'Built-in',
            active: _activeTab == _PlaylistTab.builtIn,
            colors: colors,
            onTap: () => setState(() => _activeTab = _PlaylistTab.builtIn),
          ),
          const SizedBox(width: 8),
          _Tab(
            label: 'My Playlists',
            active: _activeTab == _PlaylistTab.myPlaylists,
            colors: colors,
            onTap: () => setState(() => _activeTab = _PlaylistTab.myPlaylists),
          ),
          const SizedBox(width: 8),
          _Tab(
            label: 'External',
            active: _activeTab == _PlaylistTab.external,
            colors: colors,
            onTap: () => setState(() => _activeTab = _PlaylistTab.external),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(NatsuyumeColorScheme colors) {
    switch (_activeTab) {
      case _PlaylistTab.builtIn:
        return _buildBuiltInList(colors);
      case _PlaylistTab.myPlaylists:
        return _buildMyPlaylists(colors);
      case _PlaylistTab.external:
        return _buildEmptyState(
          colors,
          icon: Icons.folder_open_outlined,
          message: 'No external playlists found',
          hint: 'Import an .M3U or .M3U8 file to get started',
        );
    }
  }

  Widget _buildBuiltInList(NatsuyumeColorScheme colors) {
    final items = [
      (
        Icons.library_music_outlined,
        'All Songs',
        'Your entire library',
        _allSongsId,
      ),
      (
        Icons.favorite_outline,
        'Favorites',
        'Songs you\'ve liked',
        _favoritesId,
      ),
      (Icons.trending_up, 'Most Played', 'Coming soon', _mostPlayedId),
      (Icons.fiber_new_outlined, 'Not Played', 'Coming soon', _notPlayedId),
    ];

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final (icon, label, hint, id) = items[index];
        final isStub = id == _mostPlayedId || id == _notPlayedId;

        return GestureDetector(
          onTap: isStub
              ? null
              : () => _openPlaylist(
                  PlaylistData(id: id, name: label, songCount: 0),
                ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isStub
                  ? colors.surface.withValues(alpha: 0.5)
                  : colors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: isStub
                        ? colors.surfaceVariant
                        : colors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: isStub ? colors.onSurfaceVariant : colors.accent,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isStub ? colors.onSurfaceVariant : colors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hint,
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMyPlaylists(NatsuyumeColorScheme colors) {
    final playlists = _filteredPlaylists;

    if (playlists.isEmpty) {
      return _buildEmptyState(
        colors,
        icon: Icons.queue_music,
        message: 'No playlists yet',
        hint: null,
      );
    }

    return _layout == LibraryLayout.grid
        ? _buildGrid(playlists, colors)
        : _buildList(playlists, colors);
  }

  Widget _buildEmptyState(
    NatsuyumeColorScheme colors, {
    required IconData icon,
    required String message,
    String? hint,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: colors.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(fontSize: 15, color: colors.onSurfaceVariant),
          ),
          if (hint != null) ...[
            const SizedBox(height: 6),
            Text(
              hint,
              style: TextStyle(
                fontSize: 12,
                color: colors.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGrid(List<PlaylistData> playlists, NatsuyumeColorScheme colors) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
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

// ---------------------------------------------------------------------------
// Tab chip widget
// ---------------------------------------------------------------------------

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final NatsuyumeColorScheme colors;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.active,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? colors.accent.withValues(alpha: 0.15)
              : colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: active
              ? Border.all(color: colors.accent.withValues(alpha: 0.4))
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? colors.accent : colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
