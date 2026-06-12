// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'donation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DonationRequest _$DonationRequestFromJson(Map<String, dynamic> json) =>
    DonationRequest(
      name: json['name'] as String,
      description: json['description'] as String,
      categoryId: json['categoryId'] as String,
      charityId: json['charityId'] as String,
      quality: json['quality'] as String,
      size: json['size'] as String,
      postageSizeId: json['postageSizeId'] as String,
      donation: (json['donation'] as num).toDouble(),
      price: (json['price'] as num).toDouble(),
      productImages: (json['product_images'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      number: (json['number'] as num?)?.toInt() ?? 10,
    );

Map<String, dynamic> _$DonationRequestToJson(DonationRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'categoryId': instance.categoryId,
      'charityId': instance.charityId,
      'quality': instance.quality,
      'size': instance.size,
      'postageSizeId': instance.postageSizeId,
      'product_images': instance.productImages,
      'donation': instance.donation,
      'price': instance.price,
      'likes': instance.likes,
      'number': instance.number,
    };

DonationResponse _$DonationResponseFromJson(Map<String, dynamic> json) =>
    DonationResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: Product.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$DonationResponseToJson(DonationResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };
