import 'dart:async';

import 'package:cherry_mvp/core/models/profile_photo.dart';
import 'package:image_picker/image_picker.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/models/model.dart';
import 'package:cherry_mvp/core/services/services.dart';
import 'package:cherry_mvp/core/services/safe_log.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/register/register_model.dart';

class RegisterRepository {
  final FirebaseAuthService _authService;
  final FirestoreService _firestoreService;
  final StorageProvider _storage;

  RegisterRepository(this._authService, this._firestoreService, this._storage);

  Future<Result<UserCredentials?>> register(RegisterRequest request) async {
    final usernameTaken = await _isUsernameTaken(request.username);
    if (usernameTaken) {
      return Result.failure("Username is already taken.");
    }

    ProfilePhoto? photo;
    if (request.imageFile case final file?) {
      final selection = await ProfilePhoto.read(XFile(file.path));
      if (!selection.isSuccess) return Result.failure(selection.error);
      photo = selection.value;
    }

    final result = await _authService.signUp(request.email, request.password);

    if (result.isSuccess) {
      // If registration is successful, proceed with uploading user image and saving data
      final userCredentials = result.value;

      String? photoUrl;
      final uid = userCredentials?.uid;
      if (uid == null || uid.isEmpty) return Result.failure(AppStrings.editProfileSaveFailed);
      var photoUploadFailed = false;
      if (photo != null) {
        final upload = await _storage.uploadProfilePhoto(uid, photo);
        photoUrl = upload.value;
        photoUploadFailed = !upload.isSuccess;
      }

      // Now, create the user in Firestore
      final firestoreResult = await createUserInFirestore(
        uid,
        request.username,
        request.firstname,
        request.email,
        request.phone,
        photoUrl ?? "", // Pass the photo URL if available
      );

      if (firestoreResult.isSuccess) {
        unawaited(_sendVerificationEmail());
        if (photoUploadFailed) {
          return Result.failure('Your account was created. Sign in and add your photo in Edit profile.');
        }
        return Result.success(userCredentials);
      } else {
        return Result.failure(firestoreResult.error);
      }
    } else {
      return Result.failure(result.error);
    }
  }

  Future<void> _sendVerificationEmail() async {
    try {
      final verificationResult = await _authService.sendVerificationEmail();
      if (!verificationResult.isSuccess) {
        SafeLog.event(
          AppLogEvent.authenticationOperationFailed,
          level: SafeLogLevel.warning,
        );
      }
    } catch (_) {
      SafeLog.event(
        AppLogEvent.authenticationOperationFailed,
        level: SafeLogLevel.warning,
      );
    }
  }

  Future<bool> _isUsernameTaken(String username) async {
    final result = await _firestoreService.queryCollection(
      FirestoreConstants.pathUserCollection,
      field: FirestoreConstants.username,
      value: username,
    );

    return result.isSuccess && result.value!.isNotEmpty;
  }

  Future<Result<void>> createUserInFirestore(
    String uid,
    String username,
    String firstName,
    String email,
    String phone,
    String photo,
  ) async {
    // Create user document in Firestore
    // Prepare the data to be saved
    Map<String, dynamic> data = {
      FirestoreConstants.username: username,
      FirestoreConstants.firstname: firstName,
      FirestoreConstants.email: email,
      FirestoreConstants.phone: phone,
      FirestoreConstants.id: uid,
      FirestoreConstants.photoUrl: photo,
      FirestoreConstants.createdAt: FieldValue.serverTimestamp(),
    };

    final result = await _firestoreService.saveDocument(
      FirestoreConstants.pathUserCollection,
      uid,
      data,
    );

    if (result.isSuccess) {
      await _firestoreService.fetchUser(uid);
      return Result.success(null);
    } else {
      return Result.failure(result.error);
    }
  }
}
