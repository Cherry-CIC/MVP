import 'package:cherry_mvp/features/products/edit_listing/image_upload_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('detectImageUploadFormat', () {
    test('recognises JPEG, PNG and WebP by their signatures', () {
      expect(detectImageUploadFormat([0xFF, 0xD8, 0xFF, 0xE0, 0, 0, 0, 0, 0, 0, 0, 0]), ImageUploadFormat.jpeg);
      expect(
        detectImageUploadFormat([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 0]),
        ImageUploadFormat.png,
      );
      expect(
        detectImageUploadFormat([0x52, 0x49, 0x46, 0x46, 1, 2, 3, 4, 0x57, 0x45, 0x42, 0x50]),
        ImageUploadFormat.webp,
      );
    });

    test('maps formats to stable extensions', () {
      expect((ImageUploadFormat.jpeg.extension, ImageUploadFormat.jpeg.contentType), ('jpg', 'image/jpeg'));
      expect((ImageUploadFormat.png.extension, ImageUploadFormat.png.contentType), ('png', 'image/png'));
      expect((ImageUploadFormat.webp.extension, ImageUploadFormat.webp.contentType), ('webp', 'image/webp'));
    });

    test('refuses unsupported and truncated formats', () {
      expect(detectImageUploadFormat([0, 0, 0, 0x18, 0x66, 0x74, 0x79, 0x70, 0x68, 0x65, 0x69, 0x63]), isNull);
      expect(detectImageUploadFormat([0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0, 0, 0, 0, 0, 0]), isNull);
      expect(detectImageUploadFormat([0x52, 0x49, 0x46, 0x46, 1, 2, 3, 4, 0x57]), isNull);
      expect(detectImageUploadFormat(const []), isNull);
    });

    test('keeps the listing limits aligned with the API', () {
      expect(maxListingPhotos, 10);
      expect(maxListingPhotoBytes, 10 * 1024 * 1024);
    });
  });
}
