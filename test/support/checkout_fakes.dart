import 'dart:async';

import 'package:cherry_mvp/core/models/inpost.dart';
import 'package:cherry_mvp/core/models/inpost_shipping_method.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/models/user.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/checkout/checkout_repository.dart';
import 'package:cherry_mvp/features/checkout/checkout_view_model.dart';
import 'package:cherry_mvp/features/checkout/models/payment_intent.dart';
import 'package:cherry_mvp/features/checkout/payment_type.dart';
import 'package:cherry_mvp/features/donation/donation_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../checkout_view_model_test.mocks.dart';

class CheckoutFixture {
  final repository = RecordingCheckoutRepository();
  late final viewModel = CheckoutViewModel(
    donationRepository: UnusedDonationRepository(),
    checkoutRepository: repository,
    navigator: MockNavigationProvider(),
  );

  void selectValidDelivery({bool setPhone = true}) {
    viewModel.addItem(product);
    viewModel.setDeliveryChoice(DeliveryType.pickup);
    viewModel.setSelectedInpost(pickupPoint());
    viewModel.setSelectedInpostShippingMethod(shippingMethod);
    viewModel.setPaymentType(PaymentType.card);
    if (setPhone) viewModel.setMobilePhoneNumber('07700 900123');
  }

  static const product = Product(
    id: 'product-1',
    name: 'Jacket',
    description: '',
    quality: 'Good',
    productImages: [],
    donation: 10,
    price: 10,
    securityFee: 1,
    likes: 0,
    number: 1,
    size: 'M',
    postageSizeId: 'small',
  );

  static Inpost pickupPoint({String? missing, String country = 'United Kingdom'}) {
    String field(String name, String value) => name == missing ? '  ' : value;
    return Inpost(
      id: field('id', 'locker-1'),
      name: field('name', 'High Street'),
      carrier: 'inpost',
      address: field('address', '12 High Street; building: Shop'),
      postcode: field('postcode', 'SW1A 1AA'),
      city: field('city', 'London'),
      country: field('country', country),
      lat: '',
      long: '',
    );
  }

  static const shippingMethod = InpostShippingMethod(
    id: 'shipping-1',
    name: 'InPost Locker Small',
    deliveryType: 'pickup',
    deliveryMethodType: 'locker',
    pricePence: 299,
    currency: 'GBP',
    checkoutIdentifier: 'small',
  );
}

class RecordingCheckoutRepository implements ICheckoutRepository {
  final intentRequests = <Map<String, String>>[];
  final orders = <Map<String, dynamic>>[];
  Completer<Result<PaymentIntentResponse>>? pendingIntent;
  Completer<Result>? pendingOrder;
  Completer<Result<UserCredentials>>? pendingProfile;
  Result<UserCredentials> profile = Result.success(null);
  Result<PaymentIntentResponse>? intentFailure;

  static Result<PaymentIntentResponse> successfulPayment() => Result.success(
    PaymentIntentResponse(
      success: true,
      message: '',
      data: PaymentIntentData(
        paymentIntentId: 'pi_test',
        paymentIntent: 'pi_test_secret_fake',
        ephemeralKey: '',
        customer: '',
        publishableKey: 'pk_test_fake',
      ),
    ),
  );

  @override
  Future<Result<PaymentIntentResponse>> createPaymentIntent({
    required String productId,
    required String shippingMethodId,
    required String pickupPointId,
    required String country,
    required String postalCode,
  }) async {
    intentRequests.add({
      'productId': productId,
      'shippingMethodId': shippingMethodId,
      'pickupPointId': pickupPointId,
      'country': country,
      'postalCode': postalCode,
    });
    return pendingIntent != null ? pendingIntent!.future : intentFailure ?? successfulPayment();
  }

  @override
  Future<Result> createOrder(Map<String, dynamic> order) async {
    orders.add(order);
    return pendingOrder != null ? pendingOrder!.future : Result.success({});
  }

  @override
  Future<Result<UserCredentials>> fetchUserProfile() async => pendingProfile != null ? pendingProfile!.future : profile;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class UnusedDonationRepository implements IDonationRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Intercepts the real plugin boundary. No native sheet or network is used.
class FakePaymentSheet {
  static const channel = MethodChannel('flutter.stripe/payments', JSONMethodCodec());
  final calls = <String>[];
  final presented = Completer<void>();
  Completer<Map<String, dynamic>>? pendingPresentation;
  bool cancel = false;

  void install() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      if (call.method == 'presentPaymentSheet') {
        if (!presented.isCompleted) presented.complete();
        if (pendingPresentation != null) return pendingPresentation!.future;
        if (cancel) {
          return {
            'error': {'code': 'Canceled', 'localizedMessage': 'Payment cancelled', 'message': 'Payment cancelled'},
          };
        }
      }
      return <String, dynamic>{};
    });
  }

  void uninstall() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  }
}
