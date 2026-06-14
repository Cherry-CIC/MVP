import 'package:flutter/foundation.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/features/forgot_password/forgot_password_repository.dart';

class ForgotPasswordViewModel extends ChangeNotifier {
  final ForgotPasswordRepository forgotPasswordRepository;
  final NavigationProvider navigator;

  ForgotPasswordViewModel({required this.forgotPasswordRepository, required this.navigator});

  Status _status = Status.uninitialized;
  Status get status => _status;

  void clearStatus() {
    _status = Status.uninitialized;
    notifyListeners();
  }

  Future<Result<void>> sendPasswordResetEmail(String email) async {
    _status = Status.loading;
    notifyListeners();

    try {
      final result = await forgotPasswordRepository.sendPasswordResetEmail(email);
      if (result.isSuccess) {
        _status = Status.success;
      } else {
        _status = Status.failure(result.error ?? "");
      }
      notifyListeners();
      return result;
    } catch (e) {
      _status = Status.failure(e.toString());
      notifyListeners();
      return Result.failure(e.toString());
    }
  }

  void goBack() {
    navigator.goBack();
  }
}
