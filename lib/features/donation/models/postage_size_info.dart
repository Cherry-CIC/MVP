import 'package:json_annotation/json_annotation.dart';

part 'postage_size_info.g.dart';

enum PostageSize {
  small('Small'),
  medium('Medium'),
  large('Large');

  final String label;
  const PostageSize(this.label);
}

@JsonSerializable()
class PostageSizeInfo {
  final String id;
  final String type;
  final PostageSize size;
  final String description;
  final int weight;

  PostageSizeInfo({
    required this.id,
    required this.type,
    required this.size,
    required this.description,
    required this.weight,
  });

  factory PostageSizeInfo.fromJson(Map<String, dynamic> json) => _$PostageSizeInfoFromJson(json);

  Map<String, dynamic> toJson() => _$PostageSizeInfoToJson(this);
}
