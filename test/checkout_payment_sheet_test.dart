import 'package:cherry_mvp/core/models/inpost.dart';
import 'package:cherry_mvp/core/models/inpost_shipping_method.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/core/utils/status.dart';
import 'package:cherry_mvp/features/checkout/checkout_repository.dart';
import 'package:cherry_mvp/features/checkout/checkout_view_model.dart';
import 'package:cherry_mvp/features/checkout/models/payment_intent.dart';
import 'package:cherry_mvp/features/checkout/payment_type.dart';
import 'package:cherry_mvp/features/donation/donation_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_test/flutter_test.dart';

// Exercise the real Dart Stripe settings and serialisation at the native
// boundary. No native payment UI, network requests or charges are performed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter.stripe/payments', JSONMethodCodec());
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;
  late List<String> logs;
  late DebugPrintCallback previousDebugPrint;
  late _CheckoutRepository repository;
  late CheckoutViewModel viewModel;
  String? failingMethod;
  String? failureCode;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    calls = [];
    logs = [];
    previousDebugPrint = debugPrint;
    debugPrint = (message, {wrapWidth}) {
      if (message != null) logs.add(message);
    };
    failingMethod = null;
    failureCode = null;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == failingMethod) {
        return {
          'error': {
            'code': failureCode,
            'message': 'Native payment details must not reach the customer',
          },
        };
      }
      return <String, dynamic>{};
    });
    // Each attempt must configure its own key and merchant, including after
    // an earlier SDK initialisation without Apple Pay.
    Stripe.publishableKey = 'pk_test_before_checkout';
    Stripe.merchantIdentifier = null;
    repository = _CheckoutRepository();
    viewModel = _readyCheckout(repository);
  });

  tearDown(() {
    viewModel.dispose();
    messenger.setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
    debugPrint = previousDebugPrint;
  });

  test(
    'configures the Apple merchant before initialising and presenting the sheet',
    () async {
      expect(await viewModel.payWithPaymentSheet(), isTrue);

      expect(calls.map((call) => call.method), [
        'initialise',
        'initPaymentSheet',
        'presentPaymentSheet',
      ]);
      expect(
        calls.first.arguments['merchantIdentifier'],
        'merchant.uk.org.cherry',
      );
      expect(calls.first.arguments['publishableKey'], 'pk_test_checkout');
      final params = calls[1].arguments['params'] as Map;
      expect(params['applePay']['merchantCountryCode'], 'GB');
      expect(params['googlePay'], isNull);
      expect(params['merchantDisplayName'], 'cherry');
      expect(params['paymentIntentClientSecret'], 'pi_checkout_secret_test');
      expect(params['customerId'], 'cus_checkout');
      expect(params['customerEphemeralKeySecret'], 'ek_test_checkout');
      expect(repository.paymentRequests, 1);
    },
  );

  test(
    'keeps card checkout available without Apple Pay configuration in its sheet',
    () async {
      viewModel.setPaymentType(PaymentType.card);

      expect(await viewModel.payWithPaymentSheet(), isTrue);

      final params = calls.singleWhere((call) => call.method == 'initPaymentSheet').arguments['params'] as Map;
      expect(params['applePay'], isNull);
      expect(params['googlePay'], isNull);
      expect(calls.last.method, 'presentPaymentSheet');
    },
  );

  test(
    'preserves the backend IDs for order confirmation after payment succeeds',
    () async {
      expect(await viewModel.payWithPaymentSheet(), isTrue);
      expect(viewModel.lastPaymentIntentId, 'pi_checkout');
      expect(viewModel.lastOrderId, 'order_checkout');

      await viewModel.createOrder();

      expect(repository.confirmedOrders, [
        {'orderId': 'order_checkout', 'paymentIntentId': 'pi_checkout'},
      ]);
      expect(viewModel.createOrderStatus.type, StatusType.success);
    },
  );

  test(
    'cancellation returns to checkout without a failure or stale payment IDs',
    () async {
      expect(await viewModel.payWithPaymentSheet(), isTrue);
      failingMethod = 'presentPaymentSheet';
      failureCode = 'Canceled';

      expect(await viewModel.payWithPaymentSheet(), isFalse);

      expect(viewModel.createOrderStatus.type, StatusType.canceled);
      expect(viewModel.createOrderStatus.message, isEmpty);
      expect(viewModel.lastPaymentIntentId, isNull);
      expect(viewModel.lastOrderId, isNull);
      expect(repository.confirmedOrders, isEmpty);
      expect(viewModel.basketItems, hasLength(1));
      expect(viewModel.selectedPaymentType, PaymentType.apple);
      expect(logs, isEmpty);
    },
  );

  test('an initialisation failure never presents the payment sheet', () async {
    failingMethod = 'initPaymentSheet';
    failureCode = 'Failed';

    expect(await viewModel.payWithPaymentSheet(), isFalse);

    expect(calls.map((call) => call.method), [
      'initialise',
      'initPaymentSheet',
    ]);
    expect(viewModel.createOrderStatus.type, StatusType.failure);
    expect(
      viewModel.createOrderStatus.message,
      'Payment could not be completed. Please try again.',
    );
    expect(viewModel.lastPaymentIntentId, isNull);
    expect(viewModel.lastOrderId, isNull);
    expect(repository.confirmedOrders, isEmpty);
    expect(logs, [
      'SEVERE event=checkout_payment_failed stage=initialisation code=failed',
    ]);
  });

  test(
    'a failed payment clears IDs from an earlier successful attempt',
    () async {
      expect(await viewModel.payWithPaymentSheet(), isTrue);
      failingMethod = 'presentPaymentSheet';
      failureCode = 'Failed';

      expect(await viewModel.payWithPaymentSheet(), isFalse);

      expect(viewModel.createOrderStatus.type, StatusType.failure);
      expect(viewModel.lastPaymentIntentId, isNull);
      expect(viewModel.lastOrderId, isNull);
      expect(repository.confirmedOrders, isEmpty);
      expect(logs, [
        'SEVERE event=checkout_payment_failed stage=presentation code=failed',
      ]);
    },
  );

  test('a backend failure never initialises or presents Stripe', () async {
    repository.failPaymentPreparation = true;

    expect(await viewModel.payWithPaymentSheet(), isFalse);

    expect(calls, isEmpty);
    expect(viewModel.createOrderStatus.type, StatusType.failure);
    expect(viewModel.lastPaymentIntentId, isNull);
    expect(viewModel.lastOrderId, isNull);
    expect(repository.confirmedOrders, isEmpty);
    expect(logs, [
      'SEVERE event=checkout_payment_failed stage=preparation code=backendRejected',
    ]);
  });

  test('a timed-out payment logs only its stage and approved failure code', () async {
    failingMethod = 'presentPaymentSheet';
    failureCode = 'Timeout';

    expect(await viewModel.payWithPaymentSheet(), isFalse);

    expect(viewModel.createOrderStatus.type, StatusType.failure);
    expect(viewModel.lastPaymentIntentId, isNull);
    expect(viewModel.lastOrderId, isNull);
    expect(logs, [
      'SEVERE event=checkout_payment_failed stage=presentation code=timeout',
    ]);
  });
}

