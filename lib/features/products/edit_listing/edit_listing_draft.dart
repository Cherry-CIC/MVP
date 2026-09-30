import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/utils/validator.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class ListingPhoto {
  const ListingPhoto.remote(String url) : remoteUrl = url, file = null;
  const ListingPhoto.local(XFile image) : file = image, remoteUrl = null;

  final String? remoteUrl;
  final XFile? file;
}

/// Only descriptive fields belong here. Never serialise a whole Product to PUT.
class EditListingDraft {
  EditListingDraft({
    required this.name,
    required this.description,
    required this.quality,
    required this.size,
    required this.categoryId,
    required List<ListingPhoto> photos,
  }) : photos = List.unmodifiable(photos);

  factory EditListingDraft.fromProduct(Product product) => EditListingDraft(
    name: product.name,
    description: product.description,
    quality: product.quality,
    size: product.size,
    categoryId: product.categoryId,
    photos: product.productImages.map(ListingPhoto.remote).toList(),
  );

  final String name;
  final String description;
  final String quality;
  final String size;
  final String? categoryId;
  final List<ListingPhoto> photos;

  EditListingDraft copyWith({
    String? name,
    String? description,
    String? quality,
    String? size,
    String? categoryId,
    List<ListingPhoto>? photos,
  }) => EditListingDraft(
    name: name ?? this.name,
    description: description ?? this.description,
    quality: quality ?? this.quality,
    size: size ?? this.size,
    categoryId: categoryId ?? this.categoryId,
    photos: photos ?? this.photos,
  );

  static String? validateTitle(String? value) {
    final error = validateDonationFormFields(value);
    if (error != null) return error;
    final length = value!.trim().length;
    if (length < 3) return 'Use at least 3 characters for the title';
    if (length > 100) return 'Use no more than 100 characters for the title';
    return null;
  }

  static String? validateDescription(String? value) {
    // The update API explicitly permits clearing an optional description.
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final error = validateDonationFormFields(value);
    if (error != null) return error;
    if (text.length > 500) return 'Use no more than 500 characters for the description';
    return null;
  }

  String? validate(Product original) {
    final textError = validateTitle(name) ?? validateDescription(description);
    if (textError != null) return textError;
    if (quality.trim().isEmpty || size.trim().isEmpty) return 'Choose a condition and size';
    if (categoryId != original.categoryId && (categoryId?.trim().isEmpty ?? true)) {
      return 'Choose a category';
    }
    if (photos.isEmpty) return 'Keep at least one photo';
    for (final photo in photos) {
      if (photo.remoteUrl != null && !original.productImages.contains(photo.remoteUrl)) {
        return 'Reload this listing before changing its photos';
      }
    }
    return null;
  }

  bool hasChanges(Product original) =>
      name.trim() != original.name ||
      description.trim() != original.description ||
      quality != original.quality ||
      size != original.size ||
      categoryId != original.categoryId ||
      photos.any((photo) => photo.file != null) ||
      !listEquals(photos.map((photo) => photo.remoteUrl).toList(), original.productImages);

  Map<String, dynamic> changedFields(Product original, List<String> imageUrls) => {
    if (name.trim() != original.name) 'name': name.trim(),
    if (description.trim() != original.description) 'description': description.trim(),
    if (quality != original.quality) 'quality': quality,
    if (size != original.size) 'size': size,
    if (categoryId != original.categoryId) 'categoryId': categoryId,
    if (!listEquals(imageUrls, original.productImages)) 'product_images': imageUrls,
  };
}
