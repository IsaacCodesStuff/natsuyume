import 'package:flutter/material.dart';
import '../../../theme/natsuyume_theme.dart';
import '../../../widgets/settings_tile.dart';
import '../../../widgets/settings_section.dart';

enum PlayerTheme { light, dark, dynamic, manual }

enum ThemeStyle {
  tonalSpot,
  vibrant,
  expressive,
  spritz,
  rainbowTonalSpot,
  fruitSalad,
}

extension PlayerThemeLabel on PlayerTheme {
  String get label {
    switch (this) {
      case PlayerTheme.light:
        return 'Light';
      case PlayerTheme.dark:
        return 'Dark';
      case PlayerTheme.dynamic:
        return 'Dynamic';
      case PlayerTheme.manual:
        return 'Manual';
    }
  }
}

extension ThemeStyleLabel on ThemeStyle {
  String get label {
    switch (this) {
      case ThemeStyle.tonalSpot:
        return 'Tonal Spot';
      case ThemeStyle.vibrant:
        return 'Vibrant';
      case ThemeStyle.expressive:
        return 'Expressive';
      case ThemeStyle.spritz:
        return 'Spritz';
      case ThemeStyle.rainbowTonalSpot:
        return 'Rainbow Tonal Spot';
      case ThemeStyle.fruitSalad:
        return 'Fruit Salad';
    }
  }
}

class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  PlayerTheme _playerTheme = PlayerTheme.dynamic;
  ThemeStyle _themeStyle = ThemeStyle.tonalSpot;

  void _showPlayerThemeDialog() {
    final colors = NatsuyumeTheme.of(context).colors;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Default player theme',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: PlayerTheme.values.map((theme) {
            return RadioListTile<PlayerTheme>(
              value: theme,
              groupValue: _playerTheme,
              title: Text(
                theme.label,
                style: TextStyle(fontSize: 15, color: colors.onSurface),
              ),
              activeColor: colors.accent,
              onChanged: (v) {
                if (v != null) {
                  setState(() => _playerTheme = v);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  void _showThemeStyleDialog() {
    final colors = NatsuyumeTheme.of(context).colors;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Theme style',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeStyle.values.map((style) {
            return RadioListTile<ThemeStyle>(
              value: style,
              groupValue: _themeStyle,
              title: Text(
                style.label,
                style: TextStyle(fontSize: 15, color: colors.onSurface),
              ),
              activeColor: colors.accent,
              onChanged: (v) {
                if (v != null) {
                  setState(() => _themeStyle = v);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ),
        ],
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
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: colors.onSurface),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Text(
                    'Theme',
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
                SettingsTile(
                  title: 'Default player theme',
                  subtitle: _playerTheme.label,
                  onTap: _showPlayerThemeDialog,
                ),
                SettingsTile(
                  title: 'Theme style',
                  subtitle: _themeStyle.label,
                  onTap: _showThemeStyleDialog,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
