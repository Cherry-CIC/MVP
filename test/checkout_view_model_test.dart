import 'package:cherry_mvp/core/models/inpost_model.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/core/utils/status.dart';
import 'package:cherry_mvp/features/checkout/checkout_repository.dart';
import 'package:cherry_mvp/features/checkout/checkout_view_model.dart';
import 'package:cherry_mvp/features/checkout/widgets/shipping_address_widget.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeCheckoutRepository implements ICheckoutRepository {
  Map<String, dynamic>? createdOrder;
  Result<dynamic> createOrderResult = Result.success({
    'shipment': {'id': 'shipment_123'},
  });

  @override
  Future<void> storeOrderInFirestore(Map<String, dynamic> orderData) async {}

  @override
  Future<Result> createOrder(Map<String, dynamic> order) async {
    createdOrder = order;
    return createOrderResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Product _testProduct({double price = 10}) {
  return Product(
    id: 'product_1',
    name: 'Blue jacket',
    description: 'Warm jacket',
    quality: 'Good',
    productImages: const [],
    donation: price,
    price: price,
    likes: 0,
    number: 1,
    size: 'M',
  );
}

void main() {
  group('CheckoutViewModel', () {
    late CheckoutViewModel viewModel;
    late FakeCheckoutRepository repository;

    setUp(() {
      repository = FakeCheckoutRepository();
      viewModel = CheckoutViewModel(checkoutRepository: repository);
    });

    test('should initialize with empty state', () {
      expect(viewModel.hasShippingAddress, false);
      expect(viewModel.hasPaymentMethod, false);
      expect(viewModel.canCheckout, false);
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
            longName: 'BS1 6PL',
            shortName: 'BS1 6PL',
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
            longName: 'BS1 6PL',
            shortName: 'BS1 6PL',
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

    test('createOrder sends backend payload for home delivery', () async {
      viewModel.addItem(_testProduct());
      viewModel.setDeliveryChoice('home');
      viewModel.setShippingAddress(
        PlaceDetails.fromManualEntry(
          addressLine1: '12 Cherry Lane',
          addressLine2: 'Flat 2',
          city: 'Bristol',
          postcode: 'BS1 6PL',
          country: 'United Kingdom',
        ),
      );
      viewModel.setAddressConfirmed(true);

      await viewModel.createOrder(paymentIntentId: 'pi_123');

      final payload = repository.createdOrder!;
      expect(payload['amount'], 1399);
      expect(payload['paymentIntentId'], 'pi_123');
      expect(payload['deliveryType'], 'home');
      expect(payload['shippingOptionId'], isNotEmpty);
      expect(payload['shippingWeight'], 500);
      expect(payload['productId'], 'product_1');
      expect(payload['productName'], 'Blue jacket');
      expect(payload['shippingOptionPrice'], 299);
      expect(payload['shippingCarrier'], isNotEmpty);

      final shipping = payload['shipping'] as Map<String, dynamic>;
      expect(shipping['name'], isNot('John Doe'));

      final address = shipping['address'] as Map<String, dynamic>;
      expect(address['line1'], '12 Cherry Lane');
      expect(address['city'], 'Bristol');
      expect(address['postal_code'], 'BS1 6PL');
      expect(address['country'], 'GB');
      expect(viewModel.checkoutFlowState, CheckoutFlowState.shipmentCreated);
    });

    test('createOrder sends backend payload for pickup delivery', () async {
      viewModel.addItem(_testProduct());
      viewModel.setDeliveryChoice('pickup');
      viewModel.setSelectedInpost(
        const InpostModel(
          id: 'locker_1',
          name: 'Aldi Locker - Temple Gate',
          address: 'Temple Gate, Bristol',
          postcode: 'BS1 6PL',
          lat: '51.4490',
          long: '-2.5830',
        ),
      );

      await viewModel.createOrder(paymentIntentId: 'pi_456');

      final payload = repository.createdOrder!;
      expect(payload['paymentIntentId'], 'pi_456');
      expect(payload['deliveryType'], 'pickup_point');
      expect(payload['shippingOptionId'], isNotEmpty);
      expect(payload['shippingWeight'], 500);

      final shipping = payload['shipping'] as Map<String, dynamic>;
      final address = shipping['address'] as Map<String, dynamic>;
      expect(address['line1'], 'Temple Gate');
      expect(address['city'], 'Bristol');
      expect(address['postal_code'], 'BS1 6PL');
      expect(address['country'], 'GB');

      final pickupPoint = payload['pickupPoint'] as Map<String, dynamic>;
      expect(pickupPoint['id'], 'locker_1');
      expect(pickupPoint['name'], 'Aldi Locker - Temple Gate');
      expect(pickupPoint['addressLine1'], 'Temple Gate');
      expect(pickupPoint['city'], 'Bristol');
      expect(pickupPoint['postalCode'], 'BS1 6PL');
      expect(pickupPoint['country'], 'GB');
      expect(pickupPoint['carrier'], isNotEmpty);
    });

    test(
      'createOrder treats shipmentStatus pending as partial success',
      () async {
        repository.createOrderResult = Result.success({
          'shipmentStatus': 'pending',
        });
        viewModel.addItem(_testProduct());
        viewModel.setDeliveryChoice('pickup');
        viewModel.setSelectedInpost(
          const InpostModel(
            id: 'locker_1',
            name: 'Aldi Locker - Temple Gate',
            address: 'Temple Gate, Bristol',
            postcode: 'BS1 6PL',
            lat: '51.4490',
            long: '-2.5830',
          ),
        );

        await viewModel.createOrder(paymentIntentId: 'pi_789');

        expect(viewModel.checkoutFlowState, CheckoutFlowState.shipmentPending);
        expect(viewModel.createOrderStatus.type, StatusType.success);
      },
    );
  });
}
