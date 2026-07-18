import 'package:flutter/material.dart';
import '../../../theme/natsuyume_theme.dart';
import '../../../widgets/settings_tile.dart';
import '../../../widgets/settings_section.dart';

class PlaybackSettingsScreen extends StatefulWidget {
  const PlaybackSettingsScreen({super.key});

  @override
  State<PlaybackSettingsScreen> createState() => _PlaybackSettingsScreenState();
}

class _PlaybackSettingsScreenState extends State<PlaybackSettingsScreen> {
  bool _gaplessPlayback = true;
  double _countPlaybackAfter = 0.5;

  void _showCountPlaybackDialog() {
    final colors = NatsuyumeTheme.of(context).colors;
    double tempValue = _countPlaybackAfter;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Count playback after...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Count a play after ${(tempValue * 100).round()}% of the song has been played.',
                style: TextStyle(fontSize: 14, color: colors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: colors.accent,
                  inactiveTrackColor: colors.surfaceVariant,
                  thumbColor: colors.accent,
                  overlayColor: colors.accent.withOpacity(0.1),
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 8,
                  ),
                ),
                child: Slider(
                  value: tempValue,
                  min: 0.1,
                  max: 1.0,
                  divisions: 18,
                  onChanged: (v) => setDialogState(() => tempValue = v),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '10%',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '100%',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
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
                setState(() => _countPlaybackAfter = tempValue);
                Navigator.pop(context);
              },
              child: Text('Save', style: TextStyle(color: colors.accent)),
            ),
          ],
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: colors.onSurface),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Text(
                    'Playback',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SettingsSection(
              children: [
                SettingsToggleTile(
                  title: 'Gapless playback',
                  value: _gaplessPlayback,
                  onChanged: (v) => setState(() => _gaplessPlayback = v),
                ),
                SettingsTile(
                  title: 'Count playback after...',
                  subtitle:
                      '${(_countPlaybackAfter * 100).round()}% of song duration',
                  onTap: _showCountPlaybackDialog,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
