import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'natsuyume_theme.dart';

class ThemeRegistry extends ChangeNotifier {
  ThemeRegistry._();
  static final ThemeRegistry instance = ThemeRegistry._();

  NatsuyumeMode _mode = NatsuyumeMode.dark;
  NatsuyumePalette _palette = NatsuyumePalette.default_;
  ThemeStyle _themeStyle = ThemeStyle.vibrant;
  Color? _dynamicSeedColor;
  NatsuyumeColorScheme? _manualScheme;

  NatsuyumeMode get selectedMode => _mode;
  NatsuyumePalette get selectedPalette => _palette;
  ThemeStyle get selectedThemeStyle => _themeStyle;
  Color? get dynamicSeedColor => _dynamicSeedColor;
  NatsuyumeColorScheme? get manualScheme => _manualScheme;

  final Set<NatsuyumePalette> _unlockedPalettes = {};
  final Set<NatsuyumePalette> _enabledPalettes = {};

  // -------------------------------------------------------------------------
  // Current resolved scheme
  // -------------------------------------------------------------------------
  NatsuyumeColorScheme get currentScheme {
    if (_mode == NatsuyumeMode.manual && _manualScheme != null) {
      return _manualScheme!;
    }
    return NatsuyumeColorScheme.resolve(
      mode: _mode,
      palette: _palette,
      seedColor: _dynamicSeedColor,
      themeStyle: _themeStyle,
    );
  }

