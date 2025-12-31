import 'package:firebase_auth/firebase_auth.dart';
import 'package:cherry_mvp/core/models/model.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'error_string.dart';

class FirebaseAuthService {
  final FirebaseAuth firebaseAuth;

  FirebaseAuthService({required this.firebaseAuth});

  Future<Result<UserCredentials>> signUp(String email, String password) async {
    try {
      UserCredential user = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      return Result.success(
        UserCredentials(uid: user.user?.uid, email: user.user?.email),
      );
    } on FirebaseAuthException catch (e) {
      return Result.failure(e.message ?? ErrorStrings.registerError);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  Future<Result<UserCredentials>> login(String email, String password) async {
    try {
      UserCredential user = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return Result.success(
        UserCredentials(uid: user.user?.uid, email: user.user?.email),
      );
    } on FirebaseAuthException catch (e) {
      return Result.failure(e.message ?? ErrorStrings.loginError);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> sendVerificationEmail() async {
    try {
      final user = firebaseAuth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        return Result.success(null);
      } else {
        return Result.failure('No user found or email already verified');
      }
    } on FirebaseAuthException catch (e) {
      return Result.failure(e.message ?? ErrorStrings.friendlyError);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  Future<Result<UserCredentials>> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      final user = await FirebaseAuth.instance.signInWithCredential(credential);

      // Once signed in, return the UserCredential
      return Result.success(
        UserCredentials(
          uid: user.user?.uid,
          email: user.user?.email,
          firstname: user.user?.displayName,
          photoUrl: user.user?.photoURL,
          phoneNumber: user.user?.phoneNumber,
        ),
      );
    } on FirebaseAuthException catch (e) {
      return Result.failure(e.message ?? ErrorStrings.friendlyError);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  Future<Result<UserCredentials>> signInWithApple() async {
    try {
      final appleProvider = AppleAuthProvider();
      final UserCredential user;
      if (kIsWeb) {
        user = await FirebaseAuth.instance.signInWithPopup(appleProvider);
      } else {
        user = await FirebaseAuth.instance.signInWithProvider(appleProvider);
      }
      // Once signed in, return the UserCredential
      return Result.success(
        UserCredentials(
          uid: user.user?.uid,
          email: user.user?.email,
          firstname: user.user?.displayName,
          photoUrl: user.user?.photoURL,
          phoneNumber: user.user?.phoneNumber,
        ),
      );
    } on FirebaseAuthException catch (e) {
      return Result.failure(e.message ?? ErrorStrings.friendlyError);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> logout() async {
    try {
      await firebaseAuth.signOut();
      if (await GoogleSignIn().isSignedIn()) {
        await GoogleSignIn().signOut();
      }

      return Result.success(null);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
}
