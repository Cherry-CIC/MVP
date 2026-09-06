import 'package:json_annotation/json_annotation.dart';

part 'inpost_shipping_method.g.dart';

@JsonSerializable()
class InpostShippingMethod {
  final String id;
  final String name;
  final String deliveryType;
  final String deliveryMethodType;
  @JsonKey(fromJson: _parsePricePence)
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

  static int _parsePricePence(dynamic value) {
    if (value is int) return value;
    if (value is double && value == value.truncateToDouble()) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw FormatException('Invalid pricePence value: $value');
  }

  @override
  String toString() {
    return 'InpostShippingMethod(redacted)';
  }
}
