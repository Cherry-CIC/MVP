import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  final _googleSignIn = GoogleSignIn.instance;
  bool _isGoogleSignInInitialized = false;

  GoogleSignInAccount? _currentUser;
  GoogleSignInAccount? get currentUser => _currentUser;

  GoogleAuthService() {
    _initializeGoogleSignIn();
  }

  Future<void> _initializeGoogleSignIn() async {
    try {
      await _googleSignIn.initialize(
        serverClientId: '401854471349-803q3o5vmr8m94fuvt50t1ke07h79c87.apps.googleusercontent.com',
      );
      _isGoogleSignInInitialized = true;
    } catch (e) {
      print('Failed to initialize Google Sign-In: $e');
      rethrow;
    }
  }

  /// Always check Google sign in initialization before use
  Future<void> _ensureGoogleSignInInitialized() async {
    if (!_isGoogleSignInInitialized) {
      await _initializeGoogleSignIn();
    }
  }

  Future<UserCredential> signInWithGoogleFirebase(FirebaseAuth firebaseAuth) async {
    await _ensureGoogleSignInInitialized();

    final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

    final authClient = _googleSignIn.authorizationClient;
    final authorization = await authClient.authorizationForScopes(['email']);

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: authorization?.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await firebaseAuth.signInWithCredential(credential);
    _currentUser = googleUser;

    return userCredential;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
  }
}
