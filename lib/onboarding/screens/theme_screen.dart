import 'package:flutter/material.dart';
import '../../theme/natsuyume_theme.dart';
import '../../theme/theme_registry.dart';

class ThemeScreen extends StatefulWidget {
  final VoidCallback onNext;
  const ThemeScreen({super.key, required this.onNext});

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  NatsuyumeMode _selected = NatsuyumeMode.light;

  void _selectMode(NatsuyumeMode mode) {
    setState(() => _selected = mode);
    ThemeRegistry.instance.selectMode(mode);
    NatsuyumeTheme.of(
      context,
    ).onThemeChange(ThemeRegistry.instance.currentScheme);
  }

  @override
  Widget build(BuildContext context) {
    final colors = NatsuyumeTheme.of(context).colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              Text(
                'Choose your theme',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: colors.onBackground,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You can always change this later in settings.',
                style: TextStyle(fontSize: 14, color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView(
                  children: [
                    _ThemeOption(
                      mode: NatsuyumeMode.light,
                      selected: _selected == NatsuyumeMode.light,
                      colors: colors,
                      onTap: () => _selectMode(NatsuyumeMode.light),
                      description:
                          'Soft and paper-like. Easy on the eyes indoors.',
                      previewBg: const Color(0xFFF2F6FE),
                      previewAccent: const Color(0xFF3A7FD4),
                    ),
                    const SizedBox(height: 12),
                    _ThemeOption(
                      mode: NatsuyumeMode.dark,
                      selected: _selected == NatsuyumeMode.dark,
                      colors: colors,
                      onTap: () => _selectMode(NatsuyumeMode.dark),
                      description:
                          'Deep dark theme. Great for low-light listening.',
                      previewBg: const Color(0xFF12131A),
                      previewAccent: const Color(0xFF90BFF9),
                    ),
                    const SizedBox(height: 12),
                    _ThemeOption(
                      mode: NatsuyumeMode.amoled,
                      selected: _selected == NatsuyumeMode.amoled,
                      colors: colors,
                      onTap: () => _selectMode(NatsuyumeMode.amoled),
                      description: 'Pure black. Saves battery on OLED screens.',
                      previewBg: const Color(0xFF000000),
                      previewAccent: const Color(0xFF90BFF9),
                    ),
                    const SizedBox(height: 12),
                    _ThemeOption(
                      mode: NatsuyumeMode.dynamic,
                      selected: _selected == NatsuyumeMode.dynamic,
                      colors: colors,
                      onTap: () => _selectMode(NatsuyumeMode.dynamic),
                      description: 'Colors shift to match your album art.',
                      previewBg: const Color(0xFF0E1420),
                      previewAccent: const Color(0xFF7EC8E3),
                    ),
                    const SizedBox(height: 12),
                    _ThemeOption(
                      mode: NatsuyumeMode.manual,
                      selected: _selected == NatsuyumeMode.manual,
                      colors: colors,
                      onTap: () => _selectMode(NatsuyumeMode.manual),
                      description: 'Define every color yourself.',
                      previewBg: const Color(0xFF1A1A2E),
                      previewAccent: const Color(0xFFE94560),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _PrimaryButton(
                label: 'Continue',
                onTap: widget.onNext,
                colors: colors,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final NatsuyumeMode mode;
  final bool selected;
  final NatsuyumeColorScheme colors;
  final VoidCallback onTap;
  final String description;
  final Color previewBg;
  final Color previewAccent;

  const _ThemeOption({
    required this.mode,
    required this.selected,
    required this.colors,
    required this.onTap,
    required this.description,
    required this.previewBg,
    required this.previewAccent,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? colors.accent.withValues(alpha: 0.12)
              : colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? colors.accent : colors.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Mini theme preview
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: previewBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.divider, width: 1),
              ),
              child: Center(
                child: Container(
                  width: 24,
                  height: 8,
                  decoration: BoxDecoration(
                    color: previewAccent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mode.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: selected ? colors.accent : colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: colors.accent, size: 22),
          ],
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final NatsuyumeColorScheme colors;

  const _PrimaryButton({
    required this.label,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: colors.accent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.background,
            ),
          ),
        ),
      ),
    );
  }
}
