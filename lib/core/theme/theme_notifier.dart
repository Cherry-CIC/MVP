import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ChangeNotifier {
  ThemeNotifier(this._prefs) {
    final storedModeIndex = _prefs.getInt(_prefsKey);
    if (storedModeIndex != null &&
        storedModeIndex >= 0 &&
        storedModeIndex < ThemeMode.values.length) {
      _mode = ThemeMode.values[storedModeIndex];
    }
  }

  static const String _prefsKey = 'theme_mode';
  final SharedPreferences _prefs;

  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  bool get isDark => _mode == ThemeMode.dark;

  void setThemeMode(ThemeMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    _prefs.setInt(_prefsKey, mode.index);
    notifyListeners();
  }

  void toggleDark(bool enabled) {
    setThemeMode(enabled ? ThemeMode.dark : ThemeMode.light);
  }
}
