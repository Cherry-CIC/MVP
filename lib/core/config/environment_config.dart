import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnvironment {
  static const String apiBaseUrlKey = 'API_BASE_URL';
  static const String useFirebaseEmulatorsKey = 'USE_FIREBASE_EMULATORS';
  static const String firebaseEmulatorHostKey = 'FIREBASE_EMULATOR_HOST';
  static const String firebaseAuthEmulatorPortKey =
      'FIREBASE_AUTH_EMULATOR_PORT';
  static const String firestoreEmulatorPortKey = 'FIRESTORE_EMULATOR_PORT';

  static String get apiBaseUrl => resolveApiBaseUrl(dotenv.env);

  static FirebaseEmulatorConfig? get firebaseEmulatorConfig =>
      resolveFirebaseEmulatorConfig(dotenv.env);

  static String resolveApiBaseUrl(Map<String, String> env) {
    final rawBaseUrl = env[apiBaseUrlKey]?.trim() ?? '';
    if (rawBaseUrl.isEmpty) {
      throw FormatException(
        'Missing API_BASE_URL in .env. Add the backend base URL before '
        'running the app.',
      );
    }

    final normalisedBaseUrl = _normaliseApiBaseUrl(rawBaseUrl);
    final uri = Uri.tryParse(normalisedBaseUrl);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw FormatException(
        'API_BASE_URL must be a complete URL, for example '
        'https://example.com',
      );
    }

    return normalisedBaseUrl;
  }

  static FirebaseEmulatorConfig? resolveFirebaseEmulatorConfig(
    Map<String, String> env,
  ) {
    final useFirebaseEmulators =
        (env[useFirebaseEmulatorsKey] ?? '').trim().toLowerCase() == 'true';
    if (!useFirebaseEmulators) {
      return null;
    }

    final host = (env[firebaseEmulatorHostKey] ?? 'localhost').trim();
    if (host.isEmpty) {
      throw FormatException(
        'FIREBASE_EMULATOR_HOST cannot be empty when '
        'USE_FIREBASE_EMULATORS=true.',
      );
    }

    return FirebaseEmulatorConfig(
      host: host,
      authPort: _resolvePort(env, firebaseAuthEmulatorPortKey, fallback: 9099),
      firestorePort: _resolvePort(
        env,
        firestoreEmulatorPortKey,
        fallback: 8080,
      ),
    );
  }

  static String _normaliseApiBaseUrl(String rawBaseUrl) {
    var normalisedBaseUrl = rawBaseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    normalisedBaseUrl = normalisedBaseUrl.replaceFirst(RegExp(r'/api$'), '');
    return normalisedBaseUrl;
  }

  static int _resolvePort(
    Map<String, String> env,
    String key, {
    required int fallback,
  }) {
    final rawPort = env[key]?.trim();
    if (rawPort == null || rawPort.isEmpty) {
      return fallback;
    }

    final port = int.tryParse(rawPort);
    if (port == null || port < 1 || port > 65535) {
      throw FormatException('$key must be a valid port number.');
    }

    return port;
  }
}

class FirebaseEmulatorConfig {
  const FirebaseEmulatorConfig({
    required this.host,
    required this.authPort,
    required this.firestorePort,
  });

  final String host;
  final int authPort;
  final int firestorePort;
}
