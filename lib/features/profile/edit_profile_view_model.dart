import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/services/services.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/features/profile/edit_profile_repository.dart';

typedef UsernameTakenCheck = Future<Result<bool>> Function(String username, {String? excludeUid});
typedef UsernameSaver = Future<Result<void>> Function(String uid, String username);

class EditProfileViewModel extends ChangeNotifier {
  final IEditProfileRepository repository;
  final UsernameTakenCheck _isUsernameTaken;
  final UsernameSaver _saveUsername;

  EditProfileViewModel({
    required this.repository,
    UsernameTakenCheck? isUsernameTaken,
    UsernameSaver? saveUsername,
  })  : _isUsernameTaken = isUsernameTaken ?? UsernameService.isUsernameTaken,
        _saveUsername = saveUsername ?? UsernameService.saveUsername;

  Status _status = Status.uninitialized;
  Status get status => _status;
  bool get isSaving => _status.type == StatusType.loading;

  bool _isPartialSave = false;

  /// True when the name/phone write landed but the username write did not, so
  /// the backend now holds changes the local user state does not know about.
  /// The name and username live in different stores, so the two writes cannot
  /// be made atomic here; the caller has to reload instead.
  bool get isPartialSave => _isPartialSave;

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
    _isPartialSave = false;
    notifyListeners();

    var profileSaved = false;

    try {
      // Check username availability before writing anything.
      if (username != null) {
        final isTakenResult = await _isUsernameTaken(username, excludeUid: uid);
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
        profileSaved = true;
      }

      if (username != null) {
        final result = await _saveUsername(uid, username);
        if (!result.isSuccess) {
          // The name/phone write already landed, so report the partial outcome
          // rather than implying nothing was saved.
          if (profileSaved) {
            return _fail(AppStrings.editProfileUsernameNotSaved, isPartial: true);
          }
          return _fail(result.error ?? AppStrings.usernameSaveFailed);
        }
      }

      _status = Status.success;
      notifyListeners();
      return Result.success(null);
    } catch (_) {
      return _fail(AppStrings.editProfileSaveFailed, isPartial: profileSaved);
    }
  }

  Result<void> _fail(String message, {bool isPartial = false}) {
    _status = Status.failure(message);
    _isPartialSave = isPartial;
    notifyListeners();
    return Result.failure(message);
  }
}
