import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:cherry_mvp/core/models/inpost_model.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/core/utils/status.dart';
import 'package:cherry_mvp/features/checkout/checkout_repository.dart';
import 'package:cherry_mvp/features/checkout/models/payment_intent.dart';
import 'package:cherry_mvp/features/checkout/checkout_view_model.dart';
import 'package:cherry_mvp/features/checkout/widgets/shipping_address_widget.dart';

@GenerateNiceMocks([MockSpec<NavigationProvider>()])
import 'checkout_view_model_test.mocks.dart';

class FakeCheckoutRepository implements ICheckoutRepository {
  FakeCheckoutRepository({this.fetchNearestResult});

  final Result? fetchNearestResult;
  Map<String, dynamic>? createdOrder;
  Result<dynamic> createOrderResult = Result.success({
    'shipment': {'id': 'shipment_123'},
  });

  @override
  Future<Result> fetchNearestInPosts(String postalCode) async {
    return fetchNearestResult ?? Result.success([]);
  }

  @override
  Future<void> storeOrderInFirestore(Map<String, dynamic> orderData) async {}

  @override
  Future<Result<PaymentIntentResponse>> createPaymentIntent(double amount) async {
    return Result.failure('Payment intent creation is not used in this test.');
  }

  @override
  Future<Result> createOrder(Map<String, dynamic> order) async {
    createdOrder = order;
    return createOrderResult;
  }

