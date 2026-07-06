// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'charity_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Charity _$CharityFromJson(Map<String, dynamic> json) => Charity(
  id: json['id'] as String,
  name: json['name'] as String,
  imageUrl: json['imageUrl'] as String,
  description: json['description'] as String?,
  website: json['website'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$CharityToJson(Charity instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'imageUrl': instance.imageUrl,
  'description': instance.description,
  'website': instance.website,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};
