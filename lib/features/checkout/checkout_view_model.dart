import 'package:cherry_mvp/core/models/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:logging/logging.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/models/inpost.dart';
import 'package:cherry_mvp/core/models/inpost_shipping_method.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/router/nav_routes.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/features/checkout/checkout_repository.dart';
import 'package:cherry_mvp/features/checkout/constants/address_constants.dart';
import 'package:cherry_mvp/features/checkout/models/payment_intent.dart';
import 'package:cherry_mvp/features/checkout/payment_type.dart';
import 'package:cherry_mvp/features/checkout/widgets/shipping_address_widget.dart';

enum DeliveryType { pickup, home, undefined }

/// ViewModel for managing checkout state including basket items, shipping address, and payment method
class CheckoutViewModel extends ChangeNotifier {
  final ICheckoutRepository checkoutRepository;
  final NavigationProvider navigator;
  final _log = Logger('CheckoutViewModel');

  CheckoutViewModel({required this.checkoutRepository, required this.navigator});

  Status _status = Status.uninitialized;

  Status get status => _status;

  Status _createOrderStatus = Status.uninitialized;
  Status get createOrderStatus => _createOrderStatus;

  final List<Product> _basketItems = [];

  final List<InpostSearchResult> _nearestInposts = [];
  List<InpostSearchResult> get nearestInposts => _nearestInposts;

  final List<InpostShippingMethod> _inpostShippingMethods = [];
  List<InpostShippingMethod> get inpostShippingMethods => _inpostShippingMethods;

  Inpost? _selectedInpost;
  Inpost? get selectedInpost => _selectedInpost;

  String _mobilePhoneNumber = '';
  String get mobilePhoneNumber => _mobilePhoneNumber;

  void setMobilePhoneNumber(String value) {
    _mobilePhoneNumber = value;
    notifyListeners();
  }

  InpostShippingMethod? _selectedInpostShippingMethod;
  InpostShippingMethod? get selectedInpostShippingMethod => _selectedInpostShippingMethod;
  bool _showLocker = false;
  bool get showLocker => _showLocker;

  DeliveryType _deliveryChoice = DeliveryType.undefined;
  DeliveryType get deliveryChoice => _deliveryChoice;
  void setDeliveryChoice(DeliveryType val) {
    _deliveryChoice = val;
    notifyListeners();
  }

  void setShowLocker(bool val) {
    _showLocker = val;
    notifyListeners();
  }

  void setSelectedInpost(Inpost? data) {
    _selectedInpost = data;
    notifyListeners();
  }

  void setSelectedInpostShippingMethod(InpostShippingMethod? method) {
    _selectedInpostShippingMethod = method;
    notifyListeners();
  }

  /// Unmodifiable list of items in the basket
  List<Product> get basketItems => List.unmodifiable(_basketItems);

  /// Total price of all items in the basket
  double get itemTotal => _basketItems.fold(0, (sum, item) => sum + item.price);

  /// Security fee retrieved from product from backend
  double get securityFee => _basketItems.fold(0, (sum, item) => sum + (item.securityFee ?? 0));

  /// postage fee
  double get postage => _selectedInpostShippingMethod?.price ?? 0.00;

  /// Total order amount including all fees
  double get total => itemTotal + securityFee + postage;

  /// TOTAL order amount without security fee (see https://github.com/Cherry-CIC/MVP/issues/423)
  double get totalWithoutSecurityFee => itemTotal + postage;

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
  bool get hasPaymentMethod => _selectedPaymentType != null || _hasPaymentMethod;

