import 'dart:io';
import 'dart:math';

import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/services/firebase_storage.dart';
import 'package:cherry_mvp/core/services/network/api_endpoints.dart';
import 'package:cherry_mvp/core/services/network/api_service.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/products/listing_details.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'edit_listing_draft.dart';
import 'image_upload_format.dart';

abstract class IEditListingRepository {
  bool canEdit(Product product);
  Future<Result<Product>> load(String productId);
  Future<EditListingSaveResult> save(Product original, EditListingDraft draft);
}

class EditListingSaveResult {
  const EditListingSaveResult.success(Product value)
    : product = value,
      error = null,
      requiresReload = false,
      writeAttempted = true;
  const EditListingSaveResult.failure(this.error, {this.requiresReload = false, this.writeAttempted = false})
    : product = null;

  final Product? product;
  final String? error;
  final bool requiresReload;
  final bool writeAttempted;
  bool get isSuccess => product != null;
}

class EditListingRepository implements IEditListingRepository {
  EditListingRepository({
    required ApiService apiService,
    required ProductRepository productRepository,
    required StorageProvider storageProvider,
    required String? Function() currentUserId,
  }) : _api = apiService,
       _products = productRepository,
       _storage = storageProvider,
       _readUserId = currentUserId;

  final ApiService _api;
  final ProductRepository _products;
  final StorageProvider _storage;
  final String? Function() _readUserId;

  @override
  bool canEdit(Product product) {
    final uid = _readUserId();
    return uid != null &&
        uid.isNotEmpty &&
        product.userId == uid &&
        product.number > 0 &&
        (product.status == 'active' || product.status == 'unlisted');
  }

  @override
  Future<Result<Product>> load(String productId) async {
    final uid = _readUserId();
    if (uid == null || uid.isEmpty) return Result.failure('Sign in to edit your listing');
    final result = await _products.fetchProduct(productId);
    if (!result.isSuccess || result.value == null) return result;
    if (uid != _readUserId() || !canEdit(result.value!)) {
      return Result.failure('This listing cannot be edited at the moment');
    }
    return result;
  }

  @override
  Future<EditListingSaveResult> save(Product original, EditListingDraft draft) async {
    if (!canEdit(original)) {
      return const EditListingSaveResult.failure('This listing cannot be edited at the moment');
    }
    final validationError = draft.validate(original);
    if (validationError != null) return EditListingSaveResult.failure(validationError);
    if (!draft.hasChanges(original)) return const EditListingSaveResult.failure('There are no changes to save');
    final uid = _readUserId()!;
    var writeAttempted = false;
    try {
      final latest = await load(original.id);
      if (!latest.isSuccess || latest.value == null) {
        return EditListingSaveResult.failure(latest.error ?? 'Could not check this listing');
      }
      if (!sameListingDetails(original, latest.value!)) {
        return const EditListingSaveResult.failure(
          'This listing has changed. Reload it before editing again.',
          requiresReload: true,
        );
      }

      // Inspect every new photo before uploading any, so one unusable photo
      // cannot leave earlier ones orphaned in Storage.
      final formats = <ImageUploadFormat?>[];
      final photoError = await _inspectNewPhotos(draft.photos, formats);
      if (photoError != null) return EditListingSaveResult.failure(photoError);

      final imageUrls = <String>[];
      for (var index = 0; index < draft.photos.length; index++) {
        final photo = draft.photos[index];
        if (uid != _readUserId()) {
          return const EditListingSaveResult.failure('Your account changed. Reopen the listing.', requiresReload: true);
        }
        if (photo.remoteUrl != null) {
          imageUrls.add(photo.remoteUrl!);
          continue;
        }
        final format = formats[index]!;
        final nonce = List.generate(16, (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0')).join();
        final uploaded = await _storage.uploadImage(
          File(photo.file!.path),
          'products/$uid/edit_$nonce.${format.extension}',
        );
        if (!uploaded.isSuccess || uploaded.value == null) {
          return const EditListingSaveResult.failure(
            'A photo could not be uploaded. Your listing has not been changed.',
          );
        }
        imageUrls.add(uploaded.value!);
      }
      if (uid != _readUserId()) {
        return const EditListingSaveResult.failure('Your account changed. Reopen the listing.', requiresReload: true);
      }

      writeAttempted = true;
      final result = await _api.put<dynamic>(
        ApiEndpoints.productById(original.id),
        data: draft.changedFields(original, imageUrls),
      );
      final response = result.value;
      final data = response is Map ? response['data'] : null;
      if (!result.isSuccess ||
          response is! Map ||
          response['success'] != true ||
          data is! Map ||
          data['id'] != original.id) {
        return const EditListingSaveResult.failure(
          'We could not confirm the save. Reload the listing to check its current details.',
          requiresReload: true,
          writeAttempted: true,
        );
      }
      final saved = await _products.fetchProduct(original.id);
      if (uid != _readUserId() || !saved.isSuccess || saved.value == null || saved.value!.userId != uid) {
        return const EditListingSaveResult.failure(
          'Your changes may have been saved. Reload the listing to check its current details.',
          requiresReload: true,
          writeAttempted: true,
        );
      }
      // Display server readback, never an optimistic copy of the submitted form.
      return EditListingSaveResult.success(saved.value!);
    } catch (_) {
      return EditListingSaveResult.failure(
        writeAttempted
            ? 'We could not confirm the save. Reload the listing to check its current details.'
            : 'Could not save your changes. Please try again.',
        requiresReload: writeAttempted,
        writeAttempted: writeAttempted,
      );
    }
    // Never delete media here, even after a successful save. Historical orders
    // or concurrent reads may still reference it. Retention is a backend task.
  }

  /// Reads the real format and size of each new photo, in the same order as
  /// [photos]; already-uploaded photos get a null entry in [formats].
  /// Returns a message for the first unusable photo, or null if all are fine.
  Future<String?> _inspectNewPhotos(List<ListingPhoto> photos, List<ImageUploadFormat?> formats) async {
    for (final photo in photos) {
      final image = photo.file;
      if (image == null) {
        formats.add(null);
        continue;
      }
      try {
        final file = File(image.path);
        if (await file.length() > maxListingPhotoBytes) {
          return 'Each photo must be no larger than 10 MB. Your listing has not been changed.';
        }
        final handle = await file.open();
        final List<int> header;
        try {
          header = await handle.read(imageHeaderLength);
        } finally {
          await handle.close();
        }
        final format = detectImageUploadFormat(header);
        if (format == null) {
          return 'Use JPEG, PNG or WebP photos. Your listing has not been changed.';
        }
        formats.add(format);
      } on FileSystemException {
        return 'A photo could not be read. Your listing has not been changed.';
      }
    }
    return null;
  }
}
