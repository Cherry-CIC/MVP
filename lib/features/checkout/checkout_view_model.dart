import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:logging/logging.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/router/nav_routes.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/features/checkout/checkout_repository.dart';
import 'package:cherry_mvp/features/checkout/constants/address_constants.dart';
import 'package:cherry_mvp/features/checkout/models/payment_intent.dart';
import 'package:cherry_mvp/features/checkout/models/pickup_point.dart';
import 'package:cherry_mvp/features/checkout/payment_type.dart';
import 'package:cherry_mvp/features/checkout/widgets/shipping_address_widget.dart';

/// ViewModel for managing checkout state including basket items, shipping address, and payment method
class CheckoutViewModel extends ChangeNotifier {
  static const String pickupPointDeliveryChoice = 'pickup_point';
  static const String homeDeliveryChoice = 'home';

  final ICheckoutRepository checkoutRepository;
  final NavigationProvider navigator;
  final _log = Logger('CheckoutViewModel');

  CheckoutViewModel({required this.checkoutRepository, required this.navigator});

  Status _status = Status.uninitialized;

  Status get status => _status;

  Status _createOrderStatus = Status.uninitialized;
  Status get createOrderStatus => _createOrderStatus;

  final List<Product> _basketItems = [];

  final List<PickupPoint> _pickupPoints = [];
  List<PickupPoint> get pickupPoints => List.unmodifiable(_pickupPoints);

  PickupPoint? selectedPickupPoint;

  String? deliveryChoice;

  void setDeliveryChoice(String val) {
    if (val != pickupPointDeliveryChoice) {
      selectedPickupPoint = null;
      _pickupPoints.clear();
    }
    deliveryChoice = val;
    notifyListeners();
  }

  bool get isPickupPointDelivery => deliveryChoice == pickupPointDeliveryChoice;

  void setSelectedPickupPoint(PickupPoint? data) {
    selectedPickupPoint = data;
    notifyListeners();
  }

  void clearSelectedPickupPoint() {
    selectedPickupPoint = null;
    notifyListeners();
  }

  /// Unmodifiable list of items in the basket
  List<Product> get basketItems => List.unmodifiable(_basketItems);

  /// Total price of all items in the basket
  double get itemTotal => _basketItems.fold(0, (sum, item) => sum + item.price);

  /// Security fee calculated as 10% of item total
  double get securityFee => itemTotal * 0.1;

  /// Fixed postage fee
  double get postage => 2.99;

  /// Total order amount including all fees
  double get total => itemTotal + securityFee + postage;

  // Shipping Address properties
  PlaceDetails? _shippingAddress;

  /// Currently selected shipping address
  PlaceDetails? get shippingAddress => _shippingAddress;

  /// Whether a valid shipping address has been selected
  bool get hasShippingAddress => _shippingAddress != null;

  //Whether user or logic has confirmed the shipping address
  bool isShippingAddressConfirmed = false;

  // Payment properties
  bool _hasPaymentMethod = false;
  String? _lastPaymentIntentId;

  String? get lastPaymentIntentId => _lastPaymentIntentId;

  /// Whether a payment method has been set
  bool get hasPaymentMethod => selectedPaymentType != null || _hasPaymentMethod;

  bool get hasValidDeliverySelection {
    if ((deliveryChoice ?? '').isEmpty) return false;
    if (isPickupPointDelivery) return selectedPickupPoint != null;
    return deliveryChoice == homeDeliveryChoice && isShippingAddressConfirmed && hasShippingAddress;
  }

  /// Whether the order is ready for checkout.
  bool get canCheckout => hasValidDeliverySelection && hasPaymentMethod;

  void setAddressConfirmed(bool value) {
    isShippingAddressConfirmed = value;
    notifyListeners();
  }

  // Existing basket methods
  void addItem(Product product) {
    _basketItems.add(product);
    notifyListeners();
  }

  void removeItem(Product product) {
    _basketItems.remove(product);
    notifyListeners();
  }

  void clearBasket() {
    _basketItems.clear();
    notifyListeners();
  }

  // Shipping address methods

