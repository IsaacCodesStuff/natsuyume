import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// ThemeMode — how colors are generated
// ---------------------------------------------------------------------------
enum NatsuyumeMode {
  light,
  dark,
  amoled,
  dynamic, // generated from album art via palette_generator
  manual, // user-defined via ManualThemeScreen
}

extension NatsuyumeModeLabel on NatsuyumeMode {
  String get label {
    switch (this) {
      case NatsuyumeMode.light:
        return 'Light';
      case NatsuyumeMode.dark:
        return 'Dark';
      case NatsuyumeMode.amoled:
        return 'AMOLED';
      case NatsuyumeMode.dynamic:
        return 'Dynamic';
      case NatsuyumeMode.manual:
        return 'Manual';
    }
  }
}

// ThemeStyle enum stays — only active when mode is Dynamic
enum ThemeStyle {
  vibrant,
  tonalSpot,
  expressive,
  spritz,
  rainbow,
  fruitSalad,
  neutral,
  monochrome,
  fidelity,
}

extension ThemeStyleLabel on ThemeStyle {
  String get label {
    switch (this) {
      case ThemeStyle.vibrant:
        return 'Vibrant';
      case ThemeStyle.tonalSpot:
        return 'Tonal Spot';
      case ThemeStyle.expressive:
        return 'Expressive';
      case ThemeStyle.spritz:
        return 'Spritz';
      case ThemeStyle.rainbow:
        return 'Rainbow';
      case ThemeStyle.fruitSalad:
        return 'Fruit Salad';
      case ThemeStyle.neutral:
        return 'Neutral';
      case ThemeStyle.monochrome:
        return 'Monochrome';
      case ThemeStyle.fidelity:
        return 'Fidelity';
    }
  }
}

// ---------------------------------------------------------------------------
// ThemePalette — accent family override applied on top of a mode
// Ignored when mode is dynamic or manual.
// ---------------------------------------------------------------------------
enum NatsuyumePalette {
  default_, // no override — mode defines everything
  natsuyume,
  rem,
  hestia,
  misaki,
  akane,
  syalis,
  liscia,
  itsuki,
  misumi,
  berryblossom,
  jeanne,
  yoshino,
  erna,
  beta,
}

extension NatsuyumePaletteLabel on NatsuyumePalette {
  String get label {
    switch (this) {
      case NatsuyumePalette.default_:
        return 'Default';
      case NatsuyumePalette.natsuyume:
        return 'Natsuyume';
      case NatsuyumePalette.rem:
        return 'Rem';
      case NatsuyumePalette.hestia:
        return 'Hestia';
      case NatsuyumePalette.misaki:
        return 'Misaki';
      case NatsuyumePalette.akane:
        return 'Akane';
      case NatsuyumePalette.syalis:
        return 'Syalis';
      case NatsuyumePalette.liscia:
        return 'Liscia';
      case NatsuyumePalette.itsuki:
        return 'Itsuki';
      case NatsuyumePalette.misumi:
        return 'Misumi';
      case NatsuyumePalette.berryblossom:
        return 'Berry Blossom';
      case NatsuyumePalette.jeanne:
        return 'Jeanne';
      case NatsuyumePalette.yoshino:
        return 'Yoshino';
      case NatsuyumePalette.erna:
        return 'Erna';
      case NatsuyumePalette.beta:
        return 'Beta';
    }
  }

  bool get isSecret => this != NatsuyumePalette.default_;
}

