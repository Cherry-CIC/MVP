import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'error_string.dart';

class StorageProvider {
  static const int maxImageBytes = 2 * 1024 * 1024;

  final FirebaseStorage firebaseStorage;

  StorageProvider({required this.firebaseStorage});

  /// Generic upload method for any file path
  Future<Result<String>> uploadImage(File imageFile, String storagePath) async {
    try {
      if (!imageFile.existsSync()) {
        return Result.failure('Image file could not be found.');
      }

      final fileSize = imageFile.lengthSync();
      if (fileSize > maxImageBytes) {
        return Result.failure('Image must be 2 MB or smaller.');
      }

      final contentType = _contentTypeForPath(imageFile.path);
      if (contentType == null) {
        return Result.failure('Please choose a JPG, PNG or WebP image.');
      }

      final storageRef = firebaseStorage.ref();
      final imageRef = storageRef.child(storagePath);

      await imageRef.putFile(
        imageFile,
        SettableMetadata(contentType: contentType),
      );

      // Return the download URL
      return Result.success(await imageRef.getDownloadURL());
    } on FirebaseException catch (e) {
      return Result.failure(e.message ?? ErrorStrings.storageError);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  String? _contentTypeForPath(String path) {
    final extension = path.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return null;
    }
  }
}
