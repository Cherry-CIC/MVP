import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/models/inpost_model.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/features/checkout/checkout_repository.dart';
import 'package:cherry_mvp/features/checkout/models/payment_intent.dart';
import 'package:cherry_mvp/features/checkout/payment_type.dart';
import 'package:cherry_mvp/features/checkout/widgets/shipping_address_widget.dart';
import 'package:cherry_mvp/features/checkout/constants/address_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:logging/logging.dart';

/// ViewModel for managing checkout state including basket items, shipping address, and payment method
class CheckoutViewModel extends ChangeNotifier {
  final ICheckoutRepository checkoutRepository;
  final _log = Logger('CheckoutViewModel');

  CheckoutViewModel({required this.checkoutRepository});

  Status _status = Status.uninitialized;

  Status get status => _status;

  Status _createOrderStatus = Status.uninitialized;
  Status get createOrderStatus => _createOrderStatus;

  final List<Product> _basketItems = [];

  final List<InpostModel> _nearestInpost = [
    InpostModel(
      id: "002",
      name: "Aldi Locker — Camden",
      address: "Camden High Street, London",
      postcode: "NW1 8QP",
      lat: "51.5413",
      long: "-0.1460",
    ),
    InpostModel(
      id: "010",
      name: "Aldi Locker — Deansgate",
      address: "Deansgate, Manchester",
      postcode: "M3 2BW",
      lat: "53.4808",
      long: "-2.2474",
    ),
    InpostModel(
      id: "030",
      name: "Aldi Locker — Temple Gate",
      address: "Temple Gate, Bristol",
      postcode: "BS1 6PL",
      lat: "51.4490",
      long: "-2.5830",
    ),
  ];
  List<InpostModel> get nearestInpost => _nearestInpost;

  InpostModel? selectedInpost;

  bool showLocker = false;

  bool hasLocker = false;

  String? deliveryChoice;

  setDeliveryChoice(String val) {
    deliveryChoice = val;
    notifyListeners();
  }

  setShowLocker(bool val) {
    showLocker = val;
    notifyListeners();
  }

  setSelectedInpost(var data) {
    selectedInpost = data;
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

  /// Whether a payment method has been set
  bool get hasPaymentMethod => selectedPaymentType != null || _hasPaymentMethod;

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
      AddressConstants.streetKey:
          '${_shippingAddress!.streetNumber} ${_shippingAddress!.route}'.trim(),
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
    selectedPaymentType = null;
    _hasPaymentMethod = false;
    isShippingAddressConfirmed = false;
    selectedInpost = null;
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
    return street.isNotEmpty &&
        city.isNotEmpty &&
        postalCode.isNotEmpty &&
        _isValidPostalCode(postalCode);
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
          AddressConstants.streetKey:
              shippingAddressComponents[AddressConstants.streetKey],
          AddressConstants.cityKey:
              shippingAddressComponents[AddressConstants.cityKey],
          AddressConstants.stateKey:
              shippingAddressComponents[AddressConstants.stateKey],
          'postal_code':
              shippingAddressComponents[AddressConstants.postalCodeKey],
          AddressConstants.countryKey:
              shippingAddressComponents[AddressConstants.countryKey],
          'latitude': _shippingAddress?.latitude,
          'longitude': _shippingAddress?.longitude,
        },
        'totals': {
          'item_total': itemTotal,
          'security_fee': securityFee,
          'postage': postage,
          'total': total,
        },
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

