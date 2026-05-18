import 'package:json_annotation/json_annotation.dart';

part 'inpost_shipping_method.g.dart';

@JsonSerializable()
class InpostShippingMethod {
  final String id;
  final String name;
  final String deliveryType;
  final String deliveryMethodType;
  @JsonKey(fromJson: _parseDouble)
  final double price;
  final String? currency;
  final String? carrierCode;
  final String? carrierName;
  final String checkoutIdentifier;
  const InpostShippingMethod({
    required this.id,
    required this.name,
    required this.deliveryType,
    required this.deliveryMethodType,
    required this.price,
    required this.currency,
    required this.carrierCode,
    required this.carrierName,
    required this.checkoutIdentifier,
  });

  factory InpostShippingMethod.fromJson(Map<String, dynamic> json) => _$InpostShippingMethodFromJson(json);

  // To JSON
  Map<String, dynamic> toJson() => _$InpostShippingMethodToJson(this);

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  String toString() {
    return 'InpostShippingMethod{id: $id, name: $name, deliveryType: $deliveryType, deliveryMethodType: $deliveryMethodType, price: $price, currency: $currency, carrierCode: $carrierCode, carrierName: $carrierName, checkoutIdentifier: $checkoutIdentifier}';
  }
}
