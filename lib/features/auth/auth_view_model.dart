import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cherry_mvp/core/models/user.dart';
import 'package:cherry_mvp/core/router/router.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/features/login/login_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final LoginRepository loginRepository;
  final NavigationProvider navigator;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthViewModel({required this.loginRepository, required this.navigator});

  Status _status = Status.uninitialized;
  Status get status => _status;
  User? get currentUser => FirebaseAuth.instance.currentUser;

  UserCredentials? userCredentials;
  bool isLoadingUser = false;

  Future<void> loadCurrentUser() async {
    if (currentUser == null) return;

    isLoadingUser = true;
    notifyListeners();

    final doc = await _firestore.collection('users').doc(currentUser!.uid).get();

    if (doc.exists) {
      userCredentials = UserCredentials.fromFirestore(
        doc.data()!,
        currentUser!.uid,
      );
    } else {
      userCredentials = UserCredentials.fromAuth(currentUser!);
    }

    isLoadingUser = false;
    print(userCredentials?.firstname);
    notifyListeners();
  }

  // TODO: ideally, instead of passing context and handling SnackBars here, they should be handled in the
  // TODO: calling view. Need to refactor.
  Future<void> logout(BuildContext context) async {
    _status = Status.loading;
    notifyListeners();

    try {
      final result = await loginRepository.logout();

      if (result.isSuccess) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

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
}
