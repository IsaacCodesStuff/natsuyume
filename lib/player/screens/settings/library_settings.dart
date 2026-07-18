import 'package:flutter/material.dart';
import '../../../theme/natsuyume_theme.dart';
import '../../../widgets/settings_tile.dart';
import '../../../widgets/settings_section.dart';

class LibrarySettingsScreen extends StatelessWidget {
  const LibrarySettingsScreen({super.key});

  void _showConfirmDialog(
    BuildContext context,
    NatsuyumeColorScheme colors, {
    required String title,
    required String message,
    required String confirmLabel,
    required VoidCallback onConfirm,
    bool destructive = false,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            fontSize: 14,
            color: colors.onSurfaceVariant,
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
              Navigator.pop(context);
              onConfirm();
            },
            child: Text(
              confirmLabel,
              style: TextStyle(
                color: destructive ? Colors.red : colors.accent,
              ),
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
                    'Library',
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
                  title: 'Scan for folders',
                  onTap: () {
                    // Wired to core in 0.8.x
                  },
                ),
                SettingsTile(
                  title: 'Manage scanned folders',
                  onTap: () {
                    // Wired to core in 0.8.x
                  },
                ),
                SettingsTile(
                  title: 'Manage user data',
                  onTap: () {
                    _showConfirmDialog(
                      context,
                      colors,
                      title: 'Manage user data',
                      message:
                          'This will let you view and manage your stored user data. This feature will be fully available in a future update.',
                      confirmLabel: 'OK',
                      onConfirm: () {},
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            SettingsSection(
              title: 'CSV',
              children: [
                SettingsTile(
                  title: 'Import from CSV',
                  subtitle: 'Post-0.8.x feature',
                  enabled: false,
                  onTap: null,
                ),
                SettingsTile(
                  title: 'Export to CSV',
                  subtitle: 'Post-0.8.x feature',
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