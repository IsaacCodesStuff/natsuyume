import 'package:flutter/material.dart';
import '../../../theme/natsuyume_theme.dart';
import '../../../widgets/settings_tile.dart';
import '../../../widgets/settings_section.dart';

class SettingsSettingsScreen extends StatefulWidget {
  const SettingsSettingsScreen({super.key});

  @override
  State<SettingsSettingsScreen> createState() => _SettingsSettingsScreenState();
}

class _SettingsSettingsScreenState extends State<SettingsSettingsScreen> {
  bool _placeholder1 = false;

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
                    'Settings',
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
                  title: 'I have no idea what to add here',
                  value: _placeholder1,
                  onChanged: (v) => setState(() => _placeholder1 = v),
                ),
                SettingsTile(
                  title: 'More upcoming features',
                  subtitle: 'To be determined',
                  enabled: false,
                  onTap: null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
