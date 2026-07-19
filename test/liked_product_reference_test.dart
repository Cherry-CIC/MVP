import 'package:cherry_mvp/features/liked_items/models/liked_product_reference.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LikedProductReference', () {
    test('parses a valid liked product reference', () {
      final reference = LikedProductReference.tryParse(
        documentId: 'product-1',
        data: const {'productId': 'product-1'},
      );

      expect(reference, isNotNull);
      expect(reference!.productId, 'product-1');
    });

    test('uses the document ID while a server timestamp write is pending', () {
      final reference = LikedProductReference.tryParse(
        documentId: 'product-2',
        data: const {},
      );

      expect(reference, isNotNull);
      expect(reference!.productId, 'product-2');
      expect(reference.likedAt, isNull);
    });

    test('rejects mismatched document and product IDs', () {
      final reference = LikedProductReference.tryParse(
        documentId: 'product-3',
        data: const {'productId': 'different-product'},
      );

      expect(reference, isNull);
    });
  });
}
