/// Maximum number and size of photos accepted by the listing API.
const int maxListingPhotos = 10;
const int maxListingPhotoBytes = 10 * 1024 * 1024;

/// How many leading bytes [detectImageUploadFormat] needs.
const int imageHeaderLength = 12;

class ImageUploadFormat {
  const ImageUploadFormat._(this.extension, this.contentType);

  final String extension;
  final String contentType;

  static const jpeg = ImageUploadFormat._('jpg', 'image/jpeg');
  static const png = ImageUploadFormat._('png', 'image/png');
  static const webp = ImageUploadFormat._('webp', 'image/webp');
}

/// Identifies a supported image from its bytes rather than its file name.
ImageUploadFormat? detectImageUploadFormat(List<int> header) {
  bool startsWith(List<int> signature, {int offset = 0}) {
    if (header.length < offset + signature.length) return false;
    for (var i = 0; i < signature.length; i++) {
      if (header[offset + i] != signature[i]) return false;
    }
    return true;
  }

  if (startsWith(const [0xFF, 0xD8, 0xFF])) return ImageUploadFormat.jpeg;
  if (startsWith(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) {
    return ImageUploadFormat.png;
  }
  if (startsWith(const [0x52, 0x49, 0x46, 0x46]) && startsWith(const [0x57, 0x45, 0x42, 0x50], offset: 8)) {
    return ImageUploadFormat.webp;
  }
  return null;
}
