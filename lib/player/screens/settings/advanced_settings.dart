import 'package:flutter/material.dart';
import '../../../theme/natsuyume_theme.dart';
import '../../../widgets/settings_tile.dart';
import '../../../widgets/settings_section.dart';

class AdvancedSettingsScreen extends StatefulWidget {
  const AdvancedSettingsScreen({super.key});

  @override
  State<AdvancedSettingsScreen> createState() => _AdvancedSettingsScreenState();
}

class _AdvancedSettingsScreenState extends State<AdvancedSettingsScreen> {
  bool _placeholder1 = true;

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
                    'Advanced',
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
                  title: 'What do I add here lol',
                  value: _placeholder1,
                  onChanged: (v) => setState(() => _placeholder1 = v),
                ),
                SettingsTile(
                  title: 'Upcoming features maybe?',
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
