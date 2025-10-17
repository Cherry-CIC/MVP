import 'package:cherry_mvp/features/settings/settings_repository.dart';
import 'package:flutter/material.dart';

class SettingsViewModel extends ChangeNotifier {
  final SettingsRepository settingsRepository;

  SettingsViewModel({required this.settingsRepository});

  String get themeMode => settingsRepository.themeMode;

  Future<void> setThemeMode(String mode) async {
    await settingsRepository.setThemeMode(mode);
    notifyListeners();
  }
}
