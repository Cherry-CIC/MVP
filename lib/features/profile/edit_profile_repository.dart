import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cherry_mvp/core/models/profile_photo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/services/services.dart';
import 'package:cherry_mvp/core/utils/utils.dart';

abstract class IEditProfileRepository {
  Future<Result<void>> updateProfile({
    required String uid,
    ProfilePhoto? photo,
    String? displayName,
    String? phoneNumber,
  });
}

class EditProfileRepository implements IEditProfileRepository {
  final ApiService apiService;

  final StorageProvider storage;
  final FirebaseAuth auth;

  final FirebaseFirestore firestore;

  EditProfileRepository(this.apiService, this.storage, this.auth, this.firestore);

  // Some existing profiles are keyed by UID but have no id field for the API lookup.
  Future<bool> _linkExistingProfile(String uid) {
    final profile = firestore.collection(FirestoreConstants.users).doc(uid);
    return firestore.runTransaction((transaction) async {
      final data = (await transaction.get(profile)).data();
      if (data == null || auth.currentUser?.uid != uid) return false;
      if (data.containsKey('firebaseUid') && data['firebaseUid'] != uid) return false;
      if (data.containsKey('id')) return data['id'] == uid;
      transaction.update(profile, {'id': uid});
      return true;
    });
  }

  @override
  Future<Result<void>> updateProfile({
    required String uid,
    ProfilePhoto? photo,
    String? displayName,
    String? phoneNumber,
  }) async {
    // Only changed fields reach this method. Explain the UK prefix before
    // sending a number that the backend's international format check rejects.
    if (phoneNumber?.trim().startsWith('0') == true) {
      return Result.failure(AppStrings.editProfilePhoneInternationalFormat);
    }

    String? photoUrl;
    if (photo != null) {
      final upload = await storage.uploadProfilePhoto(uid, photo);
      if (!upload.isSuccess) return Result.failure(upload.error);
      photoUrl = upload.value;
      if (photoUrl == null || photoUrl.isEmpty) return Result.failure(AppStrings.editProfileSaveFailed);
    }
    if (auth.currentUser?.uid != uid) return Result.failure(AppStrings.editProfileSaveFailed);

    final changes = {
      'photoURL': ?photoUrl,
      'displayName': ?displayName,
      'phoneNumber': ?phoneNumber,
    };
    Future<Result<Map<String, dynamic>>> saveChanges() =>
        apiService.put<Map<String, dynamic>>(ApiEndpoints.profile, data: changes);

    var result = await saveChanges();
    if (photo != null && result.statusCode == 404 && auth.currentUser?.uid == uid) {
      try {
        final linked = await _linkExistingProfile(uid);
        if (linked && auth.currentUser?.uid == uid) result = await saveChanges();
      } on FirebaseException {
        return Result.failure(AppStrings.editProfileSaveFailed);
      }
    }

    if (!result.isSuccess) {
      final message = result.error;
      return Result.failure(
        message == null || message == ErrorStrings.apiError
            ? AppStrings.editProfileSaveFailed
            : message,
      );
    }

    final response = result.value;
    if (response != null && response['success'] == false) {
      return Result.failure(
        response['message']?.toString() ?? AppStrings.editProfileSaveFailed,
      );
    }

    return Result.success(null);
  }
}
