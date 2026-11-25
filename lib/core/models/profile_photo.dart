import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import '../config/app_strings.dart';
import '../utils/result.dart';

class ProfilePhoto {
  ProfilePhoto._(this.bytes, this.contentType);

  final Uint8List bytes;
  final String contentType;
  static const maxBytes = 5 * 1024 * 1024;
  static const _types = {'image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif'};

  // A failed save can be retried without replacing the current photo or
  // creating another copy of the selected file.
  String pathFor(String uid) => 'user_images/$uid/${sha256.convert(bytes)}';

  static Future<Result<ProfilePhoto>> read(XFile file) async {
    try {
      final size = await file.length();
      if (size <= 0 || size >= maxBytes) return Result.failure(AppStrings.profilePhotoSizeError);
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty || bytes.length >= maxBytes) return Result.failure(AppStrings.profilePhotoSizeError);
      final type = lookupMimeType('', headerBytes: bytes);
      if (type == null || !_types.contains(type)) return Result.failure(AppStrings.profilePhotoTypeError);
      return Result.success(ProfilePhoto._(bytes, type));
    } catch (_) {
      return Result.failure(AppStrings.errorPickingImage);
    }
  }
}
