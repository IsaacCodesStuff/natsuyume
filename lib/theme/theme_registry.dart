import 'package:flutter/material.dart';
import 'natsuyume_theme.dart';

class ThemeRegistry extends ChangeNotifier {
  ThemeRegistry._();
  static final ThemeRegistry instance = ThemeRegistry._();

  NatsuyumeMode _mode = NatsuyumeMode.dark;
  NatsuyumePalette _palette = NatsuyumePalette.default_;
  Color? _dynamicSeedColor;
  ThemeStyle _themeStyle = ThemeStyle.vibrant;
  ThemeStyle get selectedThemeStyle => _themeStyle;

  NatsuyumeMode get selectedMode => _mode;
  NatsuyumePalette get selectedPalette => _palette;
  Color? get dynamicSeedColor => _dynamicSeedColor;

  // Unlocked secret palettes
  final Set<NatsuyumePalette> _unlockedPalettes = {};
  final Set<NatsuyumePalette> _enabledPalettes = {};

  // -------------------------------------------------------------------------
  // Mode selection
  // -------------------------------------------------------------------------
  void selectMode(NatsuyumeMode mode) {
    _mode = mode;
    // Reset palette when switching to dynamic or manual
    if (mode == NatsuyumeMode.dynamic || mode == NatsuyumeMode.manual) {
      _palette = NatsuyumePalette.default_;
    }
    notifyListeners();
  }

  void selectThemeStyle(ThemeStyle style) {
    _themeStyle = style;
    if (_mode == NatsuyumeMode.dynamic) notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Palette selection
  // -------------------------------------------------------------------------
  void selectPalette(NatsuyumePalette palette) {
    if (palette != NatsuyumePalette.default_ &&
        !_unlockedPalettes.contains(palette))
      return;
    _palette = palette;
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Dynamic seed color — set by PlayerShell on track change
  // -------------------------------------------------------------------------
  void setDynamicSeedColor(Color color) {
    _dynamicSeedColor = color;
    if (_mode == NatsuyumeMode.dynamic) notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Current resolved scheme
  // -------------------------------------------------------------------------
  NatsuyumeColorScheme get currentScheme => NatsuyumeColorScheme.resolve(
    mode: _mode,
    palette: _palette,
    seedColor: _dynamicSeedColor,
    themeStyle: _themeStyle,
  );

  // -------------------------------------------------------------------------
  // Secret palette unlock system — mirrors old ThemeRegistry API
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
    _enabledPalettes.add(palette); // auto-enable on first unlock
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
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Code unlock — maps secret codes to palettes
  // -------------------------------------------------------------------------
  String? unlockByCode(String code) {
    const codeMap = {
      'Fuck you Alphanox no dreamy theme for you': NatsuyumePalette.natsuyume,
      'Rem': NatsuyumePalette.rem,
      'Hestia': NatsuyumePalette.hestia,
      'Misaki': NatsuyumePalette.misaki,
      'Akane': NatsuyumePalette.akane,
      'Syalis': NatsuyumePalette.syalis,
      'Liscia': NatsuyumePalette.liscia,
      'Itsuki': NatsuyumePalette.itsuki,
      'Misumi': NatsuyumePalette.misumi,
      'Berry Blossom': NatsuyumePalette.berryblossom,
      'Jeanne': NatsuyumePalette.jeanne,
      'Yoshino': NatsuyumePalette.yoshino,
      'Erna': NatsuyumePalette.erna,
      'Beta': NatsuyumePalette.beta,
    };

    final palette = codeMap[code.toUpperCase()];
    if (palette == null) return null;
    unlock(palette);
    return palette.label;
  }

  void reset() {
    _mode = NatsuyumeMode.dark;
    _palette = NatsuyumePalette.default_;
    _dynamicSeedColor = null;
    _unlockedPalettes.clear();
    _enabledPalettes.clear();
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Legacy compat — old code used selectedThemeId string
  // -------------------------------------------------------------------------
  String get selectedThemeId => _mode.name;
}
