import 'package:flutter/material.dart';

class AppThemeMode extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  set themeMode(ThemeMode thememode) {
    _themeMode = thememode;
    notifyListeners();
  }

  void darkMode() {
    _themeMode = ThemeMode.dark;
    notifyListeners();
  }

  void lightMode() {
    _themeMode = ThemeMode.light;
    notifyListeners();
  }

  void systemMode() {
    _themeMode = ThemeMode.system;
    notifyListeners();
  }

  bool get isDark => _themeMode == ThemeMode.dark;
  bool get isLight => _themeMode == ThemeMode.light;
}

final appThemeModeNotifier = AppThemeMode();
