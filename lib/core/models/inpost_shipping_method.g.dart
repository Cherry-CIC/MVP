// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inpost_shipping_method.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InpostShippingMethod _$InpostShippingMethodFromJson(
  Map<String, dynamic> json,
) => InpostShippingMethod(
  id: json['id'] as String,
  name: json['name'] as String,
  deliveryType: json['deliveryType'] as String,
  deliveryMethodType: json['deliveryMethodType'] as String,
  pricePence: InpostShippingMethod._parsePricePence(json['pricePence']),
  currency: json['currency'] as String?,
  checkoutIdentifier: json['checkoutIdentifier'] as String,
);

Map<String, dynamic> _$InpostShippingMethodToJson(
  InpostShippingMethod instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'deliveryType': instance.deliveryType,
  'deliveryMethodType': instance.deliveryMethodType,
  'pricePence': instance.pricePence,
  'currency': instance.currency,
  'checkoutIdentifier': instance.checkoutIdentifier,
};