  @override
  Future<void> storeLockerInFirestore(InpostModel data) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Product _testProduct({double price = 10}) {
  return Product(
    id: 'product_123',
    name: 'Test jumper',
    description: 'A warm jumper',
    quality: 'Good',
    productImages: const [],
    donation: 0,
    price: price,
    likes: 0,
    number: 1,
    size: 'M',
  );
}

PlaceDetails _validUkAddress() {
  return PlaceDetails(
    formattedAddress: '10 Test Street, London, SW1A 1AA, United Kingdom',
    addressComponents: [
      AddressComponent(
        longName: '10',
        shortName: '10',
        types: ['street_number'],
      ),
      AddressComponent(
        longName: 'Test Street',
        shortName: 'Test Street',
        types: ['route'],
      ),
      AddressComponent(
        longName: 'London',
        shortName: 'London',
        types: ['locality'],
      ),
      AddressComponent(
        longName: 'SW1A 1AA',
        shortName: 'SW1A 1AA',
        types: ['postal_code'],
      ),
      AddressComponent(
        longName: 'United Kingdom',
        shortName: 'GB',
        types: ['country'],
      ),
    ],
  );
}

void main() {
  group('CheckoutViewModel', () {
    late CheckoutViewModel viewModel;
    late MockNavigationProvider mockNavigator;

    setUp(() {
      mockNavigator = MockNavigationProvider();
      viewModel = CheckoutViewModel(
        checkoutRepository: FakeCheckoutRepository(),
        navigator: mockNavigator,
      );
    });

    test('should initialize with empty state', () {
      expect(viewModel.hasShippingAddress, false);
      expect(viewModel.hasPaymentMethod, false);
      expect(viewModel.canCheckout, false);
      expect(viewModel.nearestInpost, isEmpty);
    });

    test('should set shipping address correctly', () {
      final testAddress = PlaceDetails(
        formattedAddress: 'Test Address',
        addressComponents: [
          AddressComponent(
            longName: '123',
            shortName: '123',
            types: ['street_number'],
          ),
          AddressComponent(
            longName: 'Main St',
            shortName: 'Main St',
            types: ['route'],
          ),
          AddressComponent(
            longName: 'Anytown',
            shortName: 'Anytown',
            types: ['locality'],
          ),
          AddressComponent(
            longName: 'NY',
            shortName: 'NY',
            types: ['administrative_area_level_1'],
          ),
          AddressComponent(
            longName: 'SW1A 1AA',
            shortName: 'SW1A 1AA',
            types: ['postal_code'],
          ),
          AddressComponent(
            longName: 'USA',
            shortName: 'US',
            types: ['country'],
          ),
        ],
      );

      viewModel.setShippingAddress(testAddress);

      expect(viewModel.hasShippingAddress, true);
      expect(viewModel.shippingAddress, testAddress);
      expect(viewModel.formattedShippingAddress, 'Test Address');
    });

    test('should validate shipping address correctly', () {
      // Test with invalid address (null)
      expect(viewModel.validateShippingAddress(), false);

      // Test with valid address
      final validAddress = PlaceDetails(
        formattedAddress: 'Valid Address',
        addressComponents: [
          AddressComponent(
            longName: '123',
            shortName: '123',
            types: ['street_number'],
          ),
          AddressComponent(
            longName: 'Main St',
            shortName: 'Main St',
            types: ['route'],
          ),
          AddressComponent(
            longName: 'Anytown',
            shortName: 'Anytown',
            types: ['locality'],
          ),
          AddressComponent(
            longName: 'SW1A 1AA',
            shortName: 'SW1A 1AA',
            types: ['postal_code'],
          ),
        ],
      );

      viewModel.setShippingAddress(validAddress);
      expect(viewModel.validateShippingAddress(), true);
    });

    test('should handle payment method correctly', () {
      expect(viewModel.hasPaymentMethod, false);

      viewModel.setPaymentMethod(true);
      expect(viewModel.hasPaymentMethod, true);

      viewModel.setPaymentMethod(false);
      expect(viewModel.hasPaymentMethod, false);
    });

    test('should determine checkout readiness correctly', () {
      expect(viewModel.canCheckout, false);

      // Set payment method only
      viewModel.setPaymentMethod(true);
      expect(viewModel.canCheckout, false);

      // Set shipping address only
      viewModel.setPaymentMethod(false);
      final testAddress = PlaceDetails(
        formattedAddress: 'Test Address',
        addressComponents: [],
      );
      viewModel.setShippingAddress(testAddress);
      expect(viewModel.canCheckout, false);

      // Set both payment method and shipping address
      viewModel.setPaymentMethod(true);
      expect(viewModel.canCheckout, true);
    });

    test('should reset checkout state correctly', () {
      final testAddress = PlaceDetails(
        formattedAddress: 'Test Address',
        addressComponents: [],
      );

      viewModel.setShippingAddress(testAddress);
      viewModel.setPaymentMethod(true);

      expect(viewModel.hasShippingAddress, true);
      expect(viewModel.hasPaymentMethod, true);

      viewModel.resetCheckout();

      expect(viewModel.hasShippingAddress, false);
      expect(viewModel.hasPaymentMethod, false);
      expect(viewModel.canCheckout, false);
    });

    test('creates home delivery order payload after payment succeeds', () async {
      final fakeRepository = FakeCheckoutRepository();
      viewModel = CheckoutViewModel(
        checkoutRepository: fakeRepository,
        navigator: mockNavigator,
      );

      viewModel.addItem(_testProduct());
      viewModel.setDeliveryChoice('home');
      viewModel.setShippingAddress(_validUkAddress());
      viewModel.setAddressConfirmed(true);

      await viewModel.createOrder(paymentIntentId: 'pi_test_123');

      final order = fakeRepository.createdOrder;
      expect(order, isNotNull);
      expect(order!['amount'], 1399);
      expect(order['paymentIntentId'], 'pi_test_123');
      expect(order['deliveryType'], 'home');
      expect(order['shippingOptionId'], 'mvp-home-delivery');
      expect(order['shippingWeight'], 500);
      expect(order['productId'], 'product_123');
      expect(order['productName'], 'Test jumper');
      expect(order['shippingOptionName'], 'MVP home delivery');
      expect(order['shippingOptionPrice'], 299);
      expect(order['shippingCarrier'], 'evri');

      final shipping = order['shipping'] as Map<String, dynamic>;
      final address = shipping['address'] as Map<String, dynamic>;
      expect(address['line1'], '10 Test Street');
      expect(address['city'], 'London');
      expect(address['postal_code'], 'SW1A 1AA');
      expect(address['country'], 'GB');
      expect(shipping['name'], isNot('John Doe'));
      expect((shipping['name'] as String).trim(), isNotEmpty);
    });

    test('creates pick-up point order payload after payment succeeds', () async {
      final fakeRepository = FakeCheckoutRepository();
      viewModel = CheckoutViewModel(
        checkoutRepository: fakeRepository,
        navigator: mockNavigator,
      );

      viewModel.addItem(_testProduct());
      viewModel.setDeliveryChoice('pickup');
      viewModel.setSelectedInpost(
        const InpostModel(
          id: 'locker_123',
          name: 'Locker One',
          address: '1 Pickup Street, London',
          postcode: 'SW1A 1AA',
          lat: '51.501',
          long: '-0.141',
        ),
      );

      await viewModel.createOrder(paymentIntentId: 'pi_pickup_123');

      final order = fakeRepository.createdOrder;
      expect(order, isNotNull);
      expect(order!['amount'], 1399);
      expect(order['paymentIntentId'], 'pi_pickup_123');
      expect(order['deliveryType'], 'pickup_point');
      expect(order['shippingOptionId'], 'mvp-pickup-point-delivery');
      expect(order['shippingWeight'], 500);
      expect(order['shippingOptionName'], 'MVP pick-up point delivery');
      expect(order['shippingOptionPrice'], 0);
      expect(order['shippingCarrier'], 'inpost');

      final shipping = order['shipping'] as Map<String, dynamic>;
      final address = shipping['address'] as Map<String, dynamic>;
      expect(address['line1'], '1 Pickup Street, London');
      expect(address['city'], 'London');
      expect(address['postal_code'], 'SW1A 1AA');
      expect(address['country'], 'GB');
      expect(shipping['name'], isNot('John Doe'));

      final pickupPoint = order['pickupPoint'] as Map<String, dynamic>;
      expect(pickupPoint['id'], 'locker_123');
      expect(pickupPoint['name'], 'Locker One');
      expect(pickupPoint['addressLine1'], '1 Pickup Street, London');
      expect(pickupPoint['city'], 'London');
      expect(pickupPoint['postalCode'], 'SW1A 1AA');
      expect(pickupPoint['country'], 'GB');
      expect(pickupPoint['carrier'], 'inpost');
    });

    test('pending shipment response records partial checkout success', () async {
      final fakeRepository = FakeCheckoutRepository()
        ..createOrderResult = Result.success({'shipmentStatus': 'pending'});
      viewModel = CheckoutViewModel(
        checkoutRepository: fakeRepository,
        navigator: mockNavigator,
      );

      viewModel.addItem(_testProduct());
      viewModel.setDeliveryChoice('home');
      viewModel.setShippingAddress(_validUkAddress());
      viewModel.setAddressConfirmed(true);

      await viewModel.createOrder(paymentIntentId: 'pi_pending_123');

      expect(viewModel.checkoutFlowState, CheckoutFlowState.shipmentPending);
      expect(viewModel.hasCompletedCheckout, true);
      expect(viewModel.createOrderStatus.type, StatusType.success);
    });

    test('should extract address components correctly', () {
      final testAddress = PlaceDetails(
        formattedAddress: 'Test Address',
        addressComponents: [
          AddressComponent(
            longName: '123',
            shortName: '123',
            types: ['street_number'],
          ),
          AddressComponent(
            longName: 'Main St',
            shortName: 'Main St',
            types: ['route'],
          ),
          AddressComponent(
            longName: 'Anytown',
            shortName: 'Anytown',
            types: ['locality'],
          ),
          AddressComponent(
            longName: 'NY',
            shortName: 'NY',
            types: ['administrative_area_level_1'],
          ),
          AddressComponent(
            longName: '12345',
            shortName: '12345',
            types: ['postal_code'],
          ),
        ],
      );

      viewModel.setShippingAddress(testAddress);

      final components = viewModel.shippingAddressComponents;
      expect(components['street'], '123 Main St');
      expect(components['city'], 'Anytown');
      expect(components['state'], 'NY');
      expect(components['postalCode'], '12345');
    });

    test(
      'should fail pickup lookup when the response cannot be parsed',
      () async {
        viewModel = CheckoutViewModel(
          checkoutRepository: FakeCheckoutRepository(fetchNearestResult: Result.success({'unexpected': 'payload'})),
          navigator: mockNavigator,
        );

        await viewModel.fetchNearestInPosts('SW1A 1AA');

        expect(viewModel.nearestInpost, isEmpty);
        expect(viewModel.showLocker, false);
        expect(viewModel.status.type, StatusType.failure);
      },
    );

    test('should populate pickup lockers from a valid response', () async {
      viewModel = CheckoutViewModel(
        checkoutRepository: FakeCheckoutRepository(
          fetchNearestResult: Result.success([
            {
              'id': 'locker-1',
              'name': 'Locker One',
              'address': '1 Test Street',
              'postcode': 'SW1A 1AA',
              'lat': '51.5010',
              'long': '-0.1416',
            },
          ]),
        ),
        navigator: mockNavigator,
      );

      await viewModel.fetchNearestInPosts('SW1A 1AA');

      expect(viewModel.status.type, StatusType.success);
      expect(viewModel.showLocker, true);
      expect(viewModel.nearestInpost, hasLength(1));
      expect(viewModel.nearestInpost.first.name, 'Locker One');
    });
  });
}
