// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'charity_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Charity _$CharityFromJson(Map<String, dynamic> json) => Charity(
  id: Charity._readId(json, 'id') as String,
  name: json['name'] as String,
  imageUrl: Charity._readImageUrl(json, 'imageUrl') as String,
  description: json['description'] as String?,
  website: json['website'] as String?,
  likes: json['likes'] == null ? 0 : Charity.parseLikes(json['likes']),
  createdAt: Charity.parseTimestamp(json['createdAt']),
  updatedAt: Charity.parseTimestamp(json['updatedAt']),
);

Map<String, dynamic> _$CharityToJson(Charity instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'imageUrl': instance.imageUrl,
  'description': instance.description,
  'website': instance.website,
  'likes': instance.likes,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};
