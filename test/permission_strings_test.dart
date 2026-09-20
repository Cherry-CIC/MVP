import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('camera permission messaging matches the photo-only flow and settings recovery', () {
    expect(AppStrings.openSettings, 'Open Settings');
    expect(AppStrings.cameraPermissionRationale, contains('camera'));
    expect(AppStrings.cameraPermissionRationale, isNot(contains('microphone')));
    expect(AppStrings.cameraPermissionRationale, isNot(contains('video')));
    expect(AppStrings.cameraPermissionDeniedMessage, contains('camera'));
    expect(AppStrings.cameraPermissionDeniedMessage, isNot(contains('microphone')));
    expect(AppStrings.cameraPermissionDeniedMessage, isNot(contains('video')));
    expect(AppStrings.cameraPermissionPermanentlyDeniedMessage, contains('Settings'));
    expect(AppStrings.permissionTryAgain, 'Try Again');
  });
}
