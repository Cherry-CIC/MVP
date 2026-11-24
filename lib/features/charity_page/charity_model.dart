import 'package:json_annotation/json_annotation.dart';
import 'package:cherry_mvp/core/config/config.dart';

part 'charity_model.g.dart';

@JsonSerializable()
class Charity {
  @JsonKey(readValue: _readId)
  final String id;
  final String name;
  @JsonKey(readValue: _readImageUrl)
  final String imageUrl;
  final String? description;
  final String? website;
  @JsonKey(fromJson: parseLikes)
  final int likes;
  @JsonKey(fromJson: parseTimestamp)
  final DateTime createdAt;
  @JsonKey(fromJson: parseTimestamp)
  final DateTime updatedAt;

  const Charity({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.description,
    this.website,
    this.likes = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  static Object? _readId(Map<dynamic, dynamic> json, String key) =>
      json['id'] ?? json['_id'];

  static Object? _readImageUrl(Map<dynamic, dynamic> json, String key) =>
      json['imageUrl'] ?? json['image_url'] ?? '';

  Charity copyWith({
    String? id,
    String? name,
    String? imageUrl,
    String? description,
    String? website,
    int? likes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Charity(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      website: website ?? this.website,
      likes: likes ?? this.likes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static int parseLikes(dynamic value) {
    final parsed = switch (value) {
      int() => value,
      num() => value.toInt(),
      String() => int.tryParse(value),
      _ => null,
    };
    return parsed != null && parsed >= 0 ? parsed : 0;
  }

  static DateTime parseTimestamp(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    if (value is Map && value['_seconds'] is num) {
      final seconds = (value['_seconds'] as num).toInt();
      return DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
    }
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  // Use generated methods
  factory Charity.fromJson(Map<String, dynamic> json) => _$CharityFromJson(json);

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