  /// Sets the shipping address from Google Places API result
  /// Notifies listeners when address is updated
  void setShippingAddress(PlaceDetails address) {
    _shippingAddress = address;
    _pickupPoints.clear();
    selectedPickupPoint = null;
    notifyListeners();
  }

  /// Clears the currently selected shipping address
  void clearShippingAddress() {
    _shippingAddress = null;
    _pickupPoints.clear();
    selectedPickupPoint = null;
    notifyListeners();
  }

  PaymentType? selectedPaymentType;
  // Payment method methods
  void setPaymentType(PaymentType type) {
    selectedPaymentType = type;
    _hasPaymentMethod = true;
    notifyListeners();
  }

  PaymentType? getPaymentType() {
    return selectedPaymentType;
  }

  /// Sets whether a payment method has been configured
  void setPaymentMethod(bool hasPayment) {
    _hasPaymentMethod = hasPayment;
    if (!hasPayment) {
      selectedPaymentType = null;
    }
    notifyListeners();
  }

  /// Clears any selected payment method.
  void clearPaymentMethod() {
    selectedPaymentType = null;
    _hasPaymentMethod = false;
    notifyListeners();
  }

  /// Returns the formatted shipping address for display purposes
  String get formattedShippingAddress {
    return _shippingAddress?.formattedAddress ?? "2, Court yard";
  }

  /// Returns shipping address components as a map for backend processing
  /// Keys are standardized using AddressConstants
  Map<String, String> get shippingAddressComponents {
    if (_shippingAddress == null) return {};

    return {
      AddressConstants.streetKey: '${_shippingAddress!.streetNumber} ${_shippingAddress!.route}'.trim(),
      AddressConstants.cityKey: _shippingAddress!.locality,
      AddressConstants.stateKey: _shippingAddress!.administrativeAreaLevel1,
      AddressConstants.postalCodeKey: _shippingAddress!.postalCode,
      AddressConstants.countryKey: _shippingAddress!.country,
    };
  }

  String get pickupPointSearchCountry {
    final address = _shippingAddress;
    if (address == null) return 'GB';

    for (final component in address.addressComponents) {
      if (component.types.contains(AddressConstants.countryType)) {
        final country = component.shortName.isNotEmpty ? component.shortName : component.longName;
        return _normaliseCountryCode(country);
      }
    }

    return _normaliseCountryCode(address.country);
  }

  String _normaliseCountryCode(String country) {
    final value = country.trim();
    if (value.isEmpty) return 'GB';
    final upperValue = value.toUpperCase();
    if (upperValue == 'UNITED KINGDOM' || upperValue == 'UK' || upperValue == 'GREAT BRITAIN') {
      return 'GB';
    }
    if (upperValue.length == 2) return upperValue;
    return value;
  }

  /// Resets checkout state for a new order
  /// Clears shipping address and payment method but preserves basket items
  void resetCheckout() {
    _shippingAddress = null;
    selectedPaymentType = null;
    _hasPaymentMethod = false;
    isShippingAddressConfirmed = false;
    selectedPickupPoint = null;
    _pickupPoints.clear();
    _lastPaymentIntentId = null;
    _basketItems.clear();
    deliveryChoice = null;
    _createOrderStatus = Status.uninitialized;
    notifyListeners();
  }

  /// Validates that the shipping address has all required components
  /// Returns true if address is valid for checkout
  bool validateShippingAddress() {
    if (_shippingAddress == null) return false;

    final components = shippingAddressComponents;

    // Check required fields are present and non-empty
    final street = components[AddressConstants.streetKey]?.trim() ?? '';
    final city = components[AddressConstants.cityKey]?.trim() ?? '';
    final postalCode = components[AddressConstants.postalCodeKey]?.trim() ?? '';

    // Basic validation - could be enhanced with format validation
    return street.isNotEmpty && city.isNotEmpty && postalCode.isNotEmpty && _isValidPostalCode(postalCode);
  }

