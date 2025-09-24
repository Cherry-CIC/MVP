// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Product _$ProductFromJson(Map<String, dynamic> json) => Product(
  id: json['id'] as String,
  userId: json['userId'] as String?,
  name: json['name'] as String,
  description: json['description'] as String,
  quality: json['quality'] as String,
  productImages: (json['product_images'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  donation: Product._parseDouble(json['donation']),
  price: Product._parseDouble(json['price']),
  likes: Product._parseInt(json['likes']),
  number: Product._parseInt(json['number']),
  size: json['size'] as String,
  categoryId: json['categoryId'] as String?,
  charityId: json['charityId'] as String?,
  createdAt: json['createdAt'] as String?,
  updatedAt: json['updatedAt'] as String?,
  category: json['category'] == null
      ? null
      : Category.fromJson(json['category'] as Map<String, dynamic>),
  charity: json['charity'] == null
      ? null
      : Charity.fromJson(json['charity'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ProductToJson(Product instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'name': instance.name,
  'description': instance.description,
  'quality': instance.quality,
  'product_images': instance.productImages,
  'donation': instance.donation,
  'price': instance.price,
  'likes': instance.likes,
  'number': instance.number,
  'size': instance.size,
  'categoryId': instance.categoryId,
  'charityId': instance.charityId,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
  'category': instance.category,
  'charity': instance.charity,
};
