import 'package:json_annotation/json_annotation.dart';
import 'package:cherry_mvp/core/models/category.dart';
import 'package:cherry_mvp/features/charity_page/charity_model.dart';

part 'product.g.dart';

@JsonSerializable()
class Product {
  final String? userId;
  final String id;
  final String name;
  final String description;
  final String quality;
  @JsonKey(name: 'product_images')
  final List<String> productImages;
  @JsonKey(fromJson: _parseDouble)
  final double donation;
  @JsonKey(fromJson: _parseDouble)
  final double price;
  @JsonKey(fromJson: _parseInt)
  final int likes;
  @JsonKey(fromJson: _parseInt)
  final int number;
  final String size;
  final String? categoryId;
  final String? charityId;
  final String? createdAt;
  final String? updatedAt;
  final Category? category;
  final Charity? charity;

  const Product({
    required this.id,
    this.userId,
    required this.name,
    required this.description,
    required this.quality,
    required this.productImages,
    required this.donation,
    required this.price,
    required this.likes,
    required this.number,
    required this.size,
    this.categoryId,
    this.charityId,
    this.createdAt,
    this.updatedAt,
    this.category,
    this.charity,
  });

  // Computed property for charityImage
  String get charityImage => charity?.imageUrl ?? '';

  factory Product.fromJson(Map<String, dynamic> json) {
    // Handle fallback for product_images vs images
    if (json['product_images'] == null && json['images'] != null) {
      json['product_images'] = json['images'];
    }
    return _$ProductFromJson({
      ...json,
      'userId': json['userId'] ?? json['user_id'] ?? '',
    });
  }

  Map<String, dynamic> toJson() => _$ProductToJson(this);

  // Helper functions for JSON parsing
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