  // -------------------------------------------------------------------------
  // Mode selection
  // -------------------------------------------------------------------------
  void selectMode(NatsuyumeMode mode) {
    _mode = mode;
    if (mode == NatsuyumeMode.dynamic || mode == NatsuyumeMode.manual) {
      _palette = NatsuyumePalette.default_;
    }
    _save();
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Palette selection
  // -------------------------------------------------------------------------
  void selectPalette(NatsuyumePalette palette) {
    if (palette != NatsuyumePalette.default_ &&
        !_unlockedPalettes.contains(palette))
      return;
    _palette = palette;
    _save();
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Theme style
  // -------------------------------------------------------------------------
  void selectThemeStyle(ThemeStyle style) {
    _themeStyle = style;
    _save();
    if (_mode == NatsuyumeMode.dynamic) notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Dynamic seed color
  // -------------------------------------------------------------------------
  void setDynamicSeedColor(Color color) {
    _dynamicSeedColor = color;
    if (_mode == NatsuyumeMode.dynamic) notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Manual scheme
  // -------------------------------------------------------------------------
  void setManualScheme(NatsuyumeColorScheme scheme) {
    _manualScheme = scheme;
    _save();
    if (_mode == NatsuyumeMode.manual) notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Palette unlock system
  // -------------------------------------------------------------------------
  bool isUnlocked(NatsuyumePalette palette) =>
      _unlockedPalettes.contains(palette);

  bool isEnabled(NatsuyumePalette palette) =>
      _enabledPalettes.contains(palette);

  List<NatsuyumePalette> get unlockedPalettes => NatsuyumePalette.values
      .where((p) => p.isSecret && _unlockedPalettes.contains(p))
      .toList();

  List<NatsuyumePalette> get enabledPalettes => NatsuyumePalette.values
      .where(
        (p) =>
            p.isSecret &&
            _unlockedPalettes.contains(p) &&
            _enabledPalettes.contains(p),
      )
      .toList();

  void unlock(NatsuyumePalette palette) {
    _unlockedPalettes.add(palette);
    _enabledPalettes.add(palette);
    _save();
    notifyListeners();
  }

  void setEnabled(NatsuyumePalette palette, bool enabled) {
    if (!_unlockedPalettes.contains(palette)) return;
    if (enabled) {
      _enabledPalettes.add(palette);
    } else {
      _enabledPalettes.remove(palette);
      if (_palette == palette) _palette = NatsuyumePalette.default_;
    }
    _save();
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Code unlock
  // -------------------------------------------------------------------------
  String? unlockByCode(String code) {
    const codeMap = {
      'NATSUYUME': NatsuyumePalette.natsuyume,
      'REMREM': NatsuyumePalette.rem,
      'MISAKI': NatsuyumePalette.misaki,
      'HESTIA': NatsuyumePalette.hestia,
      'AKANE': NatsuyumePalette.akane,
      'SYALIS': NatsuyumePalette.syalis,
      'LISCIA': NatsuyumePalette.liscia,
      'ITSUKI': NatsuyumePalette.itsuki,
      'MISUMI': NatsuyumePalette.misumi,
      'BERRYBLOSSOM': NatsuyumePalette.berryblossom,
      'JEANNE': NatsuyumePalette.jeanne,
      'YOSHINO': NatsuyumePalette.yoshino,
      'ERNA': NatsuyumePalette.erna,
      'BETA': NatsuyumePalette.beta,
    };
    final palette = codeMap[code.toUpperCase()];
    if (palette == null) return null;
    unlock(palette);
    return palette.label;
  }

  void reset() {
    _mode = NatsuyumeMode.dark;
    _palette = NatsuyumePalette.default_;
    _themeStyle = ThemeStyle.vibrant;
    _dynamicSeedColor = null;
    _manualScheme = null;
    _unlockedPalettes.clear();
    _enabledPalettes.clear();
    _save();
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Legacy compat
  // -------------------------------------------------------------------------
  String get selectedThemeId => _mode.name;

  // -------------------------------------------------------------------------
  // Persistence
  // -------------------------------------------------------------------------
  static const String _keyMode = 'theme_mode';
  static const String _keyPalette = 'theme_palette';
  static const String _keyStyle = 'theme_style';
  static const String _keyUnlocked = 'theme_unlocked';
  static const String _keyEnabled = 'theme_enabled';
  static const String _keyManualBg = 'theme_manual_bg';
  static const String _keyManualSurface = 'theme_manual_surface';
  static const String _keyManualSurfaceVar = 'theme_manual_surface_variant';
  static const String _keyManualPrimary = 'theme_manual_primary';
  static const String _keyManualPrimaryVar = 'theme_manual_primary_variant';
  static const String _keyManualOnBg = 'theme_manual_on_bg';
  static const String _keyManualOnSurface = 'theme_manual_on_surface';
  static const String _keyManualOnSurfaceVar =
      'theme_manual_on_surface_variant';
  static const String _keyManualAccent = 'theme_manual_accent';
  static const String _keyManualDivider = 'theme_manual_divider';

  Future<void> loadFromPrefs(SharedPreferences prefs) async {
    // Mode
    final modeStr = prefs.getString(_keyMode);
    if (modeStr != null) {
      _mode = NatsuyumeMode.values.firstWhere(
        (m) => m.name == modeStr,
        orElse: () => NatsuyumeMode.dark,
      );
    }

    // Palette
    final paletteStr = prefs.getString(_keyPalette);
    if (paletteStr != null) {
      _palette = NatsuyumePalette.values.firstWhere(
        (p) => p.name == paletteStr,
        orElse: () => NatsuyumePalette.default_,
      );
    }

    // Style
    final styleStr = prefs.getString(_keyStyle);
    if (styleStr != null) {
      _themeStyle = ThemeStyle.values.firstWhere(
        (s) => s.name == styleStr,
        orElse: () => ThemeStyle.vibrant,
      );
    }

    // Unlocked palettes
    final unlockedList = prefs.getStringList(_keyUnlocked) ?? [];
    for (final name in unlockedList) {
      final match = _findPalette(name);
      if (match != null) _unlockedPalettes.add(match);
    }

    // Enabled palettes
    final enabledList = prefs.getStringList(_keyEnabled) ?? [];
    for (final name in enabledList) {
      final match = _findPalette(name);
      if (match != null) _enabledPalettes.add(match);
    }

    // Manual scheme
    final bgValue = prefs.getInt(_keyManualBg);
    if (bgValue != null) {
      _manualScheme = NatsuyumeColorScheme.manual(
        background: Color(bgValue),
        surface: Color(prefs.getInt(_keyManualSurface) ?? 0xFF1B1C25),
        surfaceVariant: Color(prefs.getInt(_keyManualSurfaceVar) ?? 0xFF252733),
        primary: Color(prefs.getInt(_keyManualPrimary) ?? 0xFFCCDFFB),
        primaryVariant: Color(prefs.getInt(_keyManualPrimaryVar) ?? 0xFFF6E8DC),
        onBackground: Color(prefs.getInt(_keyManualOnBg) ?? 0xFFEBEFFB),
        onSurface: Color(prefs.getInt(_keyManualOnSurface) ?? 0xFFCDD8F0),
        onSurfaceVariant: Color(
          prefs.getInt(_keyManualOnSurfaceVar) ?? 0xFF8896B8,
        ),
        accent: Color(prefs.getInt(_keyManualAccent) ?? 0xFF90BFF9),
        divider: Color(prefs.getInt(_keyManualDivider) ?? 0xFF2A2C3A),
      );
    }

    // Guard: if selected palette isn't unlocked, reset to default
    if (_palette != NatsuyumePalette.default_ &&
        !_unlockedPalettes.contains(_palette)) {
      _palette = NatsuyumePalette.default_;
    }
  }

  NatsuyumePalette? _findPalette(String name) {
    for (final p in NatsuyumePalette.values) {
      if (p.name == name) return p;
    }
    return null;
  }

  void _save() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_keyMode, _mode.name);
      prefs.setString(_keyPalette, _palette.name);
      prefs.setString(_keyStyle, _themeStyle.name);
      prefs.setStringList(
        _keyUnlocked,
        _unlockedPalettes.map((p) => p.name).toList(),
      );
      prefs.setStringList(
        _keyEnabled,
        _enabledPalettes.map((p) => p.name).toList(),
      );
      if (_manualScheme != null) {
        prefs.setInt(_keyManualBg, _manualScheme!.background.value);
        prefs.setInt(_keyManualSurface, _manualScheme!.surface.value);
        prefs.setInt(_keyManualSurfaceVar, _manualScheme!.surfaceVariant.value);
        prefs.setInt(_keyManualPrimary, _manualScheme!.primary.value);
        prefs.setInt(_keyManualPrimaryVar, _manualScheme!.primaryVariant.value);
        prefs.setInt(_keyManualOnBg, _manualScheme!.onBackground.value);
        prefs.setInt(_keyManualOnSurface, _manualScheme!.onSurface.value);
        prefs.setInt(
          _keyManualOnSurfaceVar,
          _manualScheme!.onSurfaceVariant.value,
        );
        prefs.setInt(_keyManualAccent, _manualScheme!.accent.value);
        prefs.setInt(_keyManualDivider, _manualScheme!.divider.value);
      }
    });
  }
}
