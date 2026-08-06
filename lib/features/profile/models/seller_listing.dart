class SellerListing {
  final String id;
  final String name;
  final List<String> imageUrls;
  final double? price;

  const SellerListing({
    required this.id,
    required this.name,
    required this.imageUrls,
    required this.price,
  });

  static SellerListing? tryFromJson(dynamic value) {
    if (value is! Map) {
      return null;
    }

    final json = Map<String, dynamic>.from(value);
    final id = json['id'];
    if (id is! String || id.trim().isEmpty) {
      return null;
    }

    final rawName = json['name'] ?? json['title'];
    final rawImages = json['product_images'] ?? json['images'] ?? json['productImages'];

    return SellerListing(
      id: id.trim(),
      name: rawName is String ? rawName.trim() : '',
      imageUrls: rawImages is List
          ? rawImages
                .whereType<String>()
                .map((imageUrl) => imageUrl.trim())
                .where((imageUrl) => imageUrl.isNotEmpty)
                .toList(growable: false)
          : const [],
      price: _parsePrice(json['price']),
    );
  }

  static double? _parsePrice(dynamic value) {
    double? parsedPrice;
    if (value is num) {
      parsedPrice = value.toDouble();
    } else if (value is String) {
      parsedPrice = double.tryParse(value.trim());
    }

    if (parsedPrice == null || !parsedPrice.isFinite || parsedPrice.isNegative) {
      return null;
    }
    return parsedPrice;
  }
}
