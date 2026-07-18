import 'package:flutter/material.dart';
import '../../../theme/natsuyume_theme.dart';
import '../../../widgets/settings_section.dart';
import '../../../widgets/settings_tile.dart';

class UnlockedTheme {
  final String name;
  bool enabled;

  UnlockedTheme({required this.name, this.enabled = true});
}

class UnlockedThemesScreen extends StatefulWidget {
  const UnlockedThemesScreen({super.key});

  @override
  State<UnlockedThemesScreen> createState() => _UnlockedThemesScreenState();
}

class _UnlockedThemesScreenState extends State<UnlockedThemesScreen> {
  final List<UnlockedTheme> _themes = [
    UnlockedTheme(name: 'Natsuyume'),
    UnlockedTheme(name: 'Rem'),
    UnlockedTheme(name: 'Misaki'),
    UnlockedTheme(name: 'Hestia'),
    UnlockedTheme(name: 'Akane'),
    UnlockedTheme(name: 'Syalis'),
    UnlockedTheme(name: 'Liscia'),
    UnlockedTheme(name: 'Itsuki'),
    UnlockedTheme(name: 'Misumi'),
    UnlockedTheme(name: 'Berry Blossom'),
    UnlockedTheme(name: 'Jeanne'),
    UnlockedTheme(name: 'Yoshino'),
    UnlockedTheme(name: 'Erna'),
    UnlockedTheme(name: 'Beta'),
  ];

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
                    'Unlocked themes',
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
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  SettingsSection(
                    children: _themes.map((theme) {
                      return SettingsToggleTile(
                        title: theme.name,
                        value: theme.enabled,
                        onChanged: (v) {
                          setState(() => theme.enabled = v);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
