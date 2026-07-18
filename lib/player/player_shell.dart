import 'package:flutter/material.dart';
import '../theme/natsuyume_theme.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/mini_player.dart';
import 'screens/queue_screen.dart';
import 'screens/albums_screen.dart';
import 'screens/artists_screen.dart';
import 'screens/playlists_screen.dart';
import 'screens/now_playing_screen.dart';
import 'screens/more_screen.dart';

class PlayerShell extends StatefulWidget {
  const PlayerShell({super.key});

  @override
  State<PlayerShell> createState() => _PlayerShellState();
}

class _PlayerShellState extends State<PlayerShell> {
  PlayerTab _currentTab = PlayerTab.queues;

  // Placeholder player state — will be wired to core in 0.8.x
  bool _isPlaying = false;
  bool _isFavorite = false;

  final MiniPlayerData _currentTrack = const MiniPlayerData(
    title: 'Turquoise',
    artist: 'Turquoise',
    album: '水瀬いのり',
    isPlaying: false,
    isFavorite: false,
  );

  Widget _buildCurrentScreen() {
    switch (_currentTab) {
      case PlayerTab.queues:
        return const QueueScreen();
      case PlayerTab.albums:
        return const AlbumsScreen();
      case PlayerTab.artists:
        return const ArtistsScreen();
      case PlayerTab.playlists:
        return const PlaylistsScreen();
      case PlayerTab.settings:
        return const MoreScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = NatsuyumeTheme.of(context).colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          Expanded(child: _buildCurrentScreen()),
          MiniPlayer(
            data: MiniPlayerData(
              title: _currentTrack.title,
              artist: _currentTrack.artist,
              album: _currentTrack.album,
              albumArt: _currentTrack.albumArt,
              isPlaying: _isPlaying,
              isFavorite: _isFavorite,
            ),
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const FractionallySizedBox(
                  heightFactor: 1.0,
                  child: NowPlayingScreen(),
                ),
              );
            },
            onPlayPause: () {
              setState(() => _isPlaying = !_isPlaying);
            },
            onPrevious: () {},
            onNext: () {},
            onFavorite: () {
              setState(() => _isFavorite = !_isFavorite);
            },
          ),
          NatsuyumeBottomNavBar(
            currentTab: _currentTab,
            onTabSelected: (tab) {
              setState(() => _currentTab = tab);
            },
          ),
        ],
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String label;

  const _PlaceholderScreen({required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = NatsuyumeTheme.of(context).colors;

    return Center(
      child: Text(
        '$label\n(coming soon)',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 20, color: colors.onSurfaceVariant),
      ),
    );
  }
}
