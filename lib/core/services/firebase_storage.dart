import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'error_string.dart';

class StorageProvider {
  final FirebaseStorage firebaseStorage;

  StorageProvider({required this.firebaseStorage});

  Future<Result<String>> uploadImage(File imageFile, String firstName) async {
    try {
      final storageRef = firebaseStorage.ref();
      final imageRef = storageRef.child('user_images/${firstName}_profile_picture.png');

      await imageRef.putFile(imageFile);

      // Return the download URL
      return Result.success(await imageRef.getDownloadURL());
    }on FirebaseException catch (e) {
      return Result.failure(e.message ?? ErrorStrings.storageError);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
}