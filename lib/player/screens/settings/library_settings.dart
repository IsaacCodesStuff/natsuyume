import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/natsuyume_core.dart';
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
          style: TextStyle(fontSize: 14, color: colors.onSurfaceVariant),
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
              style: TextStyle(color: destructive ? Colors.red : colors.accent),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndScanFolder(BuildContext context) async {
    final core = NatsuyumeCore.instance;

    // Don't allow a new scan while one is running
    if (core.scanState.isScanning) return;

    // Call getDirectoryPath() directly
    final result = await FilePicker.platform.getDirectoryPath();
    if (result == null) return; // user cancelled

    core.addScanFolder(result);
    // addScanFolder already triggers a scan internally,
    // but call rescanAllFolders to be explicit and handle
    // the case where the folder was already known.
    core.rescanAllFolders();
  }

  @override
  Widget build(BuildContext context) {
    final colors = NatsuyumeTheme.of(context).colors;
    final core = NatsuyumeCore.instance;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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

            // Scan progress banner
            ListenableBuilder(
              listenable: core.scanState,
              builder: (context, _) {
                final s = core.scanState;
                if (!s.isScanning && s.total == 0)
                  return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        if (s.isScanning) ...[
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.accent,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ] else ...[
                          Icon(
                            Icons.check_circle_outline,
                            size: 18,
                            color: colors.accent,
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Text(
                            s.isScanning
                                ? 'Scanning… ${s.progress} / ${s.total}'
                                : 'Scan complete — ${s.total} tracks found',
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.onSurface,
                            ),
                          ),
                        ),
                        if (s.isScanning)
                          GestureDetector(
                            onTap: core.cancelScan,
                            child: Icon(
                              Icons.close,
                              size: 18,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Settings tiles
            SettingsSection(
              children: [
                SettingsTile(
                  title: 'Scan for folders',
                  onTap: () => _pickAndScanFolder(context),
                ),
                SettingsTile(
                  title: 'Manage scanned folders',
                  onTap: () {
                    // Phase 3A: placeholder — folder list screen in next step
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Coming in next step')),
                    );
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
                          'This will let you view and manage your stored '
                          'user data. This feature will be fully available '
                          'in a future update.',
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
