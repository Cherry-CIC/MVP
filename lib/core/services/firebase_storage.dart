import 'dart:io';

import 'package:cherry_mvp/core/models/profile_photo.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'error_string.dart';

class StorageProvider {
  final FirebaseStorage firebaseStorage;

  StorageProvider({required this.firebaseStorage});

  Future<Result<String>> uploadProfilePhoto(String uid, ProfilePhoto photo) async {
    final ref = firebaseStorage.ref(photo.pathFor(uid));
    try {
      try {
        return Result.success(await ref.getDownloadURL());
      } on FirebaseException catch (e) {
        if (e.code != 'object-not-found') rethrow;
      }
      await ref.putData(photo.bytes, SettableMetadata(contentType: photo.contentType));
      return Result.success(await ref.getDownloadURL());
    } on FirebaseException {
      return Result.failure('Could not upload your profile photo. Please try again.');
    }
  }

  /// Generic upload method for any file path
  Future<Result<String>> uploadImage(File imageFile, String storagePath) async {
    try {
      final storageRef = firebaseStorage.ref();
      final imageRef = storageRef.child(storagePath);

      await imageRef.putFile(imageFile);

      // Return the download URL
      return Result.success(await imageRef.getDownloadURL());
    } on FirebaseException catch (e) {
      return Result.failure(e.message ?? ErrorStrings.storageError);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
}
