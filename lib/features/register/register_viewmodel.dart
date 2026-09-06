import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/services/safe_log.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/features/register/register_model.dart';
import 'package:cherry_mvp/features/register/register_repository.dart';

class RegisterViewModel extends ChangeNotifier {
  final RegisterRepository registerRepository;
  final NavigationProvider navigator;

  RegisterViewModel({required this.registerRepository, required this.navigator});

  //private variable (not exposed)
  Status _status = Status.uninitialized;

  //public (exposed to loginpage)
  Status get status => _status;

  Future<void> register(
    String firstName,
    String email,
    String username,
    String phone,
    String password,
    File? image,
  ) async {
    _status = Status.loading;
    notifyListeners();

    try {
      final result = await registerRepository.register(
        RegisterRequest(
          firstname: firstName,
          email: email,
          phone: phone,
          username: username,
          password: password,
          imageFile: image,
        ),
      );
      if (result.isSuccess) {
        _status = Status.success;
        navigator.goBack();
      } else {
        _status = Status.failure(result.error ?? "");
        SafeLog.event(
          AppLogEvent.registrationFailed,
          level: SafeLogLevel.warning,
        );
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
