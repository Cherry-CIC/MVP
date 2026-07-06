import 'package:json_annotation/json_annotation.dart';

part 'category.g.dart';

@JsonSerializable()
class Category {
  final String id;
  final String name;
  final String imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Category({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  // From JSON
  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);

  // To JSON
  Map<String, dynamic> toJson() => _$CategoryToJson(this);
}
