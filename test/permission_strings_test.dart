import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('camera permission messaging covers video and microphone access recovery', () {
    expect(AppStrings.openSettings, 'Open Settings');
    expect(AppStrings.cameraPermissionDeniedMessage, contains('microphone'));
    expect(AppStrings.cameraPermissionDeniedMessage, contains('video'));
  });
}
