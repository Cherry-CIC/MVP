class Product {
  final int? id;
  final String name;
  final String quality;
  final String imagePath; // Local file path
  final double price;
  final String charity;
  final int likes;
  final int number;

  Product({
    this.id,
    required this.name,
    required this.quality,
    required this.imagePath,
    required this.price,
    required this.charity,
    required this.likes,
    required this.number,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'quality': quality,
        'imagePath': imagePath,
        'price': price,
        'charity': charity,
        'likes': likes,
        'number': number,
      };

  factory Product.fromMap(Map<String, dynamic> map) => Product(
        id: map['id'],
        name: map['name'],
        quality: map['quality'],
        imagePath: map['imagePath'],
        price: map['price'],
        charity: map['charity'],
        likes: map['likes'],
        number: map['number'],
      );
}
