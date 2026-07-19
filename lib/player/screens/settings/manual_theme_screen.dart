import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../../theme/natsuyume_theme.dart';
import '../../../widgets/settings_section.dart';
import '../../../widgets/settings_tile.dart';

class ManualThemeScreen extends StatefulWidget {
  const ManualThemeScreen({super.key});

  @override
  State<ManualThemeScreen> createState() => _ManualThemeScreenState();
}

class _ManualThemeScreenState extends State<ManualThemeScreen> {
  late Map<String, Color> _colors;

  @override
  void initState() {
    super.initState();
    // Seed with current theme values
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final current = NatsuyumeTheme.of(context).colors;
      setState(() {
        _colors = {
          'background': current.background,
          'surface': current.surface,
          'surfaceVariant': current.surfaceVariant,
          'onBackground': current.onBackground,
          'onSurface': current.onSurface,
          'onSurfaceVariant': current.onSurfaceVariant,
          'accent': current.accent,
          'divider': current.divider,
          'primary': current.primary,
          'primaryVariant': current.primaryVariant,
        };
      });
    });

    _colors = {
      'background': const Color(0xFF1A1A2E),
      'surface': const Color(0xFF252538),
      'surfaceVariant': const Color(0xFF2F2F45),
      'onBackground': const Color(0xFFE8E0F0),
      'onSurface': const Color(0xFFD0C4E8),
      'onSurfaceVariant': const Color(0xFF9A8FB0),
      'accent': const Color(0xFFB08ED0),
      'divider': const Color(0xFF3A3850),
      'primary': const Color(0xFFD0C4E8),
      'primaryVariant': const Color(0xFFB0A4C8),
    };
  }

  void _pickColor(String key, NatsuyumeColorScheme colors) {
    Color pickerColor = _colors[key]!;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          _labelFor(key),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickerColor,
            onColorChanged: (c) => pickerColor = c,
            enableAlpha: false,
            labelTypes: const [ColorLabelType.rgb, ColorLabelType.hsv],
            pickerAreaHeightPercent: 0.7,
          ),
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
              setState(() => _colors[key] = pickerColor);
              _applyColors();
              Navigator.pop(context);
            },
            child: Text('Apply', style: TextStyle(color: colors.accent)),
          ),
        ],
      ),
    );
  }

  void _applyColors() {
    final scheme = NatsuyumeColorScheme.manual(
      background: _colors['background']!,
      surface: _colors['surface']!,
      surfaceVariant: _colors['surfaceVariant']!,
      primary: _colors['primary']!,
      primaryVariant: _colors['primaryVariant']!,
      onBackground: _colors['onBackground']!,
      onSurface: _colors['onSurface']!,
      onSurfaceVariant: _colors['onSurfaceVariant']!,
      accent: _colors['accent']!,
      divider: _colors['divider']!,
    );
    NatsuyumeTheme.of(context).onThemeChange(scheme);
  }

  String _labelFor(String key) {
    const labels = {
      'background': 'Background',
      'surface': 'Surface',
      'surfaceVariant': 'Surface Variant',
      'onBackground': 'On Background',
      'onSurface': 'On Surface',
      'onSurfaceVariant': 'On Surface Variant',
      'accent': 'Accent',
      'divider': 'Divider',
      'primary': 'Primary',
      'primaryVariant': 'Primary Variant',
    };
    return labels[key] ?? key;
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
                    'Customize colors',
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
                    title: 'BACKGROUNDS',
                    children:
                        ['background', 'surface', 'surfaceVariant', 'divider']
                            .map(
                              (key) => _ColorTile(
                                label: _labelFor(key),
                                color: _colors[key]!,
                                colors: colors,
                                onTap: () => _pickColor(key, colors),
                              ),
                            )
                            .toList(),
                  ),
                  const SizedBox(height: 8),
                  SettingsSection(
                    title: 'TEXT & ICONS',
                    children: ['onBackground', 'onSurface', 'onSurfaceVariant']
                        .map(
                          (key) => _ColorTile(
                            label: _labelFor(key),
                            color: _colors[key]!,
                            colors: colors,
                            onTap: () => _pickColor(key, colors),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  SettingsSection(
                    title: 'ACCENT & PRIMARY',
                    children: ['accent', 'primary', 'primaryVariant']
                        .map(
                          (key) => _ColorTile(
                            label: _labelFor(key),
                            color: _colors[key]!,
                            colors: colors,
                            onTap: () => _pickColor(key, colors),
                          ),
                        )
                        .toList(),
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

class _ColorTile extends StatelessWidget {
  final String label;
  final Color color;
  final NatsuyumeColorScheme colors;
  final VoidCallback onTap;

  const _ColorTile({
    required this.label,
    required this.color,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      title: label,
      subtitle:
          '#${color.toARGB32().toRadixString(16).toUpperCase().padLeft(8, '0').substring(2)}',
      onTap: onTap,
      trailing: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.divider, width: 1),
          ),
        ),
      ),
    );
  }
}
