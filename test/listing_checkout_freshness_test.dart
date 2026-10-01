import 'dart:async';

import 'package:cherry_mvp/core/models/inpost.dart';
import 'package:cherry_mvp/core/models/inpost_shipping_method.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/services/network/api_endpoints.dart';
import 'package:cherry_mvp/core/services/network/api_service.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/core/utils/status.dart';
import 'package:cherry_mvp/features/checkout/checkout_repository.dart';
import 'package:cherry_mvp/features/checkout/checkout_view_model.dart';
import 'package:cherry_mvp/features/checkout/models/payment_intent.dart';
import 'package:cherry_mvp/features/checkout/payment_type.dart';
import 'package:cherry_mvp/features/donation/donation_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _CheckoutRepository implements ICheckoutRepository {
  final intents = <Map<String, dynamic>>[];

  @override
  Future<Result<PaymentIntentResponse>> createPaymentIntent({
    required String productId,
    required String shippingMethodId,
    required String pickupPointId,
    required String country,
    required String postalCode,
    int? expectedEditVersion,
  }) async {
    intents.add({
      'productId': productId,
      'shippingMethodId': shippingMethodId,
      'pickupPointId': pickupPointId,
      'country': country,
      'postalCode': postalCode,
      'expectedEditVersion': expectedEditVersion,
    });
    // Stop before native Stripe. These tests never initialise a payment sheet.
    return Result.failure('Intent creation stopped by the test repository');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError('Unexpected checkout operation');
}

class _DonationRepository implements IDonationRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError('Unexpected donation operation');
}

class _Api implements ApiService {
  final requests = <Map<String, dynamic>>[];
  String? endpoint;

  @override
  Future<Result<T>> post<T>(String endpoint, {dynamic data}) async {
    this.endpoint = endpoint;
    requests.add(Map<String, dynamic>.from(data as Map));
    return Result.failure('No live API request');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError('Unexpected API operation');
}

class _Harness {
  _Harness({bool withLoader = true}) {
    viewModel = CheckoutViewModel(
      donationRepository: _DonationRepository(),
      checkoutRepository: repository,
      navigator: NavigationProvider(),
      currentUserIdProvider: () => uid,
      loadProduct: withLoader
          ? (id) async {
              loadedIds.add(id);
              return loadResponse != null ? await loadResponse!() : Result.success(_product());
            }
          : null,
    );
  }

  final repository = _CheckoutRepository();
  final loadedIds = <String>[];
  String? uid = 'buyer-1';
  Future<Result<Product>> Function()? loadResponse;
  late final CheckoutViewModel viewModel;

