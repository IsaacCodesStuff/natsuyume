import 'package:flutter/material.dart';
import '../../../theme/natsuyume_theme.dart';
import '../../../theme/theme_registry.dart';
import '../../../widgets/settings_tile.dart';
import '../../../widgets/settings_section.dart';
import 'manual_theme_screen.dart';

class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  ThemeStyle _themeStyle = ThemeStyle.vibrant;

  @override
  void initState() {
    super.initState();
    _themeStyle = ThemeRegistry.instance.selectedThemeStyle;
    ThemeRegistry.instance.addListener(_onRegistryChanged);
  }

  @override
  void dispose() {
    ThemeRegistry.instance.removeListener(_onRegistryChanged);
    super.dispose();
  }

  void _onRegistryChanged() {
    setState(() {
      _themeStyle = ThemeRegistry.instance.selectedThemeStyle;
    });
  }

  void _applyCurrentScheme() {
    final scheme = ThemeRegistry.instance.currentScheme;
    NatsuyumeTheme.of(context).onThemeChange(scheme);
  }

  // -------------------------------------------------------------------------
  // Mode picker
  // -------------------------------------------------------------------------
  void _showModePicker(NatsuyumeColorScheme colors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Theme mode',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: NatsuyumeMode.values.map((mode) {
            final selected = ThemeRegistry.instance.selectedMode == mode;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                mode.label,
                style: TextStyle(fontSize: 15, color: colors.onSurface),
              ),
              subtitle: _modeDescription(mode, colors),
              trailing: selected
                  ? Icon(Icons.check, color: colors.accent)
                  : null,
              onTap: () {
                ThemeRegistry.instance.selectMode(mode);
                _applyCurrentScheme();
                Navigator.pop(context);
                if (mode == NatsuyumeMode.manual) {
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

  Widget? _modeDescription(NatsuyumeMode mode, NatsuyumeColorScheme colors) {
    const descriptions = {
      NatsuyumeMode.light: 'Soft paper-like light theme',
      NatsuyumeMode.dark: 'Deep dark theme, easy on the eyes',
      NatsuyumeMode.amoled: 'Pure black, saves battery on OLED screens',
      NatsuyumeMode.dynamic: 'Colors generated from album art',
      NatsuyumeMode.manual: 'You define every color',
    };
    final text = descriptions[mode];
    if (text == null) return null;
    return Text(
      text,
      style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
    );
  }

  // -------------------------------------------------------------------------
  // Palette picker
  // -------------------------------------------------------------------------
  void _showPalettePicker(NatsuyumeColorScheme colors) {
    final enabled = ThemeRegistry.instance.enabledPalettes;
    final available = [NatsuyumePalette.default_, ...enabled];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Color palette',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: available.map((palette) {
            final selected = ThemeRegistry.instance.selectedPalette == palette;
            final accents = NatsuyumeColorScheme.resolve(
              mode: ThemeRegistry.instance.selectedMode,
              palette: palette,
            );
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: accents.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.divider),
                ),
              ),
              title: Text(
                palette.label,
                style: TextStyle(fontSize: 15, color: colors.onSurface),
              ),
              trailing: selected
                  ? Icon(Icons.check, color: colors.accent)
                  : null,
              onTap: () {
                ThemeRegistry.instance.selectPalette(palette);
                _applyCurrentScheme();
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

  // -------------------------------------------------------------------------
  // Theme style picker — only relevant for Dynamic mode
  // -------------------------------------------------------------------------
  void _showStylePicker(NatsuyumeColorScheme colors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Dynamic theme style',
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
                ThemeRegistry.instance.selectThemeStyle(style);
                _applyCurrentScheme();
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

  @override
  Widget build(BuildContext context) {
    final colors = NatsuyumeTheme.of(context).colors;
    final registry = ThemeRegistry.instance;
    final mode = registry.selectedMode;
    final isDynamic = mode == NatsuyumeMode.dynamic;
    final isManual = mode == NatsuyumeMode.manual;
    final paletteDisabled = isDynamic || isManual;

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
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  SettingsSection(
                    title: 'MODE',
                    children: [
                      SettingsTile(
                        title: 'Theme mode',
                        subtitle: mode.label,
                        onTap: () => _showModePicker(colors),
                      ),
                      if (isDynamic)
                        SettingsTile(
                          title: 'Dynamic style',
                          subtitle: _themeStyle.label,
                          onTap: () => _showStylePicker(colors),
                        ),
                      if (isManual)
                        SettingsTile(
                          title: 'Customize colors',
                          subtitle: 'Manually define theme colors',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ManualThemeScreen(),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SettingsSection(
                    title: 'PALETTE',
                    children: [
                      SettingsTile(
                        title: 'Color palette',
                        subtitle: paletteDisabled
                            ? 'Not available in ${mode.label} mode'
                            : registry.selectedPalette.label,
                        enabled: !paletteDisabled,
                        onTap: paletteDisabled
                            ? null
                            : () => _showPalettePicker(colors),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