// ---------------------------------------------------------------------------
// NatsuyumeColorScheme — the 10-field color contract
// ---------------------------------------------------------------------------
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

  // -------------------------------------------------------------------------
  // Built-in mode base schemes
  // -------------------------------------------------------------------------

  static const dark = NatsuyumeColorScheme(
    background: Color(0xFF0F1018),
    surface: Color(0xFF181922),
    surfaceVariant: Color(0xFF22242F),
    primary: Color(0xFFCCDFFB),
    primaryVariant: Color(0xFFF6E8DC),
    onBackground: Color(0xFFEBEFFB),
    onSurface: Color(0xFFCDD8F0),
    onSurfaceVariant: Color(0xFF8896B8),
    accent: Color(0xFF90BFF9),
    divider: Color(0xFF2A2C3A),
  );

  static const light = NatsuyumeColorScheme(
    background: Color(0xFFF2F6FE),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFDEEAFD),
    primary: Color(0xFF1A4A8C),
    primaryVariant: Color(0xFF2E62B0),
    onBackground: Color(0xFF0E1830),
    onSurface: Color(0xFF1A2540),
    onSurfaceVariant: Color(0xFF4A5E80),
    accent: Color(0xFF3A7FD4),
    divider: Color(0xFFBDD0F0),
  );

  static const amoled = NatsuyumeColorScheme(
    background: Color(0xFF000000),
    surface: Color(0xFF080A12),
    surfaceVariant: Color(0xFF10131E),
    primary: Color(0xFFCCDFFB),
    primaryVariant: Color(0xFFF6E8DC),
    onBackground: Color(0xFFEBEFFB),
    onSurface: Color(0xFFCDD8F0),
    onSurfaceVariant: Color(0xFF8896B8),
    accent: Color(0xFF90BFF9),
    divider: Color(0xFF141620),
  );

  // -------------------------------------------------------------------------
  // Palette accent overrides — applied on top of a mode's base scheme.
  // Returns accent, primary, primaryVariant for a given palette.
  // isDark drives which variant of the palette to use.
  // -------------------------------------------------------------------------
  static ({Color accent, Color primary, Color primaryVariant}) _paletteAccents(
    NatsuyumePalette palette,
    bool isDark,
  ) {
    switch (palette) {
      case NatsuyumePalette.default_:
        // No override — caller should not reach this
        return (
          accent: const Color(0xFF9A7BFF),
          primary: const Color(0xFFDCCBFF),
          primaryVariant: const Color(0xFFBBAEDD),
        );
      case NatsuyumePalette.natsuyume:
        return isDark
            ? (
                accent: const Color(0xFF90BFF9),
                primary: const Color(0xFFCCDFFB),
                primaryVariant: const Color(0xFFF6E8DC),
              )
            : (
                accent: const Color(0xFF3A7FD4),
                primary: const Color(0xFF1A4A8C),
                primaryVariant: const Color(0xFF8C5A3C),
              );
      case NatsuyumePalette.rem:
        return isDark
            ? (
                accent: const Color(0xFF6FA8FF),
                primary: const Color(0xFFD7E4FF),
                primaryVariant: const Color(0xFFA7B3D6),
              )
            : (
                accent: const Color(0xFF3B7DDD),
                primary: const Color(0xFF1A4A8A),
                primaryVariant: const Color(0xFF2D5FAA),
              );
      case NatsuyumePalette.hestia:
        return isDark
            ? (
                accent: const Color(0xFF7DE7FF),
                primary: const Color(0xFFEDE6D4),
                primaryVariant: const Color(0xFFB8D6E6),
              )
            : (
                accent: const Color(0xFF00A7D8),
                primary: const Color(0xFF2A3448),
                primaryVariant: const Color(0xFF5B718E),
              );
      case NatsuyumePalette.misaki:
        return isDark
            ? (
                accent: const Color(0xFFFF66D6),
                primary: const Color(0xFFFFB3EC),
                primaryVariant: const Color(0xFF9A5BFF),
              )
            : (
                accent: const Color(0xFFD633A5),
                primary: const Color(0xFF5A1F5C),
                primaryVariant: const Color(0xFF8C3FA8),
              );
      case NatsuyumePalette.akane:
        return isDark
            ? (
                accent: const Color(0xFFA6C95A),
                primary: const Color(0xFFE2C18A),
                primaryVariant: const Color(0xFFC9A56B),
              )
            : (
                accent: const Color(0xFF7A9F2A),
                primary: const Color(0xFF8B6330),
                primaryVariant: const Color(0xFFB68745),
              );
      case NatsuyumePalette.syalis:
        return isDark
            ? (
                accent: const Color(0xFFE68AFF),
                primary: const Color(0xFFF6D7FF),
                primaryVariant: const Color(0xFFFFD56A),
              )
            : (
                accent: const Color(0xFF9A4CC7),
                primary: const Color(0xFF6B4A88),
                primaryVariant: const Color(0xFFC99A1A),
              );
      case NatsuyumePalette.liscia:
        return isDark
            ? (
                accent: const Color(0xFFE3B341),
                primary: const Color(0xFFFFE0A3),
                primaryVariant: const Color(0xFFB54848),
              )
            : (
                accent: const Color(0xFFB8860B),
                primary: const Color(0xFF6E4A18),
                primaryVariant: const Color(0xFF8F2D2D),
              );
      case NatsuyumePalette.itsuki:
        return isDark
            ? (
                accent: const Color(0xFFE45A6B),
                primary: const Color(0xFFFFB3BC),
                primaryVariant: const Color(0xFF7A8DFF),
              )
            : (
                accent: const Color(0xFFC93E53),
                primary: const Color(0xFF7A2A35),
                primaryVariant: const Color(0xFF4A5FD4),
              );
      case NatsuyumePalette.misumi:
        return isDark
            ? (
                accent: const Color(0xFF8B5FD6),
                primary: const Color(0xFFD8C8F8),
                primaryVariant: const Color(0xFF58D0D8),
              )
            : (
                accent: const Color(0xFF6C42B5),
                primary: const Color(0xFF3D245E),
                primaryVariant: const Color(0xFF208A96),
              );
      case NatsuyumePalette.berryblossom:
        return isDark
            ? (
                accent: const Color(0xFFFF78C6),
                primary: const Color(0xFFFFC8E8),
                primaryVariant: const Color(0xFFB8E83D),
              )
            : (
                accent: const Color(0xFFE8489A),
                primary: const Color(0xFF8A2458),
                primaryVariant: const Color(0xFF7AA800),
              );
      case NatsuyumePalette.jeanne:
        return isDark
            ? (
                accent: const Color(0xFFFF5A36),
                primary: const Color(0xFFFFD9D2),
                primaryVariant: const Color(0xFFD62828),
              )
            : (
                accent: const Color(0xFFD93A1A),
                primary: const Color(0xFF5A1F1F),
                primaryVariant: const Color(0xFFB22222),
              );
      case NatsuyumePalette.yoshino:
        return isDark
            ? (
                accent: const Color(0xFFFFC44D),
                primary: const Color(0xFFFFE6A3),
                primaryVariant: const Color(0xFFFF9E2C),
              )
            : (
                accent: const Color(0xFFE89A1C),
                primary: const Color(0xFF6B4A00),
                primaryVariant: const Color(0xFFB87400),
              );
      case NatsuyumePalette.erna:
        return isDark
            ? (
                accent: const Color(0xFFB7C79C),
                primary: const Color(0xFFF0E6C8),
                primaryVariant: const Color(0xFF8FA08A),
              )
            : (
                accent: const Color(0xFF8E9C63),
                primary: const Color(0xFF4D4630),
                primaryVariant: const Color(0xFFBFA86A),
              );
      case NatsuyumePalette.beta:
        return isDark
            ? (
                accent: const Color(0xFF3B8CFF),
                primary: const Color(0xFFBFD8FF),
                primaryVariant: const Color(0xFF8FD96B),
              )
            : (
                accent: const Color(0xFF1558D6),
                primary: const Color(0xFF0F1A3D),
                primaryVariant: const Color(0xFF4F9F3F),
              );
    }
  }

  // -------------------------------------------------------------------------
  // resolve() — the single entry point for all theme combinations
  // -------------------------------------------------------------------------
  static NatsuyumeColorScheme resolve({
    required NatsuyumeMode mode,
    NatsuyumePalette palette = NatsuyumePalette.default_,
    Color? seedColor,
    ThemeStyle themeStyle = ThemeStyle.vibrant,
  }) {
    if (mode == NatsuyumeMode.dynamic) {
      return seedColor != null ? _fromSeed(seedColor, themeStyle) : dark;
    }

    // Manual: caller applies directly via onThemeChange — resolve returns dark
    if (mode == NatsuyumeMode.manual) return dark;

    // Base scheme from mode
    final NatsuyumeColorScheme base;
    switch (mode) {
      case NatsuyumeMode.light:
        base = light;
        break;
      case NatsuyumeMode.dark:
        base = dark;
        break;
      case NatsuyumeMode.amoled:
        base = amoled;
        break;
      default:
        base = dark;
    }

    // No palette override
    if (palette == NatsuyumePalette.default_) return base;

    // Apply palette accent override
    final isDark = mode != NatsuyumeMode.light;
    final accents = _paletteAccents(palette, isDark);
    return NatsuyumeColorScheme(
      background: base.background,
      surface: base.surface,
      surfaceVariant: base.surfaceVariant,
      onBackground: base.onBackground,
      onSurface: base.onSurface,
      onSurfaceVariant: base.onSurfaceVariant,
      divider: base.divider,
      accent: accents.accent,
      primary: accents.primary,
      primaryVariant: accents.primaryVariant,
    );
  }

  // -------------------------------------------------------------------------
  // Dynamic scheme generation from seed color
  // -------------------------------------------------------------------------
  static NatsuyumeColorScheme _fromSeed(Color seed, ThemeStyle style) {
    // Derive background surfaces — same for all styles
    final bg = Color.lerp(const Color(0xFF0C0E16), seed, 0.08)!;
    final surface = Color.lerp(const Color(0xFF141720), seed, 0.10)!;
    final surfaceVariant = Color.lerp(const Color(0xFF1E2230), seed, 0.12)!;
    final divider = Color.lerp(const Color(0xFF22263A), seed, 0.08)!;

    final Color accent;
    final Color primary;
    final Color primaryVariant;

    switch (style) {
      case ThemeStyle.vibrant:
        accent = _boostSaturation(seed, 0.85);
        primary = Color.lerp(Colors.white, accent, 0.20)!;
        primaryVariant = Color.lerp(const Color(0xFFF6E8DC), accent, 0.15)!;
        break;

      case ThemeStyle.tonalSpot:
        // Softer, more muted than vibrant
        accent = _boostSaturation(seed, 0.55);
        primary = Color.lerp(Colors.white, accent, 0.25)!;
        primaryVariant = Color.lerp(Colors.white, accent, 0.45)!;
        break;

      case ThemeStyle.expressive:
        // Complementary hue shift — rotate hue 30° for a more expressive feel
        final hsl = HSLColor.fromColor(seed);
        accent = hsl
            .withHue((hsl.hue + 30) % 360)
            .withSaturation(0.80)
            .withLightness(0.65)
            .toColor();
        primary = Color.lerp(Colors.white, accent, 0.22)!;
        primaryVariant = _boostSaturation(seed, 0.60);
        break;

      case ThemeStyle.spritz:
        // Very desaturated, almost neutral
        accent = _boostSaturation(seed, 0.25);
        primary = Color.lerp(Colors.white, accent, 0.30)!;
        primaryVariant = Color.lerp(Colors.white, accent, 0.50)!;
        break;

      case ThemeStyle.rainbow:
        // Triadic — hue shifted 120°
        final hsl = HSLColor.fromColor(seed);
        accent = hsl
            .withHue((hsl.hue + 120) % 360)
            .withSaturation(0.80)
            .withLightness(0.65)
            .toColor();
        primary = Color.lerp(Colors.white, accent, 0.20)!;
        primaryVariant = hsl
            .withHue((hsl.hue + 240) % 360)
            .withSaturation(0.70)
            .withLightness(0.70)
            .toColor();
        break;

      case ThemeStyle.fruitSalad:
        // Analogous hue shift — rotate -30°
        final hsl = HSLColor.fromColor(seed);
        accent = hsl
            .withHue((hsl.hue - 30 + 360) % 360)
            .withSaturation(0.78)
            .withLightness(0.62)
            .toColor();
        primary = Color.lerp(Colors.white, accent, 0.22)!;
        primaryVariant = _boostSaturation(seed, 0.65);
        break;

      case ThemeStyle.neutral:
        // Almost fully desaturated — near grayscale with hint of seed
        accent = _boostSaturation(seed, 0.12);
        primary = Color.lerp(Colors.white, accent, 0.35)!;
        primaryVariant = Color.lerp(Colors.white, accent, 0.55)!;
        break;

      case ThemeStyle.monochrome:
        // Pure grayscale — no hue from seed at all
        final luminance = seed.computeLuminance();
        final gray = Color.lerp(
          const Color(0xFF888888),
          Colors.white,
          luminance,
        )!;
        accent = gray;
        primary = const Color(0xFFDDDDDD);
        primaryVariant = const Color(0xFFAAAAAA);
        break;

      case ThemeStyle.fidelity:
        // Maximum fidelity — use seed color as-is, minimal transformation
        accent = seed;
        primary = Color.lerp(Colors.white, seed, 0.15)!;
        primaryVariant = Color.lerp(Colors.white, seed, 0.35)!;
        break;
    }

    return NatsuyumeColorScheme(
      background: bg,
      surface: surface,
      surfaceVariant: surfaceVariant,
      primary: primary,
      primaryVariant: primaryVariant,
      onBackground: const Color(0xFFEBEFFB),
      onSurface: const Color(0xFFCDD8F0),
      onSurfaceVariant: const Color(0xFF8896B8),
      accent: accent,
      divider: divider,
    );
  }

  static Color _boostSaturation(Color color, double targetSaturation) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withSaturation(targetSaturation.clamp(0.0, 1.0))
        .withLightness(hsl.lightness.clamp(0.45, 0.70))
        .toColor();
  }

  // -------------------------------------------------------------------------
  // Legacy helpers — kept for manual_theme_screen.dart compatibility
  // -------------------------------------------------------------------------
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

  // fromId kept for any remaining callsites — maps to resolve()
  static NatsuyumeColorScheme fromId(String id) {
    switch (id) {
      case 'light':
        return resolve(mode: NatsuyumeMode.light);
      case 'dark':
        return resolve(mode: NatsuyumeMode.dark);
      case 'amoled':
        return resolve(mode: NatsuyumeMode.amoled);
      default:
        return resolve(mode: NatsuyumeMode.dark);
    }
  }
}

// ---------------------------------------------------------------------------
// InheritedWidget + Provider — unchanged API, NowPlayingScreen etc. unaffected
// ---------------------------------------------------------------------------
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
  NatsuyumeColorScheme _colors = NatsuyumeColorScheme.resolve(
    mode: NatsuyumeMode.dark,
  );

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