  void preparePayment([Product? product]) {
    viewModel.addItem(product ?? _product());
    viewModel.setDeliveryChoice(DeliveryType.pickup);
    viewModel.setSelectedInpost(_pickup());
    viewModel.setSelectedInpostShippingMethod(_shipping());
    viewModel.setPaymentType(PaymentType.card);
  }
}

Product _product([Map<String, dynamic> changes = const {}]) => Product.fromJson({
  'id': 'listing-1',
  'userId': 'seller-1',
  'name': 'Blue cotton shirt',
  'description': 'A long-sleeved shirt in good condition.',
  'quality': 'GOOD',
  'product_images': ['https://example.com/original.jpg'],
  'donation': 10,
  'price': 10,
  'securityFee': 1,
  'likes': 2,
  'number': 1,
  'size': 'M',
  'postageSize': 'small',
  'categoryId': 'shirts',
  'charityId': 'charity-1',
  'status': 'active',
  'editVersion': 7,
  ...changes,
});

Inpost _pickup([String id = 'locker-1']) => Inpost(
  id: id,
  name: 'High Street locker',
  carrier: 'inpost',
  address: '1 High Street',
  postcode: 'SW1A 1AA',
  city: 'London',
  country: 'GB',
  lat: '51.5',
  long: '-0.1',
);

InpostShippingMethod _shipping([String id = 'shipping-1']) => InpostShippingMethod(
  id: id,
  name: 'Locker delivery',
  deliveryType: 'pickup',
  deliveryMethodType: 'inpost',
  pricePence: 250,
  currency: 'GBP',
  checkoutIdentifier: id,
);

void main() {
  group('Listing freshness before checkout', () {
    test('unchanged details pass without removing the reviewed basket item', () async {
      final harness = _Harness();
      addTearDown(harness.viewModel.dispose);
      final original = _product();
      harness.viewModel.addItem(original);

      expect(await harness.viewModel.verifyBasketDetails(), isTrue);
      expect(harness.loadedIds, ['listing-1']);
      expect(harness.viewModel.basketItems.single, same(original));
      expect(harness.repository.intents, isEmpty);
    });

    test('likes and timestamps do not require the buyer to review again', () async {
      final harness = _Harness()
        ..loadResponse = () async => Result.success(_product({'likes': 25, 'updatedAt': '2026-09-30T10:00:00Z'}));
      addTearDown(harness.viewModel.dispose);
      harness.viewModel.addItem(_product());
      expect(await harness.viewModel.verifyBasketDetails(), isTrue);
      expect(harness.viewModel.basketItems, hasLength(1));
    });

    final changes = <String, Map<String, dynamic>>{
      'title': {'name': 'Green cotton shirt'},
      'description': {'description': 'Different details'},
      'photos': {
        'product_images': ['https://example.com/replacement.jpg'],
      },
      'charity': {'charityId': 'charity-2'},
      'price': {'price': 12},
      'condition': {'quality': 'NEW'},
      'size': {'size': 'L'},
      'category': {'categoryId': 'coats'},
      'revision': {'editVersion': 8},
      'sold status': {'status': 'sold'},
      'unlisted status': {'status': 'unlisted'},
      'no remaining stock': {'number': 0},
      'ownership': {'userId': 'buyer-1'},
    };
    for (final entry in changes.entries) {
      test('${entry.key} changes clear the basket and prevent payment intent creation', () async {
        final harness = _Harness()..loadResponse = () async => Result.success(_product(entry.value));
        addTearDown(harness.viewModel.dispose);
        harness.preparePayment();

        expect(await harness.viewModel.payWithPaymentSheet(), isFalse);
        expect(harness.viewModel.basketItems, isEmpty);
        expect(harness.repository.intents, isEmpty);
        expect(harness.viewModel.createOrderStatus.type, StatusType.failure);
        expect(harness.viewModel.createOrderStatus.message, contains('review'));
      });
    }

    for (final unavailable in [
      {'status': 'sold'},
      {'number': 0},
    ]) {
      test('already unavailable details cannot pass even when unchanged: $unavailable', () async {
        final unavailableProduct = _product(unavailable);
        final harness = _Harness()..loadResponse = () async => Result.success(unavailableProduct);
        addTearDown(harness.viewModel.dispose);
        harness.preparePayment(unavailableProduct);

        expect(await harness.viewModel.payWithPaymentSheet(), isFalse);
        expect(harness.viewModel.basketItems, isEmpty);
        expect(harness.repository.intents, isEmpty);
      });
    }

    for (final throws in [false, true]) {
      test('a ${throws ? 'throwing' : 'failed'} lookup blocks payment and retains the basket for retry', () async {
        final harness = _Harness()
          ..loadResponse = () async {
            if (throws) throw StateError('Offline');
            return Result.failure('Offline');
          };
        addTearDown(harness.viewModel.dispose);
        harness.preparePayment();

        expect(await harness.viewModel.payWithPaymentSheet(), isFalse);
        expect(harness.viewModel.basketItems, hasLength(1));
        expect(harness.repository.intents, isEmpty);
        expect(harness.viewModel.createOrderStatus.type, StatusType.failure);
      });
    }

    test('a versioned listing without a wired loader fails closed', () async {
      final harness = _Harness(withLoader: false);
      addTearDown(harness.viewModel.dispose);
      harness.preparePayment();
      expect(await harness.viewModel.payWithPaymentSheet(), isFalse);
      expect(harness.repository.intents, isEmpty);
      expect(harness.viewModel.createOrderStatus.type, StatusType.failure);
    });

    test('unchanged versioned listing passes the reviewed revision to intent creation', () async {
      final harness = _Harness();
      addTearDown(harness.viewModel.dispose);
      harness.preparePayment();
      // The fake rejects the intent before any native payment method is called.
      expect(await harness.viewModel.payWithPaymentSheet(), isFalse);
      expect(harness.repository.intents.single, {
        'productId': 'listing-1',
        'shippingMethodId': 'shipping-1',
        'pickupPointId': 'locker-1',
        'country': 'GB',
        'postalCode': 'SW1A 1AA',
        'expectedEditVersion': 7,
      });
      expect(harness.viewModel.basketItems, hasLength(1));
    });

    final pendingChanges = <String, void Function(_Harness)>{
      'account swap': (harness) => harness.uid = 'buyer-2',
      'checkout reset': (harness) => harness.viewModel.resetCheckout(),
      'basket removal': (harness) => harness.viewModel.removeItem(harness.viewModel.basketItems.single),
      'pickup point': (harness) => harness.viewModel.setSelectedInpost(_pickup('locker-2')),
      'shipping method': (harness) => harness.viewModel.setSelectedInpostShippingMethod(_shipping('shipping-2')),
      'payment method': (harness) => harness.viewModel.setPaymentType(PaymentType.apple),
      'delivery type': (harness) => harness.viewModel.setDeliveryChoice(DeliveryType.home),
    };
    for (final entry in pendingChanges.entries) {
      test('${entry.key} change during lookup cancels payment without leaving a loading state', () async {
        final response = Completer<Result<Product>>();
        final harness = _Harness()..loadResponse = () => response.future;
        addTearDown(harness.viewModel.dispose);
        harness.preparePayment();
        final payment = harness.viewModel.payWithPaymentSheet();
        expect(harness.viewModel.createOrderStatus.type, StatusType.loading);
        expect(harness.loadedIds, ['listing-1']);

        entry.value(harness);
        response.complete(Result.success(_product()));

        expect(await payment, isFalse);
        expect(harness.repository.intents, isEmpty);
        expect(harness.viewModel.createOrderStatus.type, isNot(StatusType.loading));
      });
    }
  });

  group('CheckoutRepository reviewed version contract', () {
    for (final version in <int?>[7, 0, null]) {
      test('payment intent body ${version == null ? 'omits a missing' : 'includes the $version'} revision', () async {
        final api = _Api();
        final repository = CheckoutRepository(api);
        await repository.createPaymentIntent(
          productId: 'listing-1',
          shippingMethodId: 'shipping-1',
          pickupPointId: 'locker-1',
          country: 'GB',
          postalCode: 'SW1A 1AA',
          expectedEditVersion: version,
        );
        expect(api.endpoint, ApiEndpoints.paymentIntent);
        expect(api.requests.single, {
          'productId': 'listing-1',
          'shippingMethodId': 'shipping-1',
          'pickupPointId': 'locker-1',
          'country': 'GB',
          'postalCode': 'SW1A 1AA',
          'expectedEditVersion': ?version,
        });
      });
    }
  });
}