  /// Helper method to validate postal code format (UK postcode validation)
  bool _isValidPostalCode(String postalCode) {
    // UK postcode pattern: 1-2 letters, 1-2 digits, optional letter/digit, space, digit, 2 letters
    final RegExp postcodePattern = RegExp(
      r'^[A-Z]{1,2}[0-9][A-Z0-9]? ?[0-9][A-Z]{2}$',
      caseSensitive: false,
    );
    return postcodePattern.hasMatch(postalCode.trim());
  }

  /// Processes the checkout order
  /// Returns true if successful, false if validation fails or error occurs
  Future<bool> processCheckout() async {
    if (!canCheckout) return false;
    if (!validateShippingAddress()) return false;

    try {
      // Prepare order data for API call
      final Map<String, dynamic> orderData = {
        'delivery_method': deliveryChoice,
        'items': basketItems
            .map(
              (item) => {
                'id': item.id,
                'name': item.name,
                'price': item.price,
                // Add other product fields as needed
              },
            )
            .toList(),
        'shipping_address': {
          'formatted_address': formattedShippingAddress,
          AddressConstants.streetKey: shippingAddressComponents[AddressConstants.streetKey],
          AddressConstants.cityKey: shippingAddressComponents[AddressConstants.cityKey],
          AddressConstants.stateKey: shippingAddressComponents[AddressConstants.stateKey],
          'postal_code': shippingAddressComponents[AddressConstants.postalCodeKey],
          AddressConstants.countryKey: shippingAddressComponents[AddressConstants.countryKey],
          'latitude': _shippingAddress?.latitude,
          'longitude': _shippingAddress?.longitude,
        },
        'totals': {
          'item_total': itemTotal,
          'security_fee': securityFee,
          'postage': postage,
          'total': total,
        },
        if (selectedPickupPoint != null) 'pickupPoint': selectedPickupPoint!.toJson(),
      };

      // Validate order data structure
      if (orderData['items'] == null || (orderData['items'] as List).isEmpty) {
        return false;
      }

      // Call the repository to create the order via API
      final result = await checkoutRepository.createOrder(orderData);

      if (result.isSuccess) {
        _log.info('Checkout processed successfully');
        return true;
      } else {
        _log.warning('Checkout failed: ${result.error}');
        return false;
      }
    } catch (e) {
      // Log error for debugging purposes
      _log.severe('Checkout error: $e');
      debugPrint('${AddressConstants.checkoutError}: $e');
      return false;
    }
  }

  Future<void> fetchPickupPointsForShippingAddress({
    int radius = AddressConstants.pickupPointSearchRadiusMeters,
  }) async {
    final postcode = shippingAddressComponents[AddressConstants.postalCodeKey]?.trim() ?? '';
    if (postcode.isEmpty) {
      _pickupPoints.clear();
      selectedPickupPoint = null;
      _status = Status.failure(AppStrings.checkoutAddressRequired);
      notifyListeners();
      return;
    }

    await fetchPickupPoints(
      country: pickupPointSearchCountry,
      address: postcode,
      radius: radius,
    );
  }

  Future<void> fetchPickupPoints({
    required String country,
    required String address,
    int radius = AddressConstants.pickupPointSearchRadiusMeters,
  }) async {
    _status = Status.loading;
    selectedPickupPoint = null;
    notifyListeners();

    try {
      final result = await checkoutRepository.fetchPickupPoints(
        country: country,
        address: address,
        radius: radius,
      );
      final parsedPickupPoints = result.isSuccess && result.value != null
          ? _parsePickupPointList(result.value)
          : const <PickupPoint>[];

      _pickupPoints
        ..clear()
        ..addAll(parsedPickupPoints);

      if (parsedPickupPoints.isNotEmpty) {
        _status = Status.success;
      } else {
        _status = Status.failure(
          result.isSuccess
              ? 'Pickup points currently unavailable, please try again later'
              : (result.error ?? 'Pickup points currently unavailable, please try again later'),
        );
        _log.warning(
          result.isSuccess
              ? 'Fetch pickup points returned an empty or invalid payload for address $address'
              : 'Fetch pickup points failed: ${result.error}',
        );
      }
    } catch (e) {
      _pickupPoints.clear();
      _status = Status.failure(e.toString());
      _log.severe('Fetch pickup points error:: $e');
    }

    notifyListeners();
  }

