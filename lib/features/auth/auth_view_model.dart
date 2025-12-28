import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:cherry_mvp/features/login/login_repository.dart';
import 'package:cherry_mvp/core/router/router.dart';
import 'package:cherry_mvp/core/utils/utils.dart';

class AuthViewModel extends ChangeNotifier {
  final LoginRepository loginRepository;

  AuthViewModel({required this.loginRepository});

  Status _status = Status.uninitialized;
  Status get status => _status;
  User? get currentUser => FirebaseAuth.instance.currentUser;

  Future<void> logout(BuildContext context) async {
    _status = Status.loading;
    notifyListeners();

    try {
      final result = await loginRepository.logout();

      if (result.isSuccess) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        _status = Status.success;

        if (context.mounted) {
          Provider.of<NavigationProvider>(
            context,
            listen: false,
          ).replaceWith(AppRoutes.welcome);
        }
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
