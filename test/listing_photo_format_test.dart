import 'package:cherry_mvp/features/products/edit_listing/listing_photo_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('detectListingPhotoFormat', () {
    test('recognises JPEG, PNG and WebP by their signatures', () {
      expect(detectListingPhotoFormat([0xFF, 0xD8, 0xFF, 0xE0, 0, 0, 0, 0, 0, 0, 0, 0]), ListingPhotoFormat.jpeg);
      expect(
        detectListingPhotoFormat([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 0]),
        ListingPhotoFormat.png,
      );
      expect(
        detectListingPhotoFormat([0x52, 0x49, 0x46, 0x46, 1, 2, 3, 4, 0x57, 0x45, 0x42, 0x50]),
        ListingPhotoFormat.webp,
      );
    });

    test('maps each format to the extension and content type the backend expects', () {
      expect((ListingPhotoFormat.jpeg.extension, ListingPhotoFormat.jpeg.contentType), ('jpg', 'image/jpeg'));
      expect((ListingPhotoFormat.png.extension, ListingPhotoFormat.png.contentType), ('png', 'image/png'));
      expect((ListingPhotoFormat.webp.extension, ListingPhotoFormat.webp.contentType), ('webp', 'image/webp'));
    });

    test('refuses HEIC and HEIF, which the backend cannot decode', () {
      expect(detectListingPhotoFormat([0, 0, 0, 0x18, 0x66, 0x74, 0x79, 0x70, 0x68, 0x65, 0x69, 0x63]), isNull);
      expect(detectListingPhotoFormat([0, 0, 0, 0x18, 0x66, 0x74, 0x79, 0x70, 0x6D, 0x69, 0x66, 0x31]), isNull);
    });

    test('refuses other image and media formats', () {
      // GIF89a
      expect(detectListingPhotoFormat([0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0, 0, 0, 0, 0, 0]), isNull);
      // BMP
      expect(detectListingPhotoFormat([0x42, 0x4D, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]), isNull);
    });

    test('does not mistake other RIFF files, such as WAV, for WebP', () {
      expect(detectListingPhotoFormat([0x52, 0x49, 0x46, 0x46, 1, 2, 3, 4, 0x57, 0x41, 0x56, 0x45]), isNull);
    });

    test('refuses truncated and empty input without throwing', () {
      expect(detectListingPhotoFormat(const []), isNull);
      expect(detectListingPhotoFormat([0xFF, 0xD8]), isNull);
      expect(detectListingPhotoFormat([0x89, 0x50, 0x4E, 0x47]), isNull);
      // A RIFF header cut off before the "WEBP" marker.
      expect(detectListingPhotoFormat([0x52, 0x49, 0x46, 0x46, 1, 2, 3, 4, 0x57]), isNull);
    });

    test('limits match the backend', () {
      expect(maxListingPhotos, 10);
      expect(maxListingPhotoBytes, 10 * 1024 * 1024);
      expect(listingMediaFolder, 'listing-media-v1');
      expect(listingMediaPolicy, 'listing-v1');
    });
  });
}