  /// Store a dummy order in Firestore
  Future<void> storeOrderInFirestore() async {
    final Map<String, dynamic> orderData = {
      'delivery_method': deliveryChoice,
      'items': _basketItems
          .map(
            (item) => {
              'id': item.id,
              'name': item.name,
              'price': item.price,
              'image': item.productImages.isNotEmpty ? item.productImages.first : null,
            },
          )
          .toList(),
      'shipping_address': {
        'formatted_address': formattedShippingAddress,
        ...shippingAddressComponents,
        'latitude': _shippingAddress?.latitude,
        'longitude': _shippingAddress?.longitude,
      },
      'totals': {
        'item_total': itemTotal,
        'security_fee': securityFee,
        'postage': postage,
        'total': total,
      },
      if (selectedPickupPoint != null) 'pickupPoint': selectedPickupPoint!.toJson(),
      'created_at': DateTime.now().toIso8601String(),
    };
    try {
      await checkoutRepository.storeOrderInFirestore(orderData);
    } catch (e) {
      _log.severe('Error storing order to firestore:: $e');
      rethrow;
    }
  }

  Future<bool> payWithPaymentSheet({required double amount}) async {
    if (selectedPaymentType == null) {
      _createOrderStatus = Status.failure(
        AppStrings.checkoutPaymentMethodRequired,
      );
      notifyListeners();
      return false;
    }

    _createOrderStatus = Status.loading;
    _lastPaymentIntentId = null;
    notifyListeners();

    try {
      // To create a PaymentIntent and return the client_secret
      final response = await checkoutRepository.createPaymentIntent(amount);

      if (response.isSuccess && response.value != null) {
        final paymentResponse = response.value!;

        Stripe.publishableKey = paymentResponse.publishableKey;
        await Stripe.instance.applySettings();

        final setupParams = _buildPaymentSheetParameters(
          paymentResponse,
          selectedPaymentType!,
        );

        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: setupParams,
        );

        // Present the native PaymentSheet (it will show ApplePay/GooglePay if available)
        await Stripe.instance.presentPaymentSheet();
        _lastPaymentIntentId = paymentResponse.paymentIntentId;
        return true;
      } else {
        _createOrderStatus = Status.failure(response.error.toString());
        _lastPaymentIntentId = null;
        _log.severe('Create Payment intent Error :: ${response.error}');
        notifyListeners();
        return false;
      }
    } on StripeException catch (e) {
      _createOrderStatus = Status.failure(
        e.error.localizedMessage ?? e.toString(),
      );
      _log.severe(
        'Stripe Payment Error :: ${e.error.localizedMessage ?? e.toString()}',
      );
      _lastPaymentIntentId = null;
      notifyListeners();
      return false;
    } catch (e) {
      _createOrderStatus = Status.failure(e.toString());
      _log.severe('Error making payment::: $e');
      _lastPaymentIntentId = null;
      notifyListeners();
      return false;
    }
  }

  Future<void> createOrder() async {
    _createOrderStatus = Status.loading;
    notifyListeners();

    if (basketItems.isEmpty) {
      _createOrderStatus = Status.failure('Your basket is empty');
      notifyListeners();
      return;
    }

    final paymentIntentId = _lastPaymentIntentId?.trim() ?? '';
    if (paymentIntentId.isEmpty) {
      _createOrderStatus = Status.failure(AppStrings.checkoutPaymentIntentRequired);
      notifyListeners();
      return;
    }

    if ((deliveryChoice ?? '').isEmpty) {
      _createOrderStatus = Status.failure(AppStrings.checkoutDeliveryOptionRequired);
      notifyListeners();
      return;
    }

    if (isPickupPointDelivery && selectedPickupPoint == null) {
      _createOrderStatus = Status.failure(AppStrings.checkoutPickupLockerRequired);
      notifyListeners();
      return;
    }

    final pickupPoint = selectedPickupPoint;
    final Map<String, dynamic> address = isPickupPointDelivery && pickupPoint != null
        ? {
            "line1": pickupPoint.addressLine1,
            "city": pickupPoint.city,
            "state": "",
            "postal_code": pickupPoint.postalCode,
            "country": _normaliseCountryCode(pickupPoint.country),
          }
        : {
            'line1': _shippingAddress?.line1 ?? '',
            "city": shippingAddressComponents[AddressConstants.cityKey] ?? "",
            "state": shippingAddressComponents[AddressConstants.stateKey] ?? "",
            'postal_code': shippingAddressComponents[AddressConstants.postalCodeKey] ?? "",
            "country": _normaliseCountryCode(
              shippingAddressComponents[AddressConstants.countryKey] ?? AppStrings.unitedKingdomText,
            ),
          };

    final Map<String, dynamic> orderData = {
      "amount": _toMinorUnits(total),
      "productId": basketItems[0].id,
      "productName": basketItems[0].name,
      "paymentIntentId": paymentIntentId,
      "deliveryMethod": deliveryChoice,
      "shipping": {"address": address, "name": 'Customer'},
      if (pickupPoint != null) "pickupPoint": pickupPoint.toJson(),
    };
    try {
      final result = await checkoutRepository.createOrder(orderData);
      if (result.isSuccess) {
        _createOrderStatus = Status.success;
      } else {
        _createOrderStatus = Status.failure(result.error ?? "");
        _log.warning('Create order failed! ${result.error}');
      }
    } catch (e) {
      _createOrderStatus = Status.failure(e.toString());
      _log.severe('Create order failed! ${e.toString()}');
    }
    notifyListeners();
  }

  int _toMinorUnits(double amount) {
    return (amount * 100).round();
  }

  SetupPaymentSheetParameters _buildPaymentSheetParameters(
    PaymentIntentResponse paymentResponse,
    PaymentType paymentType,
  ) {
    final customerId = paymentResponse.customer.trim();
    final ephemeralKey = paymentResponse.ephemeralKey.trim();
    final hasCustomerContext = customerId.isNotEmpty && ephemeralKey.isNotEmpty;

    final googlePay = paymentType == PaymentType.google
        ? const PaymentSheetGooglePay(merchantCountryCode: "GB", testEnv: true)
        : null;
    final applePay = paymentType == PaymentType.apple ? const PaymentSheetApplePay(merchantCountryCode: "GB") : null;

    if (hasCustomerContext) {
      return SetupPaymentSheetParameters(
        paymentIntentClientSecret: paymentResponse.paymentIntent,
        customerId: customerId,
        customerEphemeralKeySecret: ephemeralKey,
        merchantDisplayName: "cherry",
        googlePay: googlePay,
        applePay: applePay,
      );
    }

    return SetupPaymentSheetParameters(
      paymentIntentClientSecret: paymentResponse.paymentIntent,
      merchantDisplayName: "cherry",
      googlePay: googlePay,
      applePay: applePay,
    );
  }

  void resetCreateOrderStatus() {
    _createOrderStatus = Status.uninitialized;
    notifyListeners();
  }

  List<PickupPoint> _parsePickupPointList(dynamic payload) {
    dynamic listData = payload;
    if (payload is Map<String, dynamic>) {
      final data = payload['data'] ?? payload;
      listData = data is Map<String, dynamic> ? (data['pickupPoints'] ?? data['items'] ?? data['lockers']) : data;
    }

    if (listData is! List) return [];

    final pickupPoints = <PickupPoint>[];
    for (final item in listData) {
      if (item is! Map) continue;
      final pickupPoint = PickupPoint.fromJson(Map<String, dynamic>.from(item));
      if (pickupPoint.isValid) {
        pickupPoints.add(pickupPoint);
      }
    }
    return pickupPoints;
  }

  Future<void> goToHome() async {
    await navigator.navigateToAndRemoveUntil(AppRoutes.home, (Route<dynamic> route) => false);
  }

  Future<void> gotoCheckoutComplete() async {
    await Future.delayed(const Duration(seconds: 1));
    await navigator.replaceWith(AppRoutes.checkoutComplete);
  }

  Future<void> showPurchaseSecurity() async {
    await navigator.showPurchaseSecurity();
  }
}
