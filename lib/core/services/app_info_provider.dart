import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppInfoProvider extends ChangeNotifier {
  PackageInfo? _packageInfo;
  bool _isLoading = true;

  bool get isLoading => _isLoading;
  String get version => _packageInfo?.version ?? '';
  String get buildNumber => _packageInfo?.buildNumber ?? '';
  String get formattedVersion => _packageInfo != null ? '${_packageInfo!.version} (${_packageInfo!.buildNumber})' : '';

  AppInfoProvider() {
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    _packageInfo = await PackageInfo.fromPlatform();
    _isLoading = false;
    notifyListeners();
  }
}
