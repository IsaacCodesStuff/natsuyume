import 'package:flutter/material.dart';
import '../../theme/natsuyume_theme.dart';
import '../../widgets/settings_tile.dart';
import '../../widgets/settings_section.dart';
import '../../widgets/slide_route.dart';
import 'settings/playback_settings.dart';
import 'settings/theme_settings.dart';
import 'settings/library_settings.dart';
import 'settings/backup_settings.dart';
import 'settings/advanced_settings.dart';
import 'settings/settings_settings.dart';
import 'settings/about_settings.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  void _navigate(BuildContext context, Widget screen) {
    Navigator.of(context).push(SlideRoute(page: screen));
  }

  @override
  Widget build(BuildContext context) {
    final colors = NatsuyumeTheme.of(context).colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 24),
                  // Logo
                  Center(
                    child: Image.asset(
                      'assets/images/welcome_logo.png',
                      width: 100,
                      height: 100,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SettingsSection(
                    children: [
                      SettingsTile(
                        title: 'Playback',
                        icon: Icons.play_circle_outline,
                        trailing: Icon(
                          Icons.chevron_right,
                          color: colors.onSurfaceVariant,
                        ),
                        onTap: () =>
                            _navigate(context, const PlaybackSettingsScreen()),
                      ),
                      SettingsTile(
                        title: 'Theme',
                        icon: Icons.palette_outlined,
                        trailing: Icon(
                          Icons.chevron_right,
                          color: colors.onSurfaceVariant,
                        ),
                        onTap: () =>
                            _navigate(context, const ThemeSettingsScreen()),
                      ),
                      SettingsTile(
                        title: 'Library',
                        icon: Icons.library_music_outlined,
                        trailing: Icon(
                          Icons.chevron_right,
                          color: colors.onSurfaceVariant,
                        ),
                        onTap: () =>
                            _navigate(context, const LibrarySettingsScreen()),
                      ),
                      SettingsTile(
                        title: 'Backup',
                        icon: Icons.backup_outlined,
                        trailing: Icon(
                          Icons.chevron_right,
                          color: colors.onSurfaceVariant,
                        ),
                        onTap: () =>
                            _navigate(context, const BackupSettingsScreen()),
                      ),
                      SettingsTile(
                        title: 'Advanced',
                        icon: Icons.tune_outlined,
                        trailing: Icon(
                          Icons.chevron_right,
                          color: colors.onSurfaceVariant,
                        ),
                        onTap: () =>
                            _navigate(context, const AdvancedSettingsScreen()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SettingsSection(
                    children: [
                      SettingsTile(
                        title: 'Settings',
                        icon: Icons.settings_outlined,
                        trailing: Icon(
                          Icons.chevron_right,
                          color: colors.onSurfaceVariant,
                        ),
                        onTap: () =>
                            _navigate(context, const SettingsSettingsScreen()),
                      ),
                      SettingsTile(
                        title: 'About',
                        icon: Icons.info_outline,
                        trailing: Icon(
                          Icons.chevron_right,
                          color: colors.onSurfaceVariant,
                        ),
                        onTap: () =>
                            _navigate(context, const AboutSettingsScreen()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
