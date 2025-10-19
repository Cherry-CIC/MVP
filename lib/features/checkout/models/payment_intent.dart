import 'package:json_annotation/json_annotation.dart';

part 'payment_intent.g.dart';

@JsonSerializable()
class PaymentIntentResponse {
  final bool success;
  final String message;
  final PaymentIntentData data;

  PaymentIntentResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory PaymentIntentResponse.fromJson(Map<String, dynamic> json) =>
      _$PaymentIntentResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentIntentResponseToJson(this);

  String get paymentIntent => data.paymentIntent;
  String get ephemeralKey => data.ephemeralKey;
  String get customer => data.customer;
  String get publishableKey => data.publishableKey;
}

@JsonSerializable()
class PaymentIntentData {
  final String paymentIntent;
  final String ephemeralKey;
  final String customer;
  final String publishableKey;

  PaymentIntentData({
    required this.paymentIntent,
    required this.ephemeralKey,
    required this.customer,
    required this.publishableKey,
  });

  factory PaymentIntentData.fromJson(Map<String, dynamic> json) =>
      _$PaymentIntentDataFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentIntentDataToJson(this);
}
