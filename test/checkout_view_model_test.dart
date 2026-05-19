import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/core/utils/status.dart';
import 'package:cherry_mvp/features/checkout/checkout_repository.dart';
import 'package:cherry_mvp/features/checkout/checkout_view_model.dart';
import 'package:cherry_mvp/features/checkout/models/pickup_point.dart';
import 'package:cherry_mvp/features/checkout/widgets/shipping_address_widget.dart';

class FakeCheckoutRepository implements ICheckoutRepository {
  FakeCheckoutRepository({this.fetchPickupPointsResult});

  final Result? fetchPickupPointsResult;
  String? lastCountry;
  String? lastAddress;
  int? lastRadius;

  @override
  Future<Result> fetchNearestInPosts(String postalCode) async {
    return Result.success([]);
  }

  @override
  Future<Result> fetchPickupPoints({
    required String country,
    required String address,
    int radius = 5000,
  }) async {
    lastCountry = country;
    lastAddress = address;
    lastRadius = radius;
    return fetchPickupPointsResult ??
        Result.success({
          'data': {'pickupPoints': []},
        });
  }

  @override
  Future<void> storeOrderInFirestore(Map<String, dynamic> orderData) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeNavigationProvider extends NavigationProvider {
  @override
  Future<dynamic> navigateTo(String routeName, {Object? arguments}) async {}

  @override
  Future<dynamic> replaceWith(String routeName, {Object? arguments}) async {}

  @override
  Future<dynamic> navigateToAndRemoveUntil(
    String routeName,
    RoutePredicate predicate, {
    Object? arguments,
  }) async {}

  @override
  void goBack([Object? arguments]) {}

  @override
  Future<void> showPurchaseSecurity() async {}
}

void main() {
  group('CheckoutViewModel', () {
    late CheckoutViewModel viewModel;
    late FakeNavigationProvider fakeNavigator;

    setUp(() {
      fakeNavigator = FakeNavigationProvider();
      viewModel = CheckoutViewModel(
        checkoutRepository: FakeCheckoutRepository(),
        navigator: fakeNavigator,
      );
    });

    test('should initialize with empty state', () {
      expect(viewModel.hasShippingAddress, false);
      expect(viewModel.hasPaymentMethod, false);
      expect(viewModel.canCheckout, false);
      expect(viewModel.pickupPoints, isEmpty);
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

      // Set both payment method and shipping address without a delivery choice
      viewModel.setPaymentMethod(true);
      expect(viewModel.canCheckout, false);

      viewModel.setDeliveryChoice(CheckoutViewModel.homeDeliveryChoice);
      viewModel.setAddressConfirmed(true);
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

    test(
      'should fail pickup lookup when the response cannot be parsed',
      () async {
        viewModel = CheckoutViewModel(
          checkoutRepository: FakeCheckoutRepository(
            fetchPickupPointsResult: Result.success({'unexpected': 'payload'}),
          ),
          navigator: fakeNavigator,
        );

        await viewModel.fetchPickupPoints(country: 'GB', address: 'SW1A 1AA');

        expect(viewModel.pickupPoints, isEmpty);
        expect(viewModel.status.type, StatusType.failure);
      },
    );

    test('should populate pickup points from the documented response shape', () async {
      viewModel = CheckoutViewModel(
        checkoutRepository: FakeCheckoutRepository(
          fetchPickupPointsResult: Result.success({
            'success': true,
            'message': 'Pickup points retrieved successfully',
            'data': {
              'pickupPoints': [
                {
                  'id': 'pickup-1',
                  'name': 'Pickup Point One',
                  'addressLine1': '1 Test Street',
                  'city': 'London',
                  'postalCode': 'SW1A 1AA',
                  'country': 'GB',
                  'carrier': 'inpost_gb',
                  'distanceMeters': 250,
                  'latitude': '51.5010',
                  'longitude': '-0.1416',
                  'openTomorrow': true,
                  'openUpcomingWeek': true,
                },
              ],
            },
          }),
        ),
        navigator: fakeNavigator,
      );

      await viewModel.fetchPickupPoints(country: 'GB', address: 'SW1A 1AA');

      expect(viewModel.status.type, StatusType.success);
      expect(viewModel.pickupPoints, hasLength(1));
      expect(viewModel.pickupPoints.first.name, 'Pickup Point One');
      expect(viewModel.pickupPoints.first.displayAddress, '1 Test Street, London, SW1A 1AA');
    });

    test('should request pickup points with country, postcode and default radius from the shipping address', () async {
      final repository = FakeCheckoutRepository(
        fetchPickupPointsResult: Result.success({
          'data': {'pickupPoints': []},
        }),
      );
      viewModel = CheckoutViewModel(
        checkoutRepository: repository,
        navigator: fakeNavigator,
      );

      viewModel.setShippingAddress(
        PlaceDetails(
          formattedAddress: '12 Bond Street, London, SW1A 1AA',
          addressComponents: [
            AddressComponent(
              longName: 'Bond Street',
              shortName: 'Bond Street',
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
        ),
      );

      await viewModel.fetchPickupPointsForShippingAddress();

      expect(repository.lastCountry, 'GB');
      expect(repository.lastAddress, 'SW1A 1AA');
      expect(repository.lastRadius, 5000);
    });

    test('should clear selected pickup point when delivery changes away from pickup point', () {
      const pickupPoint = PickupPoint(
        id: 'pickup-1',
        name: 'Pickup Point One',
        addressLine1: '1 Test Street',
        city: 'London',
        postalCode: 'SW1A 1AA',
        country: 'GB',
        carrier: 'inpost_gb',
      );

      viewModel.setDeliveryChoice(CheckoutViewModel.pickupPointDeliveryChoice);
      viewModel.setSelectedPickupPoint(pickupPoint);

      expect(viewModel.selectedPickupPoint, pickupPoint);

      viewModel.setDeliveryChoice(CheckoutViewModel.homeDeliveryChoice);

      expect(viewModel.selectedPickupPoint, isNull);
    });
  });
}
