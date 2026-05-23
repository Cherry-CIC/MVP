import 'package:json_annotation/json_annotation.dart';

part 'charity.g.dart';

@JsonSerializable()
class Charity {
  final String id;
  final String name;
  final String imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  Charity({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Charity.fromJson(Map<String, dynamic> json) => _$CharityFromJson(json);

  Map<String, dynamic> toJson() => _$CharityToJson(this);
}
