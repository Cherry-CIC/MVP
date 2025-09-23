import 'dart:async';
import 'dart:convert';
import 'package:firebase_functions_interop/firebase_functions_interop.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Validates shipping address fields
Map<String, String>? validateAddress(Map<String, dynamic> data) {
  final requiredFields = ['name', 'street', 'city', 'postcode', 'country', 'phone'];
  final errors = <String, String>{};
  for (final field in requiredFields) {
    if (data[field] == null || (data[field] as String).trim().isEmpty) {
      errors[field] = 'Missing or empty';
    }
  }
  // Add more format validation as needed
  return errors.isEmpty ? null : errors;
}

/// POST /checkout/shipping-address
Future<void> shippingAddressHandler(ExpressHttpRequest request) async {
  final body = await utf8.decoder.bind(request.body).join();
  final data = json.decode(body) as Map<String, dynamic>;
  final errors = validateAddress(data);
  if (errors != null) {
    request.response
      ..statusCode = 400
      ..write(json.encode({'errors': errors}))
      ..close();
    return;
  }
  final sessionId = request.query['sessionId'] as String?;
  if (sessionId == null) {
    request.response
      ..statusCode = 400
      ..write(json.encode({'error': 'Missing sessionId'}))
      ..close();
    return;
  }
  final firestore = Firestore.instance;
  await firestore.collection('checkout_sessions').document(sessionId).setData({
    'shipping_address': data,
  }, merge: true);
  request.response
    ..statusCode = 200
    ..write(json.encode({'shipping_address': data}))
    ..close();
}

/// GET /checkout
Future<void> getCheckoutHandler(ExpressHttpRequest request) async {
  final sessionId = request.query['sessionId'] as String?;
  if (sessionId == null) {
    request.response
      ..statusCode = 400
      ..write(json.encode({'error': 'Missing sessionId'}))
      ..close();
    return;
  }
  final firestore = Firestore.instance;
  final doc = await firestore.collection('checkout_sessions').document(sessionId).get();
  if (!doc.exists) {
    request.response
      ..statusCode = 404
      ..write(json.encode({'error': 'Session not found'}))
      ..close();
    return;
  }
  final data = doc.data;
  request.response
    ..statusCode = 200
    ..write(json.encode(data))
    ..close();
}

/// Register the functions
void registerCheckoutApi(Functions functions) {
  functions['checkoutShippingAddress'] = functions.https.onRequest(shippingAddressHandler);
  functions['getCheckout'] = functions.https.onRequest(getCheckoutHandler);
}
