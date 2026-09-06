import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cherry_mvp/core/models/model.dart';
import 'package:cherry_mvp/core/services/error_string.dart';
import 'package:cherry_mvp/core/services/google_auth_service.dart';
import 'package:cherry_mvp/core/services/safe_log.dart';
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

      return Result.success(UserCredentials.fromAuth(user.user!));
    } on FirebaseAuthException {
      return Result.failure(ErrorStrings.registerError);
    } catch (_) {
      return Result.failure(ErrorStrings.registerError);
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
    } on FirebaseAuthException {
      return Result.failure(ErrorStrings.loginError);
    } catch (_) {
      return Result.failure(ErrorStrings.loginError);
    }
  }

  Future<Result<void>> sendPasswordResetEmail(String email) async {
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email);
      return Result.success(null);
    } on FirebaseAuthException catch (e) {
      SafeLog.event(
        AppLogEvent.authenticationOperationFailed,
        level: SafeLogLevel.warning,
      );
      if (e.code == 'invalid-email') {
        return Result.failure('Please enter a valid email address.');
      }
      return Result.success(null);
    } catch (_) {
      SafeLog.event(
        AppLogEvent.authenticationOperationFailed,
        level: SafeLogLevel.severe,
      );
      return Result.failure('Unable to send reset email right now. Please try again.');
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
    } on FirebaseAuthException {
      return Result.failure(ErrorStrings.friendlyError);
    } catch (_) {
      return Result.failure(ErrorStrings.friendlyError);
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
      return Result.success(UserCredentials.fromAuth(userCredential.user!));
    } on FirebaseAuthException {
      SafeLog.event(
        AppLogEvent.authenticationOperationFailed,
        level: SafeLogLevel.warning,
      );
      return Result.failure('Google sign-in failed');
    } catch (_) {
      SafeLog.event(
        AppLogEvent.authenticationOperationFailed,
        level: SafeLogLevel.warning,
      );
      return Result.failure('Google sign-in failed');
    }
  }

  Future<Result<UserCredentials>> signInWithApple() async {
    try {
      final appleProvider = AppleAuthProvider();
      appleProvider.addScope('email');
      appleProvider.addScope('name');
      final UserCredential userCredential;
      if (kIsWeb) {
        userCredential = await firebaseAuth.signInWithPopup(appleProvider);
      } else {
        userCredential = await firebaseAuth.signInWithProvider(appleProvider);
      }
      if (userCredential.user == null) {
        return Result.failure('No user returned from Apple sign-in');
      }
      // Once signed in, return the UserCredential
      return Result.success(UserCredentials.fromAuth(userCredential.user!));
    } on FirebaseAuthException {
      SafeLog.event(
        AppLogEvent.authenticationOperationFailed,
        level: SafeLogLevel.warning,
      );
      return Result.failure('Apple sign-in failed');
    } catch (_) {
      SafeLog.event(
        AppLogEvent.authenticationOperationFailed,
        level: SafeLogLevel.warning,
      );
      return Result.failure('Apple sign-in failed');
    }
  }

  Future<Result<void>> logout() async {
    try {
      await firebaseAuth.signOut();
      // will sign out if signed in through google_sign_in, and do nothing otherwise.
      await _googleAuthService.signOut();

      return Result.success(null);
    } catch (_) {
      return Result.failure(ErrorStrings.friendlyError);
    }
  }
}
