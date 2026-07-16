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

  // Future: dynamic scheme will be generated from album art here
  static NatsuyumeColorScheme fromSeedColor(Color seed) => dark;
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
