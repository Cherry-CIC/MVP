import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'error_string.dart';

class StorageProvider {
  final FirebaseStorage firebaseStorage;

  StorageProvider({required this.firebaseStorage});

  static const maxListingPhotos = 10;
  static const maxPhotoBytes = 10 * 1024 * 1024;
  static const maxPhotoPixels = 40000000;

  /// Upload a new, immutable object. Existing listing URLs are never copied or
  /// relabelled as proof of ownership.
  Future<Result<String>> uploadListingImage(File imageFile, String ownerUid) async {
    try {
      if (ownerUid.isEmpty || ownerUid.contains('/')) {
        return Result.failure('Sign in again before uploading photos');
      }
      if (await imageFile.length() > maxPhotoBytes) {
        return Result.failure('Each photo must be no larger than 10 MiB');
      }
      final photo = await prepareListingImage(await imageFile.readAsBytes());
      final nonce = List.generate(16, (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0')).join();
      final imageRef = firebaseStorage.ref('listing-media-v1/$ownerUid/$nonce.${photo.extension}');
      await imageRef.putData(
        photo.bytes,
        SettableMetadata(
          contentType: photo.contentType,
          customMetadata: {'ownerUid': ownerUid, 'mediaPolicy': 'listing-v1'},
        ),
      );
      return Result.success(await imageRef.getDownloadURL());
    } on FormatException catch (error) {
      return Result.failure(error.message);
    } on FirebaseException catch (_) {
      return Result.failure('This photo could not be uploaded. Please try again.');
    } catch (_) {
      return Result.failure('This photo could not be read. Choose a JPEG, PNG or WebP photo.');
    }
  }

  /// Decode before upload, checking dimensions before allocating the pixels.
  /// The native picker normally converts HEIC to JPEG. If it retains HEIC,
  /// Flutter's platform codec may decode it and we encode a bounded PNG.
  static Future<({Uint8List bytes, String extension, String contentType})> prepareListingImage(Uint8List bytes) async {
    if (bytes.isEmpty || bytes.length > maxPhotoBytes) {
      throw const FormatException('Each photo must be no larger than 10 MiB');
    }
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    ui.Image? image;
    try {
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      if (descriptor.width * descriptor.height > maxPhotoPixels) {
        throw const FormatException('Choose a photo smaller than 40 megapixels');
      }
      codec = await descriptor.instantiateCodec();
      if (codec.frameCount != 1) {
        throw const FormatException('Choose a still photo, rather than an animation');
      }
      image = (await codec.getNextFrame()).image;
      if (bytes.length >= 3 && bytes[0] == 0xff && bytes[1] == 0xd8 && bytes[2] == 0xff) {
        return (bytes: bytes, extension: 'jpg', contentType: 'image/jpeg');
      }
      if (bytes.length >= 8 && bytes[0] == 0x89 && String.fromCharCodes(bytes.sublist(1, 4)) == 'PNG') {
        return (bytes: bytes, extension: 'png', contentType: 'image/png');
      }
      if (bytes.length >= 12 &&
          String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
          String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
        return (bytes: bytes, extension: 'webp', contentType: 'image/webp');
      }
      final converted = await image.toByteData(format: ui.ImageByteFormat.png);
      if (converted == null || converted.lengthInBytes > maxPhotoBytes) {
        throw const FormatException('Choose a smaller photo or export it as JPEG');
      }
      return (bytes: converted.buffer.asUint8List(), extension: 'png', contentType: 'image/png');
    } finally {
      image?.dispose();
      codec?.dispose();
      descriptor?.dispose();
      buffer.dispose();
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
