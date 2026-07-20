import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cherry_mvp/core/models/user.dart';
import 'package:cherry_mvp/core/router/router.dart';
import 'package:cherry_mvp/core/services/services.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/features/login/login_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final LoginRepository loginRepository;
  final NavigationProvider navigator;
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;
  final ApiService apiService;

  AuthViewModel({
    required this.loginRepository,
    required this.navigator,
    required this.firebaseAuth,
    required this.firestore,
    required this.apiService,
  });

  Status _status = Status.uninitialized;
  Status _deleteAccountStatus = Status.uninitialized;
  Status get status => _status;
  Status get deleteAccountStatus => _deleteAccountStatus;
  bool get isDeletingAccount => _deleteAccountStatus.type == StatusType.loading;
  User? get currentUser => firebaseAuth.currentUser;

  UserCredentials? userCredentials;
  bool isLoadingUser = false;

  Future<void> loadCurrentUser() async {
    if (currentUser == null) return;

    isLoadingUser = true;
    notifyListeners();

    final doc = await firestore.collection('users').doc(currentUser!.uid).get();

    if (doc.exists) {
      userCredentials = UserCredentials.fromFirestore(
        doc.data()!,
        currentUser!.uid,
      );
    } else {
      userCredentials = UserCredentials.fromAuth(currentUser!);
    }

    isLoadingUser = false;
    notifyListeners();
  }

  // TODO: ideally, instead of passing context and handling SnackBars here, they should be handled in the
  // TODO: calling view. Need to refactor.
  Future<void> logout(BuildContext context) async {
    _status = Status.loading;
    notifyListeners();

    try {
      final result = await _signOutAndClearPrefs();

      if (result.isSuccess) {
        _status = Status.success;
        navigator.goBack();
      } else {
        _status = Status.failure(result.error ?? "Logout failed");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Logout failed: ${result.error}')),
          );
        }
      }
    } catch (e) {
      _status = Status.failure(e.toString());
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      notifyListeners();
    }
  }

  Future<Result<void>> deleteAccount() async {
    if (isDeletingAccount) {
      return Result.failure('Account deletion is already in progress');
    }

    _deleteAccountStatus = Status.loading;
    notifyListeners();

    try {
      final result = await apiService.delete<Map<String, dynamic>>(
        ApiEndpoints.deleteAccount,
      );

      if (!result.isSuccess) {
        final message = result.error ?? 'Failed to delete account';
        _deleteAccountStatus = Status.failure(message);
        notifyListeners();
        return Result.failure(message);
      }

      final response = result.value;
      if (response != null && response['success'] == false) {
        final message = response['message']?.toString() ?? 'Failed to delete account';
        _deleteAccountStatus = Status.failure(message);
        notifyListeners();
        return Result.failure(message);
      }

      final signOutResult = await _signOutAndClearPrefs();
      if (!signOutResult.isSuccess) {
        final message = signOutResult.error ?? 'Account deleted, but local sign out failed';
        _deleteAccountStatus = Status.failure(message);
        notifyListeners();
        return Result.failure(message);
      }

      _deleteAccountStatus = Status.success;
      notifyListeners();
      unawaited(
        navigator.navigateToAndRemoveUntil(
          AppRoutes.welcome,
          (_) => false,
        ),
      );
      return Result.success(null);
    } catch (e) {
      final message = 'Failed to delete account';
      _deleteAccountStatus = Status.failure(message);
      notifyListeners();
      return Result.failure(message);
    }
  }

  Future<Result<void>> _signOutAndClearPrefs() async {
    final result = await loginRepository.logout();
    if (!result.isSuccess) {
      return Result.failure(result.error);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    return Result.success(null);
  }
}
