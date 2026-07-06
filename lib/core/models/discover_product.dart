import 'package:cherry_mvp/core/models/model.dart';

class DiscoverProduct {
  final String productImage;
  final String description;
  final int likes;
  final String charityName;
  final String charityImage;
  final List<DiscoverItem> listProducts;

  const DiscoverProduct({
    required this.charityName,
    required this.productImage,
    required this.description,
    required this.likes,
    required this.charityImage,
    required this.listProducts,
  });
}
