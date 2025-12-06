import 'dart:io';

import 'package:cherry_mvp/features/register/register_model.dart';
import 'package:cherry_mvp/features/register/register_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:logging/logging.dart';

class RegisterViewModel extends ChangeNotifier {
  final RegisterRepository registerRepository;

  RegisterViewModel({required this.registerRepository});

  //private variable (not exposed)
  Status _status = Status.uninitialized;

  //public (exposed to loginpage)
  Status get status => _status;

  final _log = Logger('RegisterViewModel');

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
      } else {
        _status = Status.failure(result.error ?? "");
        _log.warning('Registration failed! ${result.error}');
      }
    } catch (e) {
      _status = Status.failure(e.toString());
    }

    notifyListeners();
  }
}
