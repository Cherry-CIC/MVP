// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'postage_size_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PostageSizeInfo _$PostageSizeInfoFromJson(Map<String, dynamic> json) =>
    PostageSizeInfo(
      id: json['id'] as String,
      type: json['type'] as String,
      size: $enumDecode(_$PostageSizeEnumMap, json['size']),
      description: json['description'] as String,
    );

Map<String, dynamic> _$PostageSizeInfoToJson(PostageSizeInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'size': _$PostageSizeEnumMap[instance.size]!,
      'description': instance.description,
    };

const _$PostageSizeEnumMap = {
  PostageSize.small: 'small',
  PostageSize.medium: 'medium',
  PostageSize.large: 'large',
};
