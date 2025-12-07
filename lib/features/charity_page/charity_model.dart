import 'package:cherry_mvp/core/models/donation_charity_model.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:cherry_mvp/core/config/config.dart';

part 'charity_model.g.dart';

@JsonSerializable()
class Charity {
  final String id;
  final String name;
  final String imageUrl;
  final String? description;
  final String? website;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Charity({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.description,
    this.website,
    required this.createdAt,
    required this.updatedAt,
  });

  // Use generated methods
  factory Charity.fromJson(Map<String, dynamic> json) =>
      _$CharityFromJson(json);

  Map<String, dynamic> toJson() => _$CharityToJson(this);
}

// Dummy data for testing
final dummyCharities = [
  Charity(
    id: "1",
    name: "Home-Start",
    imageUrl: AppImages.homeStart,
    createdAt: DateTime.parse("2024-01-01T00:00:00.000Z"),
    updatedAt: DateTime.parse("2024-01-01T00:00:00.000Z"),
  ),
  Charity(
    id: "2",
    name: "MIND",
    imageUrl: AppImages.mind,
    createdAt: DateTime.parse("2024-01-01T00:00:00.000Z"),
    updatedAt: DateTime.parse("2024-01-01T00:00:00.000Z"),
  ),
  Charity(
    id: "3",
    name: "Shelter",
    imageUrl: AppImages.shelter,
    createdAt: DateTime.parse("2024-01-01T00:00:00.000Z"),
    updatedAt: DateTime.parse("2024-01-01T00:00:00.000Z"),
  ),
  Charity(
    id: "4",
    name: "WWF",
    imageUrl: AppImages.wwf,
    createdAt: DateTime.parse("2024-01-01T00:00:00.000Z"),
    updatedAt: DateTime.parse("2024-01-01T00:00:00.000Z"),
  ),
];