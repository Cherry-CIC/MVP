/// Where listing photos must be uploaded, and what they must look like, to be
/// accepted by the backend's listing safeguards (cherry-Backend
/// `ListingMediaService` and `security/storage.rules`).
///
/// The backend only accepts a new photo when it lives directly under
/// `listing-media-v1/<owner uid>/`, carries the owner and policy metadata
/// below, is a JPEG, PNG or WebP no larger than 10 MiB, and the listing has at
/// most 10 photos. The legacy `products/<uid>/` folder is read-only.
const String listingMediaFolder = 'listing-media-v1';
const String listingMediaPolicy = 'listing-v1';
const int maxListingPhotos = 10;
const int maxListingPhotoBytes = 10 * 1024 * 1024;

/// How many leading bytes [detectListingPhotoFormat] needs.
const int listingPhotoHeaderLength = 12;

class ListingPhotoFormat {
  const ListingPhotoFormat._(this.extension, this.contentType);

  final String extension;
  final String contentType;

  static const jpeg = ListingPhotoFormat._('jpg', 'image/jpeg');
  static const png = ListingPhotoFormat._('png', 'image/png');
  static const webp = ListingPhotoFormat._('webp', 'image/webp');
}

/// Identifies a photo from its first bytes rather than its file name.
///
/// The backend decodes every photo and rejects one whose real format differs
/// from its declared content type, so an extension cannot be trusted: a HEIC
/// image saved as `photo.jpg` must be refused here, not after upload.
/// Returns null for anything that is not a JPEG, PNG or WebP.
ListingPhotoFormat? detectListingPhotoFormat(List<int> header) {
  bool startsWith(List<int> signature, {int offset = 0}) {
    if (header.length < offset + signature.length) return false;
    for (var i = 0; i < signature.length; i++) {
      if (header[offset + i] != signature[i]) return false;
    }
    return true;
  }

  if (startsWith(const [0xFF, 0xD8, 0xFF])) return ListingPhotoFormat.jpeg;
  if (startsWith(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) {
    return ListingPhotoFormat.png;
  }
  // WebP is a RIFF container: "RIFF", a 4-byte size, then "WEBP". Other RIFF
  // files (WAV, AVI) share the first four bytes.
  if (startsWith(const [0x52, 0x49, 0x46, 0x46]) && startsWith(const [0x57, 0x45, 0x42, 0x50], offset: 8)) {
    return ListingPhotoFormat.webp;
  }
  return null;
}
