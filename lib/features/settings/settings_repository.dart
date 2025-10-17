import 'package:cherry_mvp/core/services/services.dart';

class SettingsRepository {
  final FirestoreService _firestoreService;

  SettingsRepository(this._firestoreService);

  Future<void> setThemeMode(String mode) async {
    await _firestoreService.setThemeMode(mode);
  }

  String get themeMode => _firestoreService.themeMode;
}
