import 'package:json_annotation/json_annotation.dart';

part 'inpost_shipping_method.g.dart';

@JsonSerializable()
class InpostShippingMethod {
  final String id;
  final String name;
  final String deliveryType;
  final String deliveryMethodType;
  final int pricePence;
  final String? currency;
  final String checkoutIdentifier;
  const InpostShippingMethod({
    required this.id,
    required this.name,
    required this.deliveryType,
    required this.deliveryMethodType,
    required this.pricePence,
    required this.currency,
    required this.checkoutIdentifier,
  });

  factory InpostShippingMethod.fromJson(Map<String, dynamic> json) => _$InpostShippingMethodFromJson(json);

  // To JSON
  Map<String, dynamic> toJson() => _$InpostShippingMethodToJson(this);

  @override
  String toString() {
    return 'InpostShippingMethod{id: $id, name: $name, deliveryType: $deliveryType, deliveryMethodType: $deliveryMethodType, pricePence: $pricePence, currency: $currency, checkoutIdentifier: $checkoutIdentifier}';
  }
}
