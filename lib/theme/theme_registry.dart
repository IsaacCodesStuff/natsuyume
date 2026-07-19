import 'package:flutter/material.dart';

/// Represents a named theme entry — either a built-in or an unlocked secret theme.
class NatsuyumeThemeEntry {
  final String id;
  final String label;
  final bool isSecret;

  const NatsuyumeThemeEntry({
    required this.id,
    required this.label,
    this.isSecret = false,
  });
}

/// Central registry for all available themes.
/// Built-in themes are always present.
/// Secret themes appear only when unlocked and enabled.
class ThemeRegistry extends ChangeNotifier {
  ThemeRegistry._();
  static final ThemeRegistry instance = ThemeRegistry._();

  // Built-in themes — always available
  static const List<NatsuyumeThemeEntry> builtInThemes = [
    NatsuyumeThemeEntry(id: 'light', label: 'Light'),
    NatsuyumeThemeEntry(id: 'dark', label: 'Dark'),
    NatsuyumeThemeEntry(id: 'dynamic', label: 'Dynamic'),
    NatsuyumeThemeEntry(id: 'manual', label: 'Manual'),
  ];

  // All secret themes — only visible when unlocked AND enabled
  static const List<NatsuyumeThemeEntry> _allSecretThemes = [
    NatsuyumeThemeEntry(id: 'natsuyume', label: 'Natsuyume', isSecret: true),
    NatsuyumeThemeEntry(id: 'rem', label: 'Rem', isSecret: true),
    NatsuyumeThemeEntry(id: 'misaki', label: 'Misaki', isSecret: true),
    NatsuyumeThemeEntry(id: 'hestia', label: 'Hestia', isSecret: true),
    NatsuyumeThemeEntry(id: 'akane', label: 'Akane', isSecret: true),
    NatsuyumeThemeEntry(id: 'syalis', label: 'Syalis', isSecret: true),
    NatsuyumeThemeEntry(id: 'liscia', label: 'Liscia', isSecret: true),
    NatsuyumeThemeEntry(id: 'itsuki', label: 'Itsuki', isSecret: true),
    NatsuyumeThemeEntry(id: 'misumi', label: 'Misumi', isSecret: true),
    NatsuyumeThemeEntry(
      id: 'berryblossom',
      label: 'Berry Blossom',
      isSecret: true,
    ),
    NatsuyumeThemeEntry(id: 'jeanne', label: 'Jeanne', isSecret: true),
    NatsuyumeThemeEntry(id: 'yoshino', label: 'Yoshino', isSecret: true),
    NatsuyumeThemeEntry(id: 'erna', label: 'Erna', isSecret: true),
    NatsuyumeThemeEntry(id: 'beta', label: 'Beta', isSecret: true),
  ];

  // Tracks which secret themes have been unlocked
  final Set<String> _unlockedIds = {};

  // Tracks which unlocked themes are enabled
  final Set<String> _enabledIds = {};

  // Currently selected theme id
  String _selectedThemeId = 'dark';
  String get selectedThemeId => _selectedThemeId;

  /// All secret themes that have been unlocked
  List<NatsuyumeThemeEntry> get unlockedThemes =>
      _allSecretThemes.where((t) => _unlockedIds.contains(t.id)).toList();

  /// Unlocked themes that are also enabled — these appear in the theme picker
  List<NatsuyumeThemeEntry> get enabledSecretThemes => _allSecretThemes
      .where((t) => _unlockedIds.contains(t.id) && _enabledIds.contains(t.id))
      .toList();

  /// Full list shown in the theme picker dialog
  List<NatsuyumeThemeEntry> get availableThemes => [
    ...builtInThemes,
    ...enabledSecretThemes,
  ];

  bool isUnlocked(String id) => _unlockedIds.contains(id);
  bool isEnabled(String id) => _enabledIds.contains(id);

  /// Unlock a secret theme by id — called when a valid code is entered
  void unlock(String id) {
    if (_unlockedIds.contains(id)) return;
    _unlockedIds.add(id);
    notifyListeners();
  }

  /// Toggle whether an unlocked theme is enabled in the picker
  void setEnabled(String id, bool enabled) {
    if (!_unlockedIds.contains(id)) return;
    if (enabled) {
      _enabledIds.add(id);
    } else {
      _enabledIds.remove(id);
      // If the disabled theme was selected, fall back to dark
      if (_selectedThemeId == id) {
        _selectedThemeId = 'dark';
      }
    }
    notifyListeners();
  }

  /// Select a theme
  void selectTheme(String id) {
    _selectedThemeId = id;
    notifyListeners();
  }

  /// Unlock by secret code — returns the theme name if valid, null if not
  String? unlockByCode(String code) {
    const codeMap = {
      'NATSUYUME': 'natsuyume',
      'REMREM': 'rem',
      'MISAKI': 'misaki',
      'HESTIA': 'hestia',
      'AKANE': 'akane',
      'SYALIS': 'syalis',
      'LISCIA': 'liscia',
      'ITSUKI': 'itsuki',
      'MISUMI': 'misumi',
      'BERRYBLOSSOM': 'berryblossom',
      'JEANNE': 'jeanne',
      'YOSHINO': 'yoshino',
      'ERNA': 'erna',
      'BETA': 'beta',
    };

    final id = codeMap[code.toUpperCase()];
    if (id == null) return null;

    unlock(id);
    // Auto-enable when first unlocked
    _enabledIds.add(id);
    notifyListeners();

    return _allSecretThemes.firstWhere((t) => t.id == id).label;
  }

  /// Reset everything — called on factory reset
  void reset() {
    _unlockedIds.clear();
    _enabledIds.clear();
    _selectedThemeId = 'dark';
    notifyListeners();
  }
}
