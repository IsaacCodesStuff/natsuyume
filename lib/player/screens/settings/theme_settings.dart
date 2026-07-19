import 'package:flutter/material.dart';
import '../../../theme/natsuyume_theme.dart';
import '../../../theme/theme_registry.dart';
import '../../../widgets/settings_tile.dart';
import '../../../widgets/settings_section.dart';
import 'manual_theme_screen.dart';

enum ThemeStyle {
  tonalSpot,
  vibrant,
  expressive,
  spritz,
  rainbow,
  fruitSalad,
  neutral,
  monochrome,
  fidelity,
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
      case ThemeStyle.rainbow:
        return 'Rainbow';
      case ThemeStyle.fruitSalad:
        return 'Fruit Salad';
      case ThemeStyle.neutral:
        return 'Neutral';
      case ThemeStyle.monochrome:
        return 'Monochrome';
      case ThemeStyle.fidelity:
        return 'Fidelity';
    }
  }
}

class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  ThemeStyle _themeStyle = ThemeStyle.tonalSpot;
  late String _selectedThemeId;

  @override
  void initState() {
    super.initState();
    _selectedThemeId = ThemeRegistry.instance.selectedThemeId;
    ThemeRegistry.instance.addListener(_onRegistryChanged);
  }

  @override
  void dispose() {
    ThemeRegistry.instance.removeListener(_onRegistryChanged);
    super.dispose();
  }

  void _onRegistryChanged() {
    setState(() {
      _selectedThemeId = ThemeRegistry.instance.selectedThemeId;
    });
  }

  void _showPlayerThemeDialog(NatsuyumeColorScheme colors) {
    final available = ThemeRegistry.instance.availableThemes;

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
          children: available.map((entry) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                entry.label,
                style: TextStyle(fontSize: 15, color: colors.onSurface),
              ),
              trailing: _selectedThemeId == entry.id
                  ? Icon(Icons.check, color: colors.accent)
                  : null,
              onTap: () {
                ThemeRegistry.instance.selectTheme(entry.id);
                setState(() => _selectedThemeId = entry.id);
                // Apply the theme
                final newColors = NatsuyumeColorScheme.fromId(entry.id);
                NatsuyumeTheme.of(context).onThemeChange(newColors);
                Navigator.pop(context);
                // If manual, open the manual theme screen
                if (entry.id == 'manual') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ManualThemeScreen(),
                    ),
                  );
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

  void _showThemeStyleDialog(NatsuyumeColorScheme colors) {
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
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                style.label,
                style: TextStyle(fontSize: 15, color: colors.onSurface),
              ),
              trailing: _themeStyle == style
                  ? Icon(Icons.check, color: colors.accent)
                  : null,
              onTap: () {
                setState(() => _themeStyle = style);
                Navigator.pop(context);
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

  String get _selectedThemeLabel => ThemeRegistry.instance.availableThemes
      .firstWhere(
        (e) => e.id == _selectedThemeId,
        orElse: () => ThemeRegistry.builtInThemes.first,
      )
      .label;

  @override
  Widget build(BuildContext context) {
    final colors = NatsuyumeTheme.of(context).colors;
    final isManual = _selectedThemeId == 'manual';

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
                  subtitle: _selectedThemeLabel,
                  onTap: () => _showPlayerThemeDialog(colors),
                ),
                SettingsTile(
                  title: 'Theme style',
                  subtitle: _themeStyle.label,
                  onTap: () => _showThemeStyleDialog(colors),
                ),
                SettingsTile(
                  title: 'Customize colors',
                  subtitle: 'Manually define theme colors',
                  enabled: isManual,
                  onTap: isManual
                      ? () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ManualThemeScreen(),
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
