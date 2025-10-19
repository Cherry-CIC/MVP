// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_intent.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentIntentResponse _$PaymentIntentResponseFromJson(
  Map<String, dynamic> json,
) => PaymentIntentResponse(
  success: json['success'] as bool,
  message: json['message'] as String,
  data: PaymentIntentData.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PaymentIntentResponseToJson(
  PaymentIntentResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
};

PaymentIntentData _$PaymentIntentDataFromJson(Map<String, dynamic> json) =>
    PaymentIntentData(
      paymentIntent: json['paymentIntent'] as String,
      ephemeralKey: json['ephemeralKey'] as String,
      customer: json['customer'] as String,
      publishableKey: json['publishableKey'] as String,
    );

Map<String, dynamic> _$PaymentIntentDataToJson(PaymentIntentData instance) =>
    <String, dynamic>{
      'paymentIntent': instance.paymentIntent,
      'ephemeralKey': instance.ephemeralKey,
      'customer': instance.customer,
      'publishableKey': instance.publishableKey,
    };
