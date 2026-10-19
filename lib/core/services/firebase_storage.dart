import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'error_string.dart';

class StorageProvider {
  final FirebaseStorage firebaseStorage;

  StorageProvider({required this.firebaseStorage});

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

  /// Like [uploadImage], but declares the content type and custom metadata.
  ///
  /// Needed for locations whose Storage rules require them, such as the listing
  /// media folder, where a missing `ownerUid` makes the upload fail.
  Future<Result<String>> uploadImageWithMetadata(
    File imageFile,
    String storagePath, {
    required String contentType,
    required Map<String, String> customMetadata,
  }) async {
    try {
      final imageRef = firebaseStorage.ref().child(storagePath);

      await imageRef.putFile(
        imageFile,
        SettableMetadata(contentType: contentType, customMetadata: customMetadata),
      );

      return Result.success(await imageRef.getDownloadURL());
    } on FirebaseException catch (e) {
      return Result.failure(e.message ?? ErrorStrings.storageError);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
}
