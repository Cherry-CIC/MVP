import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:cherry_mvp/core/models/model.dart';
import 'package:cherry_mvp/core/services/error_string.dart';
import 'package:cherry_mvp/core/services/google_auth_service.dart';
import 'package:cherry_mvp/core/services/safe_log.dart';
import 'package:cherry_mvp/core/utils/result.dart';

enum RevokeAppleTokenResult {
  /// Apple is not linked to the account; revocation was skipped.
  skipped,

  /// Apple authorization token was successfully revoked.
  success,

  /// User explicitly cancelled the Apple reauthentication prompt.
  userCancelled,

  /// Revocation failed due to technical error, but account deletion should not be blocked.
  failedNonBlocking,
}

class FirebaseAuthService {
  final FirebaseAuth firebaseAuth;
  final int maxRevokeAttempts;
  final Duration revokeRetryDelay;

  FirebaseAuthService({
    required this.firebaseAuth,
    this.maxRevokeAttempts = 3,
    this.revokeRetryDelay = const Duration(milliseconds: 100),
  });

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

  bool isAppleLinked([User? user]) {
    final targetUser = user ?? firebaseAuth.currentUser;
    if (targetUser == null) return false;
    return targetUser.providerData.any((info) => info.providerId == 'apple.com');
  }

  Future<RevokeAppleTokenResult> revokeAppleAccessIfLinked() async {
    final user = firebaseAuth.currentUser;
    if (user == null || !isAppleLinked(user)) {
      return RevokeAppleTokenResult.skipped;
    }

    final UserCredential userCredential;
    try {
      final appleProvider = AppleAuthProvider();
      appleProvider.addScope('email');
      appleProvider.addScope('name');

      if (kIsWeb) {
        userCredential = await user.reauthenticateWithPopup(appleProvider);
      } else {
        userCredential = await user.reauthenticateWithProvider(appleProvider);
      }
    } on FirebaseAuthException catch (e) {
      if (_isCancellationCode(e.code)) {
        return RevokeAppleTokenResult.userCancelled;
      }
      SafeLog.event(
        AppLogEvent.authenticationOperationFailed,
        level: SafeLogLevel.warning,
      );
      return RevokeAppleTokenResult.failedNonBlocking;
    } on PlatformException catch (e) {
      if (_isCancellationCode(e.code)) {
        return RevokeAppleTokenResult.userCancelled;
      }
      SafeLog.event(
        AppLogEvent.authenticationOperationFailed,
        level: SafeLogLevel.warning,
      );
      return RevokeAppleTokenResult.failedNonBlocking;
    } catch (_) {
      SafeLog.event(
        AppLogEvent.authenticationOperationFailed,
        level: SafeLogLevel.warning,
      );
      return RevokeAppleTokenResult.failedNonBlocking;
    }

    final authorizationCode = userCredential.additionalUserInfo?.authorizationCode;
    if (authorizationCode == null || authorizationCode.isEmpty) {
      SafeLog.event(
        AppLogEvent.authenticationOperationFailed,
        level: SafeLogLevel.warning,
      );
      return RevokeAppleTokenResult.failedNonBlocking;
    }

    final revokeSuccess = await _revokeTokenWithRetry(authorizationCode);
    if (revokeSuccess) {
      return RevokeAppleTokenResult.success;
    }

    SafeLog.event(
      AppLogEvent.authenticationOperationFailed,
      level: SafeLogLevel.warning,
    );
    return RevokeAppleTokenResult.failedNonBlocking;
  }

  Future<bool> _revokeTokenWithRetry(String authorizationCode) async {
    for (var attempt = 1; attempt <= maxRevokeAttempts; attempt++) {
      try {
        await firebaseAuth.revokeTokenWithAuthorizationCode(authorizationCode);
        return true;
      } catch (error) {
        final isTransient = _isTransientRevocationError(error);
        final hasMoreAttempts = attempt < maxRevokeAttempts;

        if (isTransient && hasMoreAttempts) {
          SafeLog.event(AppLogEvent.networkRetryStarted);
          if (revokeRetryDelay > Duration.zero) {
            await Future<void>.delayed(revokeRetryDelay);
          }
          continue;
        }

        if (isTransient && !hasMoreAttempts) {
          SafeLog.event(
            AppLogEvent.networkRetryFailed,
            level: SafeLogLevel.warning,
          );
        }
        return false;
      }
    }
    return false;
  }

  static bool _isTransientRevocationError(Object error) {
    if (error is FirebaseAuthException) {
      final code = error.code.toLowerCase();
      return code == 'network-request-failed' ||
          code == 'timeout' ||
          code == 'too-many-requests' ||
          code == 'internal-error';
    }
    if (error is TimeoutException) return true;
    final errStr = error.toString().toLowerCase();
    return errStr.contains('socket') ||
        errStr.contains('timeout') ||
        errStr.contains('connection');
  }

  static bool _isCancellationCode(String code) {
    final normalized = code.toLowerCase();
    return normalized == 'canceled' ||
        normalized == 'user-cancelled' ||
        normalized == 'user-canceled' ||
        normalized == 'popup-closed-by-user' ||
        normalized == 'web-context-canceled' ||
        normalized == 'web-context-cancelled' ||
        normalized == '1001' ||
        normalized == 'error_cancel';
  }
}