  // fetch nearest inPost locker for pickup
  Future<void> fetchNearestInPosts(String postalCode) async {
    _status = Status.loading;
    notifyListeners();

    try {
      final result = await checkoutRepository.fetchNearestInPosts(postalCode);

      if (result.isSuccess && result.value != null) {
        final parsedInposts = _parseInpostList(result.value);
        if (parsedInposts.isNotEmpty) {
          _nearestInpost
            ..clear()
            ..addAll(parsedInposts);
        }
      }

      if (_nearestInpost.isNotEmpty) {
        showLocker = true;
        _status = Status.success;
      } else {
        _status = Status.failure(
          result.error ??
              'Pickup points currently unavailable, please try again later',
        );
        _log.warning('Fetch nearest inPost locker failed: ${result.error}');
      }
    } catch (e) {
      _status = Status.failure(e.toString());
      _log.severe('Fetch nearest inPost locker error:: $e');
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
        final address = (data[FirestoreConstants.address] ?? '').toString();
        final postcode = (data[FirestoreConstants.postcode] ?? '').toString();
        final lat = (data[FirestoreConstants.lat] ?? '').toString();
        final long = (data[FirestoreConstants.long] ?? '').toString();

        if (id.isNotEmpty &&
            name.isNotEmpty &&
            address.isNotEmpty &&
            postcode.isNotEmpty) {
          selectedInpost = InpostModel(
            id: id,
            name: name,
            address: address,
            postcode: postcode,
            lat: lat,
            long: long,
          );
          hasLocker = true;
          showLocker = true;
          _status = Status.success;
        } else {
          hasLocker = false;
          showLocker = false;
          selectedInpost = null;
        }
      } else {
        hasLocker = false;
        showLocker = false;
        selectedInpost = null;
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
              'image': item.productImages.isNotEmpty
                  ? item.productImages.first
                  : null,
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
    await checkoutRepository.storeOrderInFirestore(orderData);
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
        return true;
      } else {
        _createOrderStatus = Status.failure(response.error.toString());
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
      notifyListeners();
      return false;
    } catch (e) {
      _createOrderStatus = Status.failure(e.toString());
      _log.severe('Error making payment::: $e');
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

    final Map<String, dynamic> address = deliveryChoice == "pickup"
        ? {
            "line1": selectedInpost?.address ?? '',
            "city": "London",
            "state": "London",
            "postal_code": selectedInpost?.postcode ?? '',
            "country": AppStrings.unitedKingdomText,
          }
        : {
            'line1': _shippingAddress?.line1 ?? '',
            "city": shippingAddressComponents[AddressConstants.cityKey] ?? "",
            "state": shippingAddressComponents[AddressConstants.stateKey] ?? "",
            'postal_code':
                shippingAddressComponents[AddressConstants.postalCodeKey] ?? "",
            "country":
                shippingAddressComponents[AddressConstants.countryKey] ??
                AppStrings.unitedKingdomText,
          };

    final Map<String, dynamic> orderData = {
      "amount": _toMinorUnits(total),
      "productId": basketItems[0].id,
      "productName": basketItems[0].name,
      "shipping": {"address": address, "name": 'John Doe'},
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
    final applePay = paymentType == PaymentType.apple
        ? const PaymentSheetApplePay(merchantCountryCode: "GB")
        : null;

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

  List<InpostModel> _parseInpostList(dynamic payload) {
    final dynamic listData = payload is Map<String, dynamic>
        ? (payload['data'] ?? payload['lockers'] ?? payload['items'])
        : payload;

    if (listData is! List) return [];

    final lockers = <InpostModel>[];
    for (final item in listData) {
      final locker = _parseInpostItem(item);
      if (locker != null) {
        lockers.add(locker);
      }
    }
    return lockers;
  }

  InpostModel? _parseInpostItem(dynamic item) {
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
    final address = readFirst(['address', 'line1', 'street']);
    final postcode = readFirst(['postcode', 'postalCode', 'postCode']);
    final lat = readFirst(['lat', 'latitude']);
    final long = readFirst(['long', 'lng', 'longitude']);

    if (id.isEmpty || name.isEmpty || address.isEmpty || postcode.isEmpty) {
      return null;
    }

    return InpostModel(
      id: id,
      name: name,
      address: address,
      postcode: postcode,
      lat: lat,
      long: long,
    );
  }
}
