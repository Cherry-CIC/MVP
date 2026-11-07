import 'package:cherry_mvp/core/services/safe_log.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  final _googleSignIn = GoogleSignIn.instance;
  bool _isGoogleSignInInitialized = false;

  GoogleSignInAccount? _currentUser;
  GoogleSignInAccount? get currentUser => _currentUser;

  static String? resolveClientId({
    required bool isWeb,
    required TargetPlatform platform,
    required Map<String, String> env,
  }) {
    if (isWeb ||
        platform == TargetPlatform.iOS ||
        platform == TargetPlatform.macOS) {
      final clientId = env['GOOGLE_SIGN_IN_CLIENT_ID']?.trim();
      return (clientId != null && clientId.isNotEmpty) ? clientId : null;
    }
    return null;
  }

  static String? resolveServerClientId(Map<String, String> env) {
    final serverClientId = env['GOOGLE_SIGN_IN_SERVER_CLIENT_ID']?.trim();
    return (serverClientId != null && serverClientId.isNotEmpty)
        ? serverClientId
        : null;
  }

  Future<void> _initializeGoogleSignIn() async {
    try {
      await _googleSignIn.initialize(
        clientId: resolveClientId(
          isWeb: kIsWeb,
          platform: defaultTargetPlatform,
          env: dotenv.env,
        ),
        serverClientId: resolveServerClientId(dotenv.env),
      );
      _isGoogleSignInInitialized = true;
    } catch (_) {
      SafeLog.event(
        AppLogEvent.authProviderInitialisationFailed,
        level: SafeLogLevel.severe,
      );
      rethrow;
    }
  }

  /// Always check Google sign in initialization before use
  Future<void> _ensureGoogleSignInInitialized() async {
    if (!_isGoogleSignInInitialized) {
      await _initializeGoogleSignIn();
    }
  }

  Future<UserCredential> signInWithGoogleFirebase(
    FirebaseAuth firebaseAuth,
  ) async {
    if (kIsWeb) {
      return firebaseAuth.signInWithPopup(GoogleAuthProvider());
    }

    await _ensureGoogleSignInInitialized();

    final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final userCredential = await firebaseAuth.signInWithCredential(credential);
    _currentUser = googleUser;

    return userCredential;
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      try {
        await _ensureGoogleSignInInitialized();
        await _googleSignIn.signOut();
      } catch (_) {
        // Ignore Google sign-out errors when Google Sign-In was not active.
      }
    }
    _currentUser = null;
  }
}
