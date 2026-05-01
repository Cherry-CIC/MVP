import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cherry_mvp/core/models/model.dart';
import 'package:cherry_mvp/core/services/error_string.dart';
import 'package:cherry_mvp/core/services/google_auth_service.dart';
import 'package:cherry_mvp/core/utils/result.dart';

class FirebaseAuthService {
  final FirebaseAuth firebaseAuth;

  FirebaseAuthService({required this.firebaseAuth});

  late final GoogleAuthService _googleAuthService = GoogleAuthService();

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
      final userCredential = await _googleAuthService.signInWithGoogleFirebase(firebaseAuth);

      // Handle userCredential null check
      if (userCredential.user == null) {
        return Result.failure('No user returned from Google sign-in');
      }
      // Once signed in, return the UserCredential
      return Result.success(
        UserCredentials(
          uid: userCredential.user?.uid,
          email: userCredential.user?.email,
          firstname: userCredential.user?.displayName,
          photoUrl: userCredential.user?.photoURL,
          phoneNumber: userCredential.user?.phoneNumber,
        ),
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: ${e.code} ${e.message}');
      return Result.failure(e.message ?? 'Firebase Auth error');
    } catch (e) {
      debugPrint('Unknown exception: $e');
      return Result.failure('Google sign-in failed: $e');
    }
  }

  Future<Result<UserCredentials>> signInWithApple() async {
    try {
      final appleProvider = AppleAuthProvider();
      final UserCredential user;
      if (kIsWeb) {
        user = await firebaseAuth.signInWithPopup(appleProvider);
      } else {
        user = await firebaseAuth.signInWithProvider(appleProvider);
      }
      if (user.user == null) {
        return Result.failure('No user returned from Apple sign-in');
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
      debugPrint('FirebaseAuthException: ${e.code} ${e.message}');
      return Result.failure(e.message ?? 'Firebase Auth error');
    } catch (e) {
      debugPrint('Unknown exception: $e');
      return Result.failure('Apple sign-in failed: $e');
    }
  }

  Future<Result<void>> logout() async {
    try {
      await firebaseAuth.signOut();
      // will sign out if signed in through google_sign_in, and do nothing otherwise.
      await _googleAuthService.signOut();

      return Result.success(null);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
}