class _CheckoutRepository implements ICheckoutRepository {
  int paymentRequests = 0;
  bool failPaymentPreparation = false;
  final List<Map<String, dynamic>> confirmedOrders = [];

  @override
  Future<Result<PaymentIntentResponse>> createPaymentIntent({
    required String productId,
    required String shippingMethodId,
    required String pickupPointId,
    required String country,
    required String postalCode,
    required Map<String, dynamic> shipping,
    required Map<String, dynamic> pickupPoint,
  }) async {
    paymentRequests++;
    if (failPaymentPreparation) {
      return Result.failure('Payment preparation failed');
    }
    return Result.success(
      PaymentIntentResponse(
        success: true,
        message: 'Created',
        data: PaymentIntentData(
          orderId: 'order_checkout',
          paymentIntentId: 'pi_checkout',
          paymentIntent: 'pi_checkout_secret_test',
          ephemeralKey: 'ek_test_checkout',
          customer: 'cus_checkout',
          publishableKey: 'pk_test_checkout',
        ),
      ),
    );
  }

  @override
  Future<Result> createOrder(Map<String, dynamic> order) async {
    confirmedOrders.add(Map.of(order));
    return Result.success(<String, dynamic>{});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DonationRepository implements IDonationRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

CheckoutViewModel _readyCheckout(_CheckoutRepository repository) {
  return CheckoutViewModel(
      checkoutRepository: repository,
      donationRepository: _DonationRepository(),
      navigator: NavigationProvider(),
      currentUserIdProvider: () => 'buyer',
    )
    ..addItem(
      Product(
        id: 'product',
        userId: 'seller',
        name: 'Jumper',
        description: 'Blue jumper',
        quality: 'Good',
        productImages: const [],
        donation: 20,
        price: 20,
        securityFee: 2,
        likes: 0,
        number: 1,
        size: 'M',
        postageSizeId: 'small',
      ),
    )
    ..setPaymentType(PaymentType.apple)
    ..setDeliveryChoice(DeliveryType.pickup)
    ..setRecipientName('Test Buyer')
    ..setMobilePhoneNumber('+447700900000')
    ..setSelectedInpost(
      const Inpost(
        id: 'locker',
        name: 'Test Locker',
        carrier: 'inpost_gb',
        address: '10 High Street',
        postcode: 'SW1A 1AA',
        city: 'London',
        country: 'GB',
        lat: '51.5',
        long: '0.1',
      ),
    )
    ..setSelectedInpostShippingMethod(
      const InpostShippingMethod(
        id: 'shipping',
        name: 'Small',
        deliveryType: 'pickup',
        deliveryMethodType: 'locker',
        pricePence: 257,
        currency: 'GBP',
        checkoutIdentifier: 'small',
      ),
    );
}
