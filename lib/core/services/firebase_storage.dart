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
}
