import 'package:flutter/material.dart';
import '../../../theme/natsuyume_theme.dart';
import '../../../theme/theme_registry.dart';
import '../../../widgets/settings_section.dart';
import '../../../widgets/settings_tile.dart';

class UnlockedThemesScreen extends StatefulWidget {
  const UnlockedThemesScreen({super.key});

  @override
  State<UnlockedThemesScreen> createState() => _UnlockedThemesScreenState();
}

class _UnlockedThemesScreenState extends State<UnlockedThemesScreen> {
  @override
  void initState() {
    super.initState();
    ThemeRegistry.instance.addListener(_onRegistryChanged);
  }

  @override
  void dispose() {
    ThemeRegistry.instance.removeListener(_onRegistryChanged);
    super.dispose();
  }

  void _onRegistryChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final colors = NatsuyumeTheme.of(context).colors;
    final unlocked = ThemeRegistry.instance.unlockedThemes;

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
              child: unlocked.isEmpty
                  ? Center(
                      child: Text(
                        'No themes unlocked yet.\nTry entering a secret code in ???.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        SettingsSection(
                          children: unlocked.map((theme) {
                            return SettingsToggleTile(
                              title: theme.label,
                              value: ThemeRegistry.instance.isEnabled(theme.id),
                              onChanged: (v) {
                                ThemeRegistry.instance.setEnabled(theme.id, v);
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
