import 'package:cherry_mvp/features/checkout/checkout_repository.dart';
import 'package:cherry_mvp/features/checkout/checkout_view_model.dart';
import 'package:cherry_mvp/features/checkout/widgets/shipping_address_widget.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeCheckoutRepository implements ICheckoutRepository {
  @override
  Future<void> storeOrderInFirestore(Map<String, dynamic> orderData) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('CheckoutViewModel', () {
    late CheckoutViewModel viewModel;

    setUp(() {
      viewModel =
          CheckoutViewModel(checkoutRepository: FakeCheckoutRepository());
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
            longName: '12345',
            shortName: '12345',
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
            longName: '12345',
            shortName: '12345',
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
  });
}
