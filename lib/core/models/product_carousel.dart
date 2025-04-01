class ProductCarousel {
  final String image;
  final String charityLogo;
  final int numberLikes;
  final double? price;
  final int? numberIndexes;
  final String? description;
  final String? size;

  const ProductCarousel(
      {required this.image, required this.charityLogo, required this.numberLikes, this.price, this.numberIndexes, this.description, this.size});
}
