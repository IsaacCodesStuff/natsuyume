import 'package:flutter/material.dart';
import '../../../theme/natsuyume_theme.dart';
import '../../../widgets/settings_tile.dart';
import '../../../widgets/settings_section.dart';
import '../../../widgets/slide_route.dart';
import 'unlocked_themes_screen.dart';
import '../../../theme/theme_registry.dart';

class EasterEggScreen extends StatefulWidget {
  const EasterEggScreen({super.key});

  @override
  State<EasterEggScreen> createState() => _EasterEggScreenState();
}

class _EasterEggScreenState extends State<EasterEggScreen> {
  void _showSecretCodeDialog() {
    final colors = NatsuyumeTheme.of(context).colors;
    final controller = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Type a secret code...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 16,
                  letterSpacing: 2,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter code...',
                  hintStyle: TextStyle(color: colors.onSurfaceVariant),
                  errorText: errorText,
                  errorStyle: const TextStyle(color: Colors.red),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: colors.divider),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: colors.accent),
                  ),
                  errorBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                  focusedErrorBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                ),
                onChanged: (_) {
                  if (errorText != null) {
                    setDialogState(() => errorText = null);
                  }
                },
              ),
            ],
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
                final code = controller.text.trim().toUpperCase();
                final themeName = ThemeRegistry.instance.unlockByCode(code);
                if (themeName != null) {
                  Navigator.pop(context);
                  _showThemeUnlockedToast(themeName);
                } else {
                  setDialogState(() => errorText = 'Wrong code, try again!');
                }
              },
              child: Text('Submit', style: TextStyle(color: colors.accent)),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeUnlockedToast(String themeName) {
    final colors = NatsuyumeTheme.of(context).colors;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🎉 New theme discovered: $themeName!',
          style: TextStyle(color: colors.onSurface),
        ),
        backgroundColor: colors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
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
                    '???',
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
                  title: 'Unlocked themes',
                  onTap: () => Navigator.of(
                    context,
                  ).push(SlideRoute(page: const UnlockedThemesScreen())),
                ),
                SettingsTile(
                  title: 'Type a secret code...',
                  onTap: _showSecretCodeDialog,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
