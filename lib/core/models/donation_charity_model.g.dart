// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'donation_charity_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CharityCategories _$CharityCategoriesFromJson(Map<String, dynamic> json) =>
    CharityCategories(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$CharityCategoriesToJson(CharityCategories instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'imageUrl': instance.imageUrl,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