  /// Whether the order is ready for checkout (has both address and payment method)
  bool get canCheckout => hasShippingAddress && hasPaymentMethod;

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
    notifyListeners();
  }

  /// Clears the currently selected shipping address
  void clearShippingAddress() {
    _shippingAddress = null;
    notifyListeners();
  }

  PaymentType? _selectedPaymentType;

  PaymentType? get selectedPaymentType => _selectedPaymentType;
  // Payment method methods
  void setPaymentType(PaymentType type) {
    _selectedPaymentType = type;
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
      _selectedPaymentType = null;
    }
    notifyListeners();
  }

  /// Clears any selected payment method.
  void clearPaymentMethod() {
    _selectedPaymentType = null;
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

  /// Resets checkout state for a new order
  /// Clears shipping address and payment method but preserves basket items
  void resetCheckout() {
    _shippingAddress = null;
    _selectedPaymentType = null;
    _hasPaymentMethod = false;
    isShippingAddressConfirmed = false;
    _selectedInpost = null;
    _selectedInpostShippingMethod = null;
    _lastPaymentIntentId = null;
    _basketItems.clear();
    _deliveryChoice = DeliveryType.undefined;
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

  // TODO this seems extraneous and incorrect. the same behaviour occurs in createOrder() below. Commenting out for the moment.
  // /// Processes the checkout order
  // /// Returns true if successful, false if validation fails or error occurs
  // Future<bool> processCheckout() async {
  //   if (!canCheckout) return false;
  //   if (!validateShippingAddress()) return false;
  //
  //   try {
  //     // Prepare order data for API call
  //     final Map<String, dynamic> orderData = {
  //       'items': basketItems
  //           .map(
  //             (item) => {
  //               'id': item.id,
  //               'name': item.name,
  //               'price': item.price,
  //               // Add other product fields as needed
  //             },
  //           )
  //           .toList(),
  //       'shipping_address': {
  //         'formatted_address': formattedShippingAddress,
  //         AddressConstants.streetKey: shippingAddressComponents[AddressConstants.streetKey],
  //         AddressConstants.cityKey: shippingAddressComponents[AddressConstants.cityKey],
  //         AddressConstants.stateKey: shippingAddressComponents[AddressConstants.stateKey],
  //         'postal_code': shippingAddressComponents[AddressConstants.postalCodeKey],
  //         AddressConstants.countryKey: shippingAddressComponents[AddressConstants.countryKey],
  //         'latitude': _shippingAddress?.latitude,
  //         'longitude': _shippingAddress?.longitude,
  //       },
  //       'totals': {
  //         'item_total': itemTotal,
  //         'security_fee': securityFee,
  //         'postage': postage,
  //         'total': total,
  //       },
  //     };
  //
  //     // Validate order data structure
  //     if (orderData['items'] == null || (orderData['items'] as List).isEmpty) {
  //       return false;
  //     }
  //
  //     // Call the repository to create the order via API
  //     final result = await checkoutRepository.createOrder(orderData);
  //
  //     if (result.isSuccess) {
  //       _log.info('Checkout processed successfully');
  //       return true;
  //     } else {
  //       _log.warning('Checkout failed: ${result.error}');
  //       return false;
  //     }
  //   } catch (e) {
  //     // Log error for debugging purposes
  //     _log.severe('Checkout error: $e');
  //     debugPrint('${AddressConstants.checkoutError}: $e');
  //     return false;
  //   }
  // }

  Future<void> onConfirmLocation(String postalCode, String country) async {
    await fetchNearestInposts(postalCode, country);
    navigator.goBack();
  }

  // fetch nearest InPost locker for pickup
  Future<void> fetchNearestInposts(String postalCode, String country) async {
    _status = Status.loading;
    notifyListeners();

    try {
      final result = await checkoutRepository.fetchNearestInposts(postalCode, country);
      final parsedInposts = result.isSuccess && result.value != null
          ? _parseInpostList(result.value)
          : const <InpostSearchResult>[];

      _nearestInposts
        ..clear()
        ..addAll(parsedInposts);

      if (parsedInposts.isNotEmpty) {
        _showLocker = true;
        _status = Status.success;
      } else {
        _showLocker = false;
        _status = Status.failure(
          result.isSuccess
              ? 'Pickup points currently unavailable, please try again later'
              : (result.error ?? 'Pickup points currently unavailable, please try again later'),
        );
        _log.warning(
          result.isSuccess
              ? 'Fetch nearest inPost locker returned an empty or invalid '
                    'payload for postcode $postalCode'
              : 'Fetch nearest inPost locker failed: ${result.error}',
        );
      }
    } catch (e) {
      _showLocker = false;
      _nearestInposts.clear();
      _status = Status.failure(e.toString());
      _log.severe('Fetch nearest inPost locker error:: $e');
    }

    notifyListeners();
  }

  Future<void> fetchShippingMethodsForInpost(String servicePointId, String postalCode, String country) async {
    _status = Status.loading;
    notifyListeners();

    try {
      final result = await checkoutRepository.fetchShippingMethodsForInpost(servicePointId, postalCode, country);

      final parsedShippingMethods = result.isSuccess && result.value != null
          ? _parseShippingMethodList(result.value)
          : const <InpostShippingMethod>[];

      _inpostShippingMethods
        ..clear()
        ..addAll(parsedShippingMethods);

      if (parsedShippingMethods.isNotEmpty) {
        _status = Status.success;
      } else {
        _status = Status.failure(
          result.isSuccess
              ? 'InPost shipping methods currently unavailable, please try again later'
              : (result.error ?? 'InPost shipping methods currently unavailable, please try again later'),
        );
        _log.warning(
          result.isSuccess
              ? 'Fetch inPost shipping methods returned an empty or invalid payload for service point $servicePointId'
              : 'Fetch inPost shipping methods failed: ${result.error}',
        );
      }
    } catch (e) {
      _inpostShippingMethods.clear();
      _status = Status.failure(e.toString());
      _log.severe('Fetch inPost shipping methods error:: $e');
    }

    notifyListeners();
  }

  Future<void> storeLockerInFirestore() async {
    try {
      await checkoutRepository.storeLockerInFirestore(selectedInpost!);
    } catch (e) {
      _log.severe('Error storing locker to firestore:: $e');
    }
  }

  Future<Result> fetchUserLocker() async {
    final result = await checkoutRepository.fetchUserLocker();
    if (result.isSuccess) {
      final doc = result.value;
      if (doc != null && doc.exists && doc.data() is Map<String, dynamic>) {
        final data = doc.data() as Map<String, dynamic>;
        final id = (data[FirestoreConstants.id] ?? '').toString();
        final name = (data[FirestoreConstants.name] ?? '').toString();
        final carrier = (data[FirestoreConstants.carrier] ?? '').toString();
        final address = (data[FirestoreConstants.address] ?? '').toString();
        final postcode = (data[FirestoreConstants.postcode] ?? '').toString();
        final city = (data[FirestoreConstants.city] ?? '').toString();
        final country = (data[FirestoreConstants.country] ?? '').toString();
        final lat = (data[FirestoreConstants.lat] ?? '').toString();
        final long = (data[FirestoreConstants.long] ?? '').toString();

        if (id.isNotEmpty && name.isNotEmpty && address.isNotEmpty && postcode.isNotEmpty) {
          _selectedInpost = Inpost(
            id: id,
            name: name,
            carrier: carrier,
            address: address,
            postcode: postcode,
            city: city,
            country: country,
            lat: lat,
            long: long,
          );
          _showLocker = true;
          _status = Status.success;
        } else {
          _showLocker = false;
          _selectedInpost = null;
        }
      } else {
        _showLocker = false;
        _selectedInpost = null;
      }
      notifyListeners();
      return Result.success(null);
    } else {
      _status = Status.failure(result.error?.toString() ?? 'Unknown error');
      notifyListeners();
      return Result.failure(result.error);
    }
  }

  /// Store a dummy order in Firestore
  Future<void> storeOrderInFirestore() async {
    final Map<String, dynamic> orderData = {
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
      'created_at': DateTime.now().toIso8601String(),
    };
    try {
      await checkoutRepository.storeOrderInFirestore(orderData);
    } catch (e) {
      _log.severe('Error storing order to firestore:: $e');
      rethrow;
    }
  }

  Future<bool> payWithPaymentSheet({required double amountMinusSecurityFee}) async {
    if (_selectedPaymentType == null) {
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
      final response = await checkoutRepository.createPaymentIntent(amountMinusSecurityFee);

      if (response.isSuccess && response.value != null) {
        final paymentResponse = response.value!;

        Stripe.publishableKey = paymentResponse.publishableKey;
        await Stripe.instance.applySettings();

        final setupParams = _buildPaymentSheetParameters(
          paymentResponse,
          _selectedPaymentType!,
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
      _createOrderStatus = Status.failure('Payment intent is missing');
      notifyListeners();
      return;
    }

    if (_deliveryChoice == DeliveryType.undefined) {
      _createOrderStatus = Status.failure(AppStrings.checkoutDeliveryOptionRequired);
      notifyListeners();
      return;
    }

    if (_deliveryChoice == DeliveryType.pickup && selectedInpost == null) {
      _createOrderStatus = Status.failure(AppStrings.checkoutPickupLockerRequired);
      notifyListeners();
      return;
    }

    if (_deliveryChoice == DeliveryType.pickup && !_hasCompletePickupPoint(selectedInpost!)) {
      _createOrderStatus = Status.failure(AppStrings.checkoutPickupDetailsIncomplete);
      notifyListeners();
      return;
    }

    final address = _buildShippingAddress();
    final selectedShippingMethod = _selectedInpostShippingMethod;
    final inpost = selectedInpost;

    final Map<String, dynamic> orderData = {
      "amount": _toMinorUnits(total),
      "productId": basketItems[0].id,
      "productName": basketItems[0].name,
      "paymentIntentId": paymentIntentId,
      "deliveryMethod": _deliveryChoice == DeliveryType.pickup ? "pickup_point" : "home",
      if (selectedShippingMethod != null) "shippingMethodId": selectedShippingMethod.id,
      if (inpost != null) "shippingCarrier": inpost.carrier,
      "shipping": {"address": address, "name": 'Customer', "telephone": mobilePhoneNumber},
      "shippingWeight": basketItems[0].postageSize.weight,
      if (_deliveryChoice == DeliveryType.pickup) "pickupPoint": _buildPickupPointPayload(inpost!),
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

  Future<UserCredentials?> fetchUserProfile() async {
    try {
      final result = await checkoutRepository.fetchUserProfile();
      if (result.isSuccess) {
        if (result.value == null) {
          _log.warning('fetchUserProfile returned null value');
          return null;
        }
        return result.value;
      } else {
        return null;
      }
    } catch (e) {
      _log.severe('fetch profile failed! ${e.toString()}');
      return null;
    }
  }

  int _toMinorUnits(double amount) {
    return (amount * 100).round();
  }

  Map<String, dynamic> _buildShippingAddress() {
    return switch (_deliveryChoice) {
      DeliveryType.pickup => {
        "line1": _pickupAddressLine(selectedInpost!.address),
        "city": selectedInpost?.city.trim() ?? '',
        "postal_code": selectedInpost?.postcode.trim() ?? '',
        "country": _countryCode(selectedInpost?.country ?? 'GB'),
      },
      DeliveryType.home => {
        "line1": _shippingAddress?.line1 ?? '',
        "city": shippingAddressComponents[AddressConstants.cityKey] ?? "",
        "state": shippingAddressComponents[AddressConstants.stateKey] ?? "",
        "postal_code": shippingAddressComponents[AddressConstants.postalCodeKey] ?? "",
        "country": _countryCode(
          shippingAddressComponents[AddressConstants.countryKey] ?? AppStrings.unitedKingdomText,
        ),
      },
      DeliveryType.undefined => {},
    };
  }

  Map<String, dynamic> _buildPickupPointPayload(Inpost pickupPoint) {
    return {
      "id": pickupPoint.id,
      "name": pickupPoint.name,
      "addressLine1": _pickupAddressLine(pickupPoint.address),
      "city": pickupPoint.city.trim(),
      "postalCode": pickupPoint.postcode.trim(),
      "country": _countryCode(pickupPoint.country),
      "carrier": pickupPoint.carrier,
    };
  }

  bool _hasCompletePickupPoint(Inpost pickupPoint) {
    return pickupPoint.id.trim().isNotEmpty &&
        pickupPoint.name.trim().isNotEmpty &&
        _pickupAddressLine(pickupPoint.address).isNotEmpty &&
        pickupPoint.city.trim().isNotEmpty &&
        pickupPoint.postcode.trim().isNotEmpty &&
        _countryCode(pickupPoint.country).length == 2;
  }

  String _pickupAddressLine(String address) {
    return address.replaceAll(AddressConstants.inpostAddressSeparator, ', ').trim();
  }

  String _countryCode(String country) {
    final normalised = country.trim().toUpperCase();
    if (normalised.length == 2) {
      return normalised;
    }
    if (normalised == AppStrings.unitedKingdomText.toUpperCase()) {
      return 'GB';
    }
    return normalised;
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

  List<InpostSearchResult> _parseInpostList(dynamic payload) {
    final dynamic listData = payload is Map<String, dynamic>
        ? (payload['pickupPoints'] ?? payload['lockers'] ?? payload['items'])
        : payload;

    if (listData is! List) return [];

    final lockers = <InpostSearchResult>[];
    for (final item in listData) {
      final locker = _parseInpostItem(item);
      if (locker != null) {
        lockers.add(locker);
      }
    }
    return lockers;
  }

  List<InpostShippingMethod> _parseShippingMethodList(dynamic payload) {
    final List<dynamic> jsonList = payload['shippingMethods'] ?? payload;

    final shippingMethods = jsonList
        .map((json) => InpostShippingMethod.fromJson(json))
        .where((method) => method.name.startsWith('InPost Locker'))
        .toList();
    return shippingMethods;
  }

  InpostSearchResult? _parseInpostItem(dynamic item) {
    if (item is! Map) return null;
    final map = Map<String, dynamic>.from(item);

    String readFirst(List<String> keys) {
      for (final key in keys) {
        final value = map[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString().trim();
        }
      }
      return '';
    }

    final id = readFirst(['id', 'lockerId', 'code']);
    final name = readFirst(['name', 'lockerName']);
    final carrier = (map['carrier'] ?? '').toString();
    final address = readFirst(['addressLine1', 'line1', 'street']);
    final postcode = readFirst(['postcode', 'postalCode', 'postCode']);
    final city = map['city'].toString();
    final country = map['country'].toString();
    final lat = readFirst(['lat', 'latitude']);
    final long = readFirst(['long', 'lng', 'longitude']);
    if (id.isEmpty || name.isEmpty || address.isEmpty || postcode.isEmpty) {
      return null;
    }

    return InpostSearchResult(
      inpost: Inpost(
        id: id,
        name: name,
        carrier: carrier,
        address: address,
        postcode: postcode,
        city: city,
        country: country,
        lat: lat,
        long: long,
      ),
      distanceMetres: map['distanceMeters'],
    );
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

  Future<bool> showPickupPointSelection() async {
    final result = await navigator.navigateTo(AppRoutes.pickupPointSelector);

    return result == true;
  }

  void goBack(bool pickupPointSelected) {
    navigator.goBack(pickupPointSelected);
  }
}
