import 'package:flutter/cupertino.dart';
import 'package:logging/logging.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/features/login/login_model.dart';
import 'package:cherry_mvp/features/login/login_repository.dart';

class LoginViewModel extends ChangeNotifier {
  final LoginRepository loginRepository;
  final NavigationProvider navigator;

  LoginViewModel({required this.loginRepository, required this.navigator});

  //private variable (not exposed)
  Status _status = Status.uninitialized;

  //public (exposed to loginpage)
  Status get status => _status;

  final _log = Logger('LoginViewModel');
  void clearStatus() {
    _status = Status.uninitialized;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _status = Status.loading;
    notifyListeners();

    try {
      final result = await loginRepository.login(LoginRequest(email: email, password: password));
      if (result.isSuccess) {
        _status = Status.success;
        navigator.goBack();
      } else {
        _status = Status.failure(result.error ?? "");
        _log.warning('Login failed! ${result.error}');
      }
    } catch (e) {
      _status = Status.failure(e.toString());
    }

    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    _status = Status.loading;
    notifyListeners();

    try {
      final result = await loginRepository.signInWithGoogle();
      if (result.isSuccess) {
        _status = Status.success;
      } else {
        _status = Status.failure(result.error ?? "");
        _log.warning('Login failed! ${result.error}');
      }
    } catch (e) {
      _status = Status.failure(e.toString());
    }

    notifyListeners();
  }

  Future<void> signInWithApple() async {
    _status = Status.loading;
    notifyListeners();

    try {
      final result = await loginRepository.signInWithApple();

      if (result.isSuccess) {
        _status = Status.success;
      } else {
        _status = Status.failure(result.error ?? "");
        _log.warning('Login failed! ${result.error}');
      }
    } catch (e) {
      _status = Status.failure(e.toString());
    }

    notifyListeners();
  }

  void goBack() {
    navigator.goBack();
  }
}
