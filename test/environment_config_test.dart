import 'package:cherry_mvp/core/config/environment_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppEnvironment.resolveApiBaseUrl', () {
    test('throws when API_BASE_URL is missing', () {
      expect(() => AppEnvironment.resolveApiBaseUrl({}), throwsFormatException);
    });

    test('normalises a trailing /api segment', () {
      expect(
        AppEnvironment.resolveApiBaseUrl({
          'API_BASE_URL': 'https://example.com/api/',
        }),
        'https://example.com',
      );
    });

    test('keeps a valid root URL unchanged', () {
      expect(
        AppEnvironment.resolveApiBaseUrl({
          'API_BASE_URL': 'https://example.com',
        }),
        'https://example.com',
      );
    });
  });

  group('AppEnvironment.resolveFirebaseEmulatorConfig', () {
    test('returns null when emulators are not enabled', () {
      expect(AppEnvironment.resolveFirebaseEmulatorConfig({}), isNull);
    });

    test('uses safe defaults when emulators are enabled', () {
      final config = AppEnvironment.resolveFirebaseEmulatorConfig({
        'USE_FIREBASE_EMULATORS': 'true',
      });

      expect(config, isNotNull);
      expect(config!.host, 'localhost');
      expect(config.authPort, 9099);
      expect(config.firestorePort, 8080);
    });

    test('throws when an emulator port is invalid', () {
      expect(
        () => AppEnvironment.resolveFirebaseEmulatorConfig({
          'USE_FIREBASE_EMULATORS': 'true',
          'FIREBASE_AUTH_EMULATOR_PORT': 'abc',
        }),
        throwsFormatException,
      );
    });
  });
}
