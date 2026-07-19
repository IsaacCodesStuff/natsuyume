import 'package:flutter/material.dart';

class NatsuyumeColorScheme {
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color primary;
  final Color primaryVariant;
  final Color onBackground;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color accent;
  final Color divider;

  // Optional gradient — overrides background when set
  final Gradient? backgroundGradient;

  const NatsuyumeColorScheme({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.primary,
    required this.primaryVariant,
    required this.onBackground,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.accent,
    required this.divider,
    this.backgroundGradient,
  });

  static const dark = NatsuyumeColorScheme(
    background: Color(0xFF1A1A2E),
    surface: Color(0xFF252538),
    surfaceVariant: Color(0xFF2F2F45),
    primary: Color(0xFFD0C4E8),
    primaryVariant: Color(0xFFB0A4C8),
    onBackground: Color(0xFFE8E0F0),
    onSurface: Color(0xFFD0C4E8),
    onSurfaceVariant: Color(0xFF9A8FB0),
    accent: Color(0xFFB08ED0),
    divider: Color(0xFF3A3850),
  );

  static const light = NatsuyumeColorScheme(
    background: Color(0xFFF5F0FF),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFEDE8F5),
    primary: Color(0xFF4A3F6B),
    primaryVariant: Color(0xFF6A5F8B),
    onBackground: Color(0xFF1A1A2E),
    onSurface: Color(0xFF2A2040),
    onSurfaceVariant: Color(0xFF6A5F8B),
    accent: Color(0xFF7C5CBF),
    divider: Color(0xFFD8D0E8),
  );

  // Natsuyume system theme — gradient background
  static const natsuyume = NatsuyumeColorScheme(
    background: Color(0xFF2C2B3A),
    surface: Color(0xFF353448),
    surfaceVariant: Color(0xFF3F3E55),
    primary: Color(0xFFE8D0F0),
    primaryVariant: Color(0xFFD0B8E8),
    onBackground: Color(0xFFF0E8FF),
    onSurface: Color(0xFFE8D0F0),
    onSurfaceVariant: Color(0xFFB0A0C8),
    accent: Color(0xFFD080E0),
    divider: Color(0xFF454360),
    backgroundGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2C1B4A), Color(0xFF1A2C4A)],
    ),
  );

  /// Dynamic scheme — generated from album art seed color in 0.8.x
  static NatsuyumeColorScheme fromSeedColor(Color seed) => dark;

  /// Manual scheme — user defined in 0.9.x
  static NatsuyumeColorScheme manual({
    required Color background,
    required Color surface,
    required Color surfaceVariant,
    required Color primary,
    required Color primaryVariant,
    required Color onBackground,
    required Color onSurface,
    required Color onSurfaceVariant,
    required Color accent,
    required Color divider,
  }) => NatsuyumeColorScheme(
    background: background,
    surface: surface,
    surfaceVariant: surfaceVariant,
    primary: primary,
    primaryVariant: primaryVariant,
    onBackground: onBackground,
    onSurface: onSurface,
    onSurfaceVariant: onSurfaceVariant,
    accent: accent,
    divider: divider,
  );

  /// Resolve a scheme by theme id from ThemeRegistry
  static NatsuyumeColorScheme fromId(String id) {
    switch (id) {
      case 'light':
        return light;
      case 'dark':
        return dark;
      case 'natsuyume':
        return natsuyume;
      // All other secret themes stub to dark for now
      // — each will get their own scheme in 0.9.x
      default:
        return dark;
    }
  }
}

class NatsuyumeTheme extends InheritedWidget {
  final NatsuyumeColorScheme colors;
  final void Function(NatsuyumeColorScheme newColors) onThemeChange;

  const NatsuyumeTheme({
    super.key,
    required this.colors,
    required this.onThemeChange,
    required super.child,
  });

  static NatsuyumeTheme of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<NatsuyumeTheme>();
    assert(result != null, 'No NatsuyumeTheme found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(NatsuyumeTheme oldWidget) =>
      colors != oldWidget.colors;
}

class NatsuyumeThemeProvider extends StatefulWidget {
  final Widget child;

  const NatsuyumeThemeProvider({super.key, required this.child});

  @override
  State<NatsuyumeThemeProvider> createState() => _NatsuyumeThemeProviderState();
}

class _NatsuyumeThemeProviderState extends State<NatsuyumeThemeProvider> {
  NatsuyumeColorScheme _colors = NatsuyumeColorScheme.dark;

  void _updateTheme(NatsuyumeColorScheme newColors) {
    setState(() => _colors = newColors);
  }

  @override
  Widget build(BuildContext context) {
    return NatsuyumeTheme(
      colors: _colors,
      onThemeChange: _updateTheme,
      child: widget.child,
    );
  }
}

/// Helper widget that applies a gradient background when the current
/// theme defines one, falling back to a solid color otherwise.
class NatsuyumeBackground extends StatelessWidget {
  final Widget child;

  const NatsuyumeBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = NatsuyumeTheme.of(context).colors;

    return Container(
      decoration: colors.backgroundGradient != null
          ? BoxDecoration(gradient: colors.backgroundGradient)
          : BoxDecoration(color: colors.background),
      child: child,
    );
  }
}
