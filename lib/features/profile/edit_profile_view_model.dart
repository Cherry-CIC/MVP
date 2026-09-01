import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/services/services.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/features/profile/edit_profile_repository.dart';

class EditProfileViewModel extends ChangeNotifier {
  final IEditProfileRepository repository;

  EditProfileViewModel({required this.repository});

  Status _status = Status.uninitialized;
  Status get status => _status;
  bool get isSaving => _status.type == StatusType.loading;

  /// Saves the changed fields only; pass null for anything unchanged.
  Future<Result<void>> saveProfile({
    required String uid,
    String? firstName,
    String? username,
    String? phoneNumber,
  }) async {
    if (isSaving) {
      return Result.failure(AppStrings.editProfileSaveFailed);
    }

    _status = Status.loading;
    notifyListeners();

    try {
      // Check username availability before writing anything.
      if (username != null) {
        final isTakenResult = await UsernameService.isUsernameTaken(
          username,
          excludeUid: uid,
        );
        if (!isTakenResult.isSuccess) {
          return _fail(isTakenResult.error ?? AppStrings.editProfileSaveFailed);
        }
        if (isTakenResult.value == true) {
          return _fail(AppStrings.usernameTakenError);
        }
      }

      if (firstName != null || phoneNumber != null) {
        final result = await repository.updateProfile(
          displayName: firstName,
          phoneNumber: phoneNumber,
        );
        if (!result.isSuccess) {
          return _fail(result.error ?? AppStrings.editProfileSaveFailed);
        }
      }

      if (username != null) {
        final result = await UsernameService.saveUsername(uid, username);
        if (!result.isSuccess) {
          return _fail(result.error ?? AppStrings.usernameSaveFailed);
        }
      }

      _status = Status.success;
      notifyListeners();
      return Result.success(null);
    } catch (_) {
      return _fail(AppStrings.editProfileSaveFailed);
    }
  }

  Result<void> _fail(String message) {
    _status = Status.failure(message);
    notifyListeners();
    return Result.failure(message);
  }
}
