import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cherry_mvp/core/config/firestore_constants.dart';

class LikedProductReference {
  const LikedProductReference({
    required this.productId,
    required this.likedAt,
  });

  final String productId;
  final DateTime? likedAt;

  static LikedProductReference? tryParse({
    required String documentId,
    required Map<String, dynamic> data,
  }) {
    final storedProductId = data[FirestoreConstants.productId];
    final productId = storedProductId is String && storedProductId.trim().isNotEmpty
        ? storedProductId.trim()
        : documentId.trim();

    if (productId.isEmpty) {
      return null;
    }

    final normalisedDocumentId = documentId.trim();
    if (normalisedDocumentId.isNotEmpty && productId != normalisedDocumentId) {
      return null;
    }

    return LikedProductReference(
      productId: productId,
      likedAt: _parseLikedAt(data[FirestoreConstants.likedAt]),
    );
  }

  static DateTime? _parseLikedAt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }
}
