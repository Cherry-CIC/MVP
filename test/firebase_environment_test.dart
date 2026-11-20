import 'package:cherry_mvp/core/config/firebase_environment.dart';
import 'package:cherry_mvp/core/services/google_auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FirebaseEnvironment.resolveEnvironmentName', () {
    test('uses FLUTTER_APP_FLAVOR=prod when APP_ENV is omitted', () {
      expect(
        FirebaseEnvironment.resolveEnvironmentName(
          definedAppEnv: '',
          flutterAppFlavor: 'prod',
        ),
        'prod',
      );
    });

    test('supports Xcode Release-prod flavor name when APP_ENV is omitted', () {
      expect(
        FirebaseEnvironment.resolveEnvironmentName(
          definedAppEnv: '',
          flutterAppFlavor: 'Release-prod',
        ),
        'prod',
      );
    });

    test('uses FLUTTER_APP_FLAVOR=dev when APP_ENV is omitted', () {
      expect(
        FirebaseEnvironment.resolveEnvironmentName(
          definedAppEnv: '',
          flutterAppFlavor: 'dev',
        ),
        'dev',
      );
    });

    test('prefers explicit APP_ENV over FLUTTER_APP_FLAVOR', () {
      expect(
        FirebaseEnvironment.resolveEnvironmentName(
          definedAppEnv: 'prod',
          flutterAppFlavor: 'dev',
        ),
        'prod',
      );
      expect(
        FirebaseEnvironment.resolveEnvironmentName(
          definedAppEnv: 'dev',
          flutterAppFlavor: 'prod',
        ),
        'dev',
      );
    });

    test('defaults to dev when neither APP_ENV nor flavor is provided', () {
      expect(
        FirebaseEnvironment.resolveEnvironmentName(
          definedAppEnv: '',
          flutterAppFlavor: '',
        ),
        'dev',
      );
    });
  });

  group('GoogleAuthService OAuth client resolution', () {
    const sampleEnv = <String, String>{
      'GOOGLE_SIGN_IN_CLIENT_ID':
          '166746898861-iosclient.apps.googleusercontent.com',
      'GOOGLE_SIGN_IN_SERVER_CLIENT_ID':
          '166746898861-webclient.apps.googleusercontent.com',
    };

    test('omits clientId on Android while retaining serverClientId', () {
      expect(
        GoogleAuthService.resolveClientId(
          isWeb: false,
          platform: TargetPlatform.android,
          env: sampleEnv,
        ),
        isNull,
      );
      expect(
        GoogleAuthService.resolveServerClientId(sampleEnv),
        '166746898861-webclient.apps.googleusercontent.com',
      );
    });

    test('passes clientId on iOS, macOS, and web', () {
      expect(
        GoogleAuthService.resolveClientId(
          isWeb: false,
          platform: TargetPlatform.iOS,
          env: sampleEnv,
        ),
        '166746898861-iosclient.apps.googleusercontent.com',
      );
      expect(
        GoogleAuthService.resolveClientId(
          isWeb: false,
          platform: TargetPlatform.macOS,
          env: sampleEnv,
        ),
        '166746898861-iosclient.apps.googleusercontent.com',
      );
      expect(
        GoogleAuthService.resolveClientId(
          isWeb: true,
          platform: TargetPlatform.android,
          env: sampleEnv,
        ),
        '166746898861-iosclient.apps.googleusercontent.com',
      );
    });
  });
}
