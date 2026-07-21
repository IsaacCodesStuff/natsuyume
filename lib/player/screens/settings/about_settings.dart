import 'package:flutter/material.dart';
import '../../../theme/natsuyume_theme.dart';
import '../../../widgets/settings_section.dart';
import '../../../widgets/settings_tile.dart';
import '../../../widgets/slide_route.dart';
import 'easter_egg_screen.dart';
import 'package:natsuyume/core/natsuyume_core.dart'; // adjust import path if needed

class AboutSettingsScreen extends StatefulWidget {
  const AboutSettingsScreen({super.key});

  @override
  State<AboutSettingsScreen> createState() => _AboutSettingsScreenState();
}

class _AboutSettingsScreenState extends State<AboutSettingsScreen> {
  int _tapCount = 0;
  bool _easterEggUnlocked = false;

  void _onVerseTap() {
    if (_easterEggUnlocked) {
      _navigateToEasterEgg();
      return;
    }

    setState(() => _tapCount++);

    if (_tapCount >= 7) {
      setState(() => _easterEggUnlocked = true);
      _showUnlockedSnackbar();
    } else {
      final remaining = 7 - _tapCount;
      _showTapHintSnackbar(remaining);
    }
  }

  void _showTapHintSnackbar(int remaining) {
    final colors = NatsuyumeTheme.of(context).colors;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '$remaining more tap${remaining == 1 ? '' : 's'} to unlock developer options.',
            style: TextStyle(color: colors.onSurface),
          ),
          backgroundColor: colors.surface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _showUnlockedSnackbar() {
    final colors = NatsuyumeTheme.of(context).colors;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '??? has been unlocked.',
            style: TextStyle(color: colors.onSurface),
          ),
          backgroundColor: colors.surface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  void _navigateToEasterEgg() {
    Navigator.of(context).push(SlideRoute(page: const EasterEggScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final colors = NatsuyumeTheme.of(context).colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
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
                    'About',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Logo
            Center(
              child: Image.asset(
                'assets/images/welcome_logo.png',
                width: 100,
                height: 100,
              ),
            ),
            const SizedBox(height: 24),
            SettingsSection(
              children: [
                SettingsTile(
                  title: 'Version',
                  subtitle:
                      'Natsuyume internal beta build ${NatsuyumeCore.instance.version}',
                  onTap: null,
                ),
                SettingsTile(
                  title: 'Test Playback',
                  subtitle: 'Tap to play Summer Challenger.flac',
                  onTap: () async {
                    await NatsuyumeCore.instance.openFile(
                      '/storage/emulated/0/Music/VideoToMp3/AudioFormat/Summer Challenger.flac',
                    );
                  },
                ),
                SettingsTile(
                  title: 'Pause',
                  subtitle: 'Tap to pause',
                  onTap: () => NatsuyumeCore.instance.pause(),
                ),
                SettingsTile(
                  title: 'Play',
                  subtitle: 'Tap to resume',
                  onTap: () => NatsuyumeCore.instance.play(),
                ),
                SettingsTile(
                  title: 'Open source licenses',
                  onTap: () {
                    showLicensePage(context: context);
                  },
                ),
                SettingsTile(title: "What's new", onTap: () {}),
              ],
            ),
            const SizedBox(height: 24),
            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(color: NatsuyumeTheme.of(context).colors.divider),
            ),
            const SizedBox(height: 24),
            // Developer card
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: colors.surfaceVariant,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'IsaacCodesStuff',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Developer',
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // Easter egg trigger verse
            GestureDetector(
              onTap: _onVerseTap,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  child: Text(
                    '"May God\'s will be done."',
                    style: TextStyle(
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                      color: _easterEggUnlocked
                          ? colors.accent
                          : colors.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            // Show ??? entry if unlocked
            if (_easterEggUnlocked) ...[
              const SizedBox(height: 8),
              SettingsSection(
                children: [
                  SettingsTile(
                    title: '???',
                    onTap: _navigateToEasterEgg,
                    trailing: Icon(
                      Icons.chevron_right,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
